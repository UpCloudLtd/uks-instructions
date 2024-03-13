# Update CSI driver in UpCloud Kubernetes Service

Driver consists of two services running in `kube-system` namespace:
- node service `daemonset/csi-upcloud-node`
- controller service `statefulset/csi-upcloud-controller`

Normally both `csi-upcloud-controller` and `csi-upcloud-node` service should have same version of the driver running, although it's not requirement. CSI driver can be updated by modifying the driver's image tag. 

## Examples
### Update driver to version v1.1.0
Check what version is of `ghcr.io/upcloudltd/upcloud-csi` image is currently running
```shell
$ kubectl -n kube-system get statefulset/csi-upcloud-controller -o jsonpath='{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}'
k8s.gcr.io/sig-storage/csi-provisioner:vX.Y.Z
k8s.gcr.io/sig-storage/csi-attacher:vX.Y.Z
k8s.gcr.io/sig-storage/csi-resizer:vX.Y.Z
k8s.gcr.io/sig-storage/csi-snapshotter:vX.Y.Z
ghcr.io/upcloudltd/upcloud-csi:v1.0.0
```

```shell
$ kubectl -n kube-system get daemonset/csi-upcloud-node -o jsonpath='{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}'
k8s.gcr.io/sig-storage/csi-node-driver-registrar:vX.Y.Z
ghcr.io/upcloudltd/upcloud-csi:v1.0.0
```
Driver version v1.0.0 is currently running. Write version down just in case quick rollback is required. Read CSI [changelog](https://github.com/UpCloudLtd/upcloud-csi/blob/main/CHANGELOG.md) and check if there is any breaking changes between old and new version. 

Update controller and node service using kubectl to use updated driver version:
```shell
$ kubectl -n kube-system set image statefulset/csi-upcloud-controller csi-upcloud-plugin=ghcr.io/upcloudltd/upcloud-csi:v1.1.0
statefulset.apps/csi-upcloud-controller image updated
```

```shell
$ kubectl -n kube-system set image daemonset/csi-upcloud-node csi-upcloud-plugin=ghcr.io/upcloudltd/upcloud-csi:v1.1.0
daemonset.apps/csi-upcloud-node image updated
```

Updating images should also trigger rolling update to those service. Wait until all the pods are running:
```shell
$ kubectl -n kube-system get pod -l app=csi-upcloud-node
NAME                     READY   STATUS    RESTARTS   AGE
csi-upcloud-node-d6zlf   2/2     Running   0          31s
csi-upcloud-node-k54vw   2/2     Running   0          27s
csi-upcloud-node-mj26w   2/2     Running   0          29s
```
```shell
$ kubectl -n kube-system get pod -l app=csi-upcloud-controller
NAME                       READY   STATUS    RESTARTS   AGE
csi-upcloud-controller-0   5/5     Running   0          54s
```
Use version command above to double check that pods are using correct image.
If there is some errors and pods can't start, use `kubectl set image` command above to rollback previous version.