# Importing an existing block storage to your UKS cluster

__This should be done very carefully and at your own risk, as there is a possibility of data loss if something goes wrong.__

Importing a block storage volume as a Persistent Volume Claim to your UKS cluster requires following steps:

- __take a backup of your volume!__
- Grant storage permissions to your volume for the CSI sub-account
- Create PV and PVC objects that match your existing volume
- Create a test pod and verify the volume mount works

## Prerequisites

- `kubectl` installed
- Block storage volume is in the same zone as your UKS cluster
- Backups taken prior to starting the operation
- Main account access to UpCloud's Hub (hub.upcloud.com)

## Grant device permissions

Access your UKS cluster. CSI driver is run using sub-account credentials.

Get the username of your CSI user:

```shell
$ kubectl -n kube-system get secrets upcloud -o yaml -o jsonpath='{.data.username}'|base64 -d
```

### Grant device permissions using Hub

Go to https://hub.upcloud.com/people/permissions and grant CSI sub-account for permission to access the storage volume you want to use in UKS.

### Grant device permissions using API

Use following permission JSON object to set permission using `POST` request to `/1.3/permission/grant` API endpoint:  
```json
{
  "permission": {
    "options": {},
    "target_identifier": "<storage_uuid>",
    "target_type": "storage",
    "user": "<csi_subaccount_username>"
  }
}
```

## Create a Persistent Volume

Create the following file:

```
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: storage.csi.upcloud.com
  name: PV_NAME
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: STORAGE_SIZE
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: PVC_NAME
    namespace: NAMESPACE_NAME
  csi:
    driver: storage.csi.upcloud.com
    volumeHandle: VOLUME_UUID
  persistentVolumeReclaimPolicy: Retain
  storageClassName: upcloud-block-storage-maxiops
  volumeMode: Filesystem
  ```

Replace the following fields:

- `PV_NAME`: Name for the PV object you are about to create. This is referenced in the next step.
- `STORAGE_SIZE`: Size of the storage volume (for example 10Gi)
- `PVC_NAME`: Name for the PVC object you will create on the next step.
- `NAMESPACE_NAME`: Namespace for the PVC object
- `VOLUME_UUID`: UUID of the underlying storage volume you are importing

Then apply:

```
kubectl apply -f pv.yaml
```

## Create a Persistent Volume Claim

Next, create the following file:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: PVC_NAME
spec:
  storageClassName: upcloud-block-storage-maxiops
  volumeName: PV_NAME
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: STORAGE_SIZE
```

Replace `PVC_NAME`, `PV_NAME` and `STORAGE_SIZE` with the same values as in the previous step.

Then apply:

```
kubectl apply -f pvc.yaml
```

## Create a test pod and mount the storage

Create the following file:

```
kind: Pod
apiVersion: v1
metadata:
  name: csi-import-test-pod
  labels:
    app: csi-import-test-pod
spec:
  containers:
    - name: upcloud-test-pod
      image: busybox
      volumeMounts:
        - mountPath: "/data"
          name: upcloud-volume
      command: [ "sleep", "1000000" ]
  volumes:
    - name: upcloud-volume
      persistentVolumeClaim:
        claimName: PVC_NAME
```

Replace `PVC_NAME` with the name you used in previous steps.

Create the pod and access the data:

```
kubectl apply -f pod.yaml
kubectl exec -ti csi-import-test-pod /bin/ls /data
```