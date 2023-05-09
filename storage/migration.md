# Migrating persistent volume claim (PVC) from one cluster to another

__This should be done very carefully and at your own risk, as there is a possibility of data loss if something goes wrong.__

Migrating persistent volume to another cluster requires following steps:
- __take data backup!__
- old cluster
    - check that volume reclaim policy is set to `retain` to preserve data when volume is eventually removed from old cluster
    - export persistent volume (PV) and persistent volume claim (PVC) objects from the old cluster
    - shutdown application that uses PVC in the old cluster
    - determine storage device ID
- new cluster
    - grant storage device permissions
    - import persistent volume (PV) and persistent volume claim (PVC) objects into the new cluster
    - patch PV object with new PVC `uid` value
    - start application(s) in the new cluster
- cleanup
    - post-migration checks
    - remove objects from old cluster

## Prerequisites
- `kubectl` installed
- both clusters must be in the same zone
- cluster config (kubeconfig) for old and new cluster and working connection to both
- backups taken prior to starting the operation
- main account access to UpCloud's Hub (hub.upcloud.com)
- some Linux tooling is used in examples but they are not required

This document uses `mariadb` deployment from [README](README.md) as an example. To test this out, follow the steps from `README` and fill the database with test data (numbers).   
Goal here is to migrate `mariadb` deployment with the existing database to the new Kubernetes cluster.

---
# Old cluster
Set `KUBECONFIG` environment variable to point to the old cluster config.  

## Check volume reclaim policy
Check that volume [reclaim policy](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#retain) is set to `retain` to preserve storage device and data when volume is eventually removed from the old cluster. 
```shell
$ kubectl get pv <volume_name>
```
*if volume name is unknown, leave it empty and check name from PV listing*  

__MariaDB example output__:
```shell
$ kubectl get pv pvc-647af707-d53b-4dd3-9571-426a4d321593
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS                    REASON   AGE
pvc-647af707-d53b-4dd3-9571-426a4d321593   1Gi        RWO            Retain           Bound    default/mariadb-pvc   upcloud-block-storage-maxiops            32s
```
Reclaim policy column tells that we have `retain` policy and we can continue. Persistent volume claim name (`mariadb-pvc`) and namespace (`default`) are shown in the claim column.

## Export PV and PVC objects
Export persistent volume and persistent volume claim objects from the old cluster. Note that PVC objects are namespaced and PV objects are not.
```shell
$ kubectl get pv <pv_name> -o yaml > <pv_name>.yaml
$ kubectl -n <namespace> get pvc <pvc_name> -o yaml > <pvc_name>.yaml
```
*check that <pv_name>.yaml and <pvc_name>.yaml files contains PV and PVC objects before continuing*   

__MariaDB example output__:
```shell
$ kubectl get pv pvc-647af707-d53b-4dd3-9571-426a4d321593 -o yaml > pvc-647af707-d53b-4dd3-9571-426a4d321593.yaml
$ kubectl -n default get pvc mariadb-pvc -o yaml > mariadb-pvc.yaml
```

## Shutdown application(s)
Shutdown application that uses PVC in the old cluster. This will detach storage device from worker node. 

__MariaDB example output__:
```shell
$ kubectl -n default scale deployment mariadb --replicas=0
deployment.apps/mariadb scaled
```

Before continuing, login to Hub and check that the storage device with the same name as persistent volume, isn't attached to any server. 

## Determine storage device ID
Determine underlying storage device's `uuid` so that correct permissions can be granted for the new cluster. Take a copy of the storage `uuid` value.
Storage `uuid` can be checked from Hub (using PV name) or using command:
```shell
$ kubectl get pv <pv_name> -o custom-columns="storage_uuid":.spec.csi.volumeHandle,"pv_name":.metadata.name
```

__MariaDB example output__:
```shell
$ kubectl get pv pvc-647af707-d53b-4dd3-9571-426a4d321593 -o custom-columns="storage_uuid":.spec.csi.volumeHandle,"pv_name":.metadata.name
storage_uuid                           pv_name
01a1990f-3409-4cad-ba87-f7925f149842   pvc-647af707-d53b-4dd3-9571-426a4d321593
```

---

# New cluster
Set `KUBECONFIG` environment variable to point to the new cluster config.  

## Grant device permissions
CSI driver is run using sub-account credentials. Get CSI user's username in the new cluster:
```shell
$ kubectl -n kube-system get secrets upcloud -o yaml -o jsonpath='{.data.username}'|base64 -d
```

### Grant device permissions using Hub
Go to https://hub.upcloud.com/people/permissions and grant CSI sub-account for permission to access storage.

### Grant device permissions using API
Use following permission JSON object to set permission:  
```json
// POST /1.3/permission/grant
{
  "permission": {
    "options": {},
    "target_identifier": "<storage_uuid>",
    "target_type": "storage",
    "user": "<csi_subaccount_username>"
  }
}
```
See [API documentation](https://developers.upcloud.com/1.3/18-permissions/#grant-permission) for more detailed info on how to use permission API resource.

## Import PV and PVC objects to new cluster
Import persistent volume (PV) and persistent volume claim (PVC) objects to the new cluster. Before import, __check that the new cluster has PVC namespace defined__.
```shell
 $ kubectl apply -f <pv_name>.yaml
 $ kubectl apply -f <pvc_name>.yaml
```

__MariaDB example output__:
```shell
$ kubectl apply -f pvc-647af707-d53b-4dd3-9571-426a4d321593.yaml 
persistentvolume/pvc-647af707-d53b-4dd3-9571-426a4d321593 created
$ kubectl apply -f mariadb-pvc.yaml 
persistentvolumeclaim/mariadb-pvc created
```

## Patch persistent volume object
Persistent volume claim (PVC) objects have now new `uid` value and those need to be patched to persistent volume (PV) objects.  
First take copy of new volume name `<->` claim uid mapping in PVC:
```shell
$ kubectl -n <namespace> get pvc <pvc_name> -o custom-columns="pv_name":.spec.volumeName,"claim_uid":.metadata.uid
```

__MariaDB example output__:
```shell
$ kubectl -n default get pvc mariadb-pvc -o custom-columns="pv_name":.spec.volumeName,"claim_uid":.metadata.uid
pv_name                                    claim_uid
pvc-647af707-d53b-4dd3-9571-426a4d321593   0a2ebb0f-6a65-4ef8-b8b2-2156c2bf2a1e
```

Patch PV objects using `volume_name` and `claim_uid` value from previous listing:
```shell
$ kubectl patch pv <pv_name> -p '{"spec":{"claimRef":{"uid":"<claim_uid>"}}}'
```

__MariaDB example output__:
```shell
$ kubectl patch pv pvc-647af707-d53b-4dd3-9571-426a4d321593 -p '{"spec":{"claimRef":{"uid":"0a2ebb0f-6a65-4ef8-b8b2-2156c2bf2a1e"}}}'
persistentvolume/pvc-647af707-d53b-4dd3-9571-426a4d321593 patched
```

Persistent volume claim status should be now changed from `lost` to `bound`

# Start application(s)
Deploy application(s) to the new cluster and check that everything works correctly and that data is intact.

__MariaDB example output__:
```shell
$ kubectl apply -f deployment.yaml 
deployment.apps/mariadb created
```

---

# Cleanup
## Post-migration checks

Check that application are running correctly in the new cluster and double check that backups are available.  
New backup can be taken at this point, but make sure that backups taken before operation are not replaced.  

## Remove objects from old cluster
### Old cluster
Set `KUBECONFIG` environment variable to point to the __old__ cluster config and clean up persistent volume (PV) and persistent volume claim (PVC) objects.
```shell
 $ kubectl -n <namespace> delete pvc <pvc_name>
 $ kubectl delete pv <pv_name>
```

__MariaDB example output__:
```shell
$ kubectl -n default delete pvc mariadb-pvc
persistentvolumeclaim "mariadb-pvc" deleted
$ kubectl delete pv pvc-647af707-d53b-4dd3-9571-426a4d321593
persistentvolume "pvc-647af707-d53b-4dd3-9571-426a4d321593" deleted
```
