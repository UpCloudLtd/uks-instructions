# Taking persistent volume claim (PVC) snapshots

Volume snapshots provide Kubernetes users with a standardised way to copy a volume's contents at a particular point in time without creating an entirely new volume. This functionality enables, for example, database administrators to backup databases before performing edit or delete modifications.

Read more about volume [snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) from Kubernetes documentation.

## Prerequisites
- `kubectl` installed
- cluster config (kubeconfig)

This document uses `mariadb` deployment from [README](README.md) as an example. To test this out, follow the steps from `README` and fill the database with test data (numbers from 1 to 4).   
Goal here is to take a snapshot from the MariaDB data partition and use snapshot as a restore point to rollback the database to the previous version.  

Note that in real life, taking database backups using snapshots instead of using database dump utility, might lead to data loss if not carefully planned. There might be data in memory that is not flushed to disk yet.

Taking snapshot and restoring it requires following steps:
- take snapshot of the data partition
- create new persistent volume claim using snapshot as data source
- modify application to use new persistent volume claim to mount data partition

## Take snapshot of the data partition
Save following content to file named `snapshot.yaml`
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: mariadb-pvc-snapshot
spec:
  volumeSnapshotClassName: upcloud-csi-snapshotclass
  source:
    persistentVolumeClaimName: mariadb-pvc
```

Apply manifest
```shell
$ kubectl apply -f snapshot.yaml
volumesnapshot.snapshot.storage.k8s.io/mariadb-pvc-snapshot created
```

Verify that snapshot was taken successfully and that it's ready to use
```shell
$ kubectl get volumesnapshots.snapshot.storage.k8s.io mariadb-pvc-snapshot 
NAME                   READYTOUSE   SOURCEPVC     SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS               SNAPSHOTCONTENT                                    CREATIONTIME   AGE
mariadb-pvc-snapshot   true         mariadb-pvc                           10Gi          upcloud-csi-snapshotclass   snapcontent-93f917a5-3f00-4c93-9091-9c2d1a33b93a   2m13s          2m13s
```

Use `snapshotcontent` column's value to inspect content object
```shell
$ kubectl get volumesnapshotcontents.snapshot.storage.k8s.io snapcontent-93f917a5-3f00-4c93-9091-9c2d1a33b93a
NAME                                               READYTOUSE   RESTORESIZE   DELETIONPOLICY   DRIVER                    VOLUMESNAPSHOTCLASS         VOLUMESNAPSHOT         VOLUMESNAPSHOTNAMESPACE   AGE
snapcontent-93f917a5-3f00-4c93-9091-9c2d1a33b93a   true         10737418240   Delete           storage.csi.upcloud.com   upcloud-csi-snapshotclass   mariadb-pvc-snapshot   default                   3m31s
```

Snapshots can be found from Hub, under [/storage/backups](https://hub.upcloud.com/storage/backups). Snapshots use the naming convention `snapshot-<uid>`, so the above snapshot can be found with the name `snapshot-93f917a5-3f00-4c93-9091-9c2d1a33b93a` .

### Testing
Add more numbers into the running database, just to observe changes later, when the snapshot is restored.

```shell
$ kubectl exec -it deployments/mariadb -- mysql -uroot -p$MARIADB_PASSWORD -e "INSERT INTO test.number (id) VALUES (5)"
```
```shell
$ kubectl exec -it deployments/mariadb -- mysql -uroot -p$MARIADB_PASSWORD -e "SELECT id FROM test.number";
+----+
| id |
+----+
|  1 |
|  2 |
|  3 |
|  4 |
|  5 |
+----+
```
At this point snapshot taken prior contains database data-partition that has numbers from 1 to 4 in the `test.number` table and running database have numbers from 1 to 5. Let's imagine that something bad happens and we need to roll back the database to use the `test.number` table from the snapshot and accept that we are going to lose 5th record in the table.

## Create new persistent volume claim using snapshot as data source
Save following content to file named `rollback.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc-rollback
spec:
  storageClassName: upcloud-block-storage-maxiops
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  dataSource:
    kind: VolumeSnapshot
    name: mariadb-pvc-snapshot
    apiGroup: snapshot.storage.k8s.io
```
*PVC `mariadb-pvc-rollback` uses `mariadb-pvc-snapshot` snapshot as a data-source by creating a new storage device based on the snapshot.*

Apply manifest
```shell
$ kubectl apply -f rollback.yaml
```

Wait until PVC status changes from `pending` to `bound`
```shell
$ kubectl get pvc mariadb-pvc-rollback
NAME                   STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                    AGE
mariadb-pvc-rollback   Bound    pvc-20dd15bd-21d2-4976-81ab-171d1e29e8a1   10Gi       RWO            upcloud-block-storage-maxiops   8m7s
```

Note that this might take some time because data is restored from a snapshot into a new storage device.

## Modify application to use new persistent volume claim
Shut down the application.
```shell
$ kubectl scale deployment mariadb --replicas=0
deployment.apps/mariadb scaled
```

Take a copy of the `deployment.yaml` 
```shell
$ cp deployment.yaml deployment_rollback.yaml
```

Change `claimName` in `deployment_rollback.yaml` from `mariadb-pvc` to `mariadb-pvc-rollback`
```yaml
# ...
volumes:
  - name: mariadb-datadir
    persistentVolumeClaim:
      claimName: mariadb-pvc-rollback
# ...
```

Apply manifest
```shell
$ kubectl apply -f deployment_rollback.yaml
```

Verify that deployment now uses correct claim name `mariadb-pvc-rollback`
```shell
$ kubectl get deployments mariadb -o yaml -o jsonpath='{.spec.template.spec.volumes}'
[{"name":"mariadb-datadir","persistentVolumeClaim":{"claimName":"mariadb-pvc-rollback"}}]
```

Start the application
```shell
$ kubectl scale deployment mariadb --replicas=1
deployment.apps/mariadb scaled
```

### Testing
Database should now contain numbers from 1 to 4, restored from snapshot

```shell
$ kubectl exec -it deployments/mariadb -- mysql -uroot -p$MARIADB_PASSWORD -e "SELECT id FROM test.number";
+----+
| id |
+----+
|  1 |
|  2 |
|  3 |
|  4 |
+----+
```

Snapshot can be now deleted if it's not needed anymore
```shell
$ kubectl delete volumesnapshots.snapshot.storage.k8s.io  mariadb-pvc-snapshot
volumesnapshot.snapshot.storage.k8s.io "mariadb-pvc-snapshot" deleted
```

Default deletion policy is `delete` so this will also delete the snapshot from the back-end.
