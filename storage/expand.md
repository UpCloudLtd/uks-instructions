# Expand persistent volume claim volume size

Persistent volume size can be expanded by modifying `storage` attribute in persistent volume claim object. Storage size can't be shrunken. 
Upcloud's CSI driver only supports offline expansion so the application needs to be scalled down before operation.

Expanding persistent volume requires following steps:
- shut down application that uses persistent volume that is going to be resized
- patch PVC object with new size
- when resize is done, start application(s)


## Prerequisites
- `kubectl` installed
- cluster config (kubeconfig)


This document uses `mariadb` deployment from [README](README.md) as an example.     
Goal here is to resize the MariaDB data partition from 10GB to 20GB.

## Shut down application
Shut down the application that uses PVC that is going to be resized. This will detach the storage device from the worker node and allow the back-end to resize the storage. 

Check current partition size using `df` command
```shell
$ kubectl exec -it deployments/mariadb -- df -h /var/lib/mysql
Filesystem      Size  Used Avail Use% Mounted on
/dev/vdb1       9.8G  148M  9.1G   2% /var/lib/mysql
```

Size should be close to what was defined in `volume.yaml` manifest, which was 10GB in the MariaDB example.

```shell
$ kubectl -n default scale deployment mariadb --replicas=0
deployment.apps/mariadb scaled
```

## Patch PVC object with new size
```shell
$ kubectl patch pvc mariadb-pvc -p '{"spec":{"resources":{"requests":{"storage": "20Gi"}}}}'
persistentvolumeclaim/mariadb-pvc patched
```
New size can be also updated directly to `volume.yaml` manifest and then re-apply using `kubectl apply -f volume.yaml`

This might take some time. Process can be monitored by checking `mariadb-pvc` events:
```shell
$ kubectl describe pvc mariadb-pvc
```
There should be an event message `Resize volume succeeded` when operation is done.

## Start application
```shell
$ kubectl -n default scale deployment mariadb --replicas=1
deployment.apps/mariadb scaled
```

Confirm the new size
```shell
$ kubectl exec -it deployments/mariadb -- df -h /var/lib/mysql
Filesystem      Size  Used Avail Use% Mounted on
/dev/vdb1        20G  148M   19G   1% /var/lib/mysql
```

This is just a raw example. You might need to e.g. optimise table(s) to make the database engine aware of the extended space.
