# Storage encryption at rest

All block storage devices created by the CSI driver can be optionally [encrypted at rest](https://upcloud.com/resources/docs/storage#encryption-at-rest).  
Encryption support was added to CSI driver in version [v1.1.0](https://github.com/UpCloudLtd/upcloud-csi/releases/tag/v1.1.0).

Encryption at rest can be enabled by defining `encryption` parameter in storage class
```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: upcloud-encrypted-block-storage
  namespace: kube-system
parameters:
  tier: maxiops
  encryption: data-at-rest
provisioner: storage.csi.upcloud.com
```

Once defined, use newly created storage class with storage that you want to encrypt
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-pvc-encrypted
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: upcloud-encrypted-block-storage
```
Note that, using encrypted snapshots as volume source is not supported yet.