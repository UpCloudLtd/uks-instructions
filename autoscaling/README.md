# Cluster Autoscaler

Cluster Autoscaler (CA) for UpCloud automatically adds or removes cluster worker nodes depending on current workload. 
UpCloud's CA cloud provider implementation does this by increasing or decreasing node group(s) size when needed.

Cluster Autoscaler works particularly well along with Kubernetes built-in [horizontal pod autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) (HPA). 
In short, HPA scales the number of pods depending on the current workload and when CA notices that cluster resource requirements has changed, it will try to adjust worker node count to meet new needs.

Additional info about the Cluster Autoscaler can be found from the project's [README](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/README.md) file and from the [FAQ](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md) .

## Deploy Cluster Autoscaler for UpCloud

Currently it is only posible to run CA in the worker nodes, which is not ideal as Cluster Autoscaler is designed to run on Kubernetes control plane node, but our current setup [tries to ensure that CA stays always running](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/README.md#deployment). 

### Prerequisites
- `kubectl` installed
- cluster config (kubeconfig) and UUID of the cluster

Import UpCloud credentials as Kubernetes secret:  
<sub>_Replace `$UPCLOUD_PASSWORD` and `$UPCLOUD_USERNAME` with your UpCloud API credentials if not defined using environment variables._</sub>
```shell
$ kubectl -n kube-system create secret generic upcloud-autoscaler --from-literal=password=$UPCLOUD_PASSWORD --from-literal=username=$UPCLOUD_USERNAME
```
Note that user `$UPCLOUD_USERNAME` needs to have permission to manage Kubernetes cluster through UpCloud API.

Apply RBAC rules, required by the CA
```shell
$ kubectl apply -f https://raw.githubusercontent.com/UpCloudLtd/autoscaler/feat/cluster-autoscaler-cloudprovider-upcloud/cluster-autoscaler/cloudprovider/upcloud/examples/rbac.yaml
```
Download CA setup manifest
```shell
$ curl -o cluster-autoscaler.yaml https://raw.githubusercontent.com/UpCloudLtd/autoscaler/feat/cluster-autoscaler-cloudprovider-upcloud/cluster-autoscaler/cloudprovider/upcloud/examples/cluster-autoscaler.yaml
```
Edit downloaded `cluster-autoscaler.yaml` file and replace `${UPCLOUD_CLUSTER_ID}` with your cluster's UUID.

Apply the CA setup manifest
```shell
$ kubectl apply -f cluster-autoscaler.yaml
```

Check that CA is running
```shell
$ kubectl -n kube-system get pods -l app=cluster-autoscaler
NAME                                  READY   STATUS    RESTARTS   AGE
cluster-autoscaler-7c64c9f9bc-7g2vb   1/1     Running   0          4m
```

### Test autoscaling

There is [Nginx deployment example](https://github.com/UpCloudLtd/autoscaler/blob/feat/cluster-autoscaler-cloudprovider-upcloud/cluster-autoscaler/cloudprovider/upcloud/examples/testing/deployment.yaml) in the UpCloud's Cluster Autoscaler repository, that can be used to test cluster autoscaling. 

Before starting check the number of the current worker nodes
```shell
$ kubectl get nodes
NAME                          STATUS   ROLES    AGE    VERSION
kube-terraform-test-0-6nrr4   Ready    <none>   152m   v1.26.3
kube-terraform-test-0-tb9k9   Ready    <none>   152m   v1.26.3
```

Deploy Nginx test service:
```shell
$ kubectl apply -f https://raw.githubusercontent.com/UpCloudLtd/autoscaler/feat/cluster-autoscaler-cloudprovider-upcloud/cluster-autoscaler/cloudprovider/upcloud/examples/testing/deployment.yaml
```

and check that delpoyment started normally
```shell
$ kubectl -n cluster-autoscale-test get deployments/nginx
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   10/10   10           10          4m52s
```

Depending on your worker node plan, start scaling up the service, for example set replicas to 50
```shell
$ kubectl -n cluster-autoscale-test scale deployment/nginx --replicas=50
deployment.apps/nginx scaled
```

Goal here is to exhaust Kubernetes resources so that it cannot start anymore pods to fill deployment requirements. 
CA should detect this state and start creating new worker nodes as soon as possible.

Watch node list for changes
```shell
$ kubectl get nodes -w
NAME                          STATUS     ROLES    AGE     VERSION
kube-terraform-test-0-6nrr4   Ready      <none>   165m    v1.26.3
kube-terraform-test-0-tb9k9   Ready      <none>   166m    v1.26.3
kube-terraform-test-0-tbkf8   Ready      <none>   25s     v1.26.3
kube-terraform-test-0-k7p65   NotReady   <none>   8s      v1.26.3
```
New nodes should appear in the listing in couple of minutes and state should change from `NotReady` to `Ready`.

Clean up test service by deleting the namespace
```shell
$ kubectl delete namespaces cluster-autoscale-test 
namespace "cluster-autoscale-test" deleted
```

It takes about 10 to 15 minutes (with default settings) for CA to start scaling down the cluster automatically. 
```shell
$ kubectl get nodes
NAME                          STATUS   ROLES    AGE    VERSION
kube-terraform-test-0-6nrr4   Ready    <none>   3h6m   v1.26.3
kube-terraform-test-0-tb9k9   Ready    <none>   3h6m   v1.26.3
```


## What's next
- Leave Cluster Autoscaler running and [setup Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)  to automatically update workload resources
- See how you can [deploy cluster autoscaler using Terraform](https://github.com/UpCloudLtd/autoscaler/tree/feat/cluster-autoscaler-cloudprovider-upcloud/cluster-autoscaler/cloudprovider/upcloud/examples/terraform)