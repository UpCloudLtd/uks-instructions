# Welcome to UKS Alpha!

This repository contains sample configurations for Terraform and Kubernetes manifests to get started with our UpCloud Kubernetes Service (UKS).

Note that this repository is still under construction. We're updating the repository until the test period begins.

## UI

### Creating Your First Cluster

* Login to the UpCloud Hub using your account linked with the Alpha test
* Navigate to the `Kubernetes` option in the menu on your left
* Click `Create Cluster`
* The Alpha test is being run in a single zone, and the option has been pre-chosen for you
* Select a Private Network for your Worker Nodes. (If you need more information about creating a network, a link has 
  been provided with more information) NB! This network will need to be created in the same zone as the Alpha tests `de-fra1`
* Provide a name for your cluster and click `Next`
* Create a Node Group
  * Groups of worker nodes with identical image templates are organized for convenience
  * Here you can provide: `Name`, `Number of Nodes`, `Worker Node Plan`
  * Once you have created the Node Group, you can click it to provide more advanced options like: `Labels` and `SSH Key`
* When you are ready, click `Create`!
* Cluster creation will take a few minutes as worker nodes are being provisioned and a DNS record is prepared
* When the cluster is `Running`, you can download your cluster's `KubeConfig`
  * This allows you to access your cluster via the command line

### Troubleshooting

* If you are attempting to access your cluster with a brand new `KubeConfig` and receive an error `no route to host`, this means that the DNS has not been fully configured, and you will need to wait a few more minutes.
  * Alternatively, you can flush your local DNS cache with: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
##  Terraform

See [terraform/README.md](terraform/README.md).

## Exposing Services

Create a deployment and expose it to the public Internet by running the following commands:

```
kubectl create deployment --image=nginx nginx
kubectl expose deployment nginx --port=80 --target-port=80 --type=LoadBalancer
kubectl get svc -w
```

This process will take a few minutes as our system will create a new load balancer to handle the traffic.

You can verify that it works by running this simple command:

```
$ curl http://lb-231912371233.upcloudlb.com
```

## Persistent storage

See https://github.com/UpCloudLtd/upcloud-csi/tree/main/example for various examples for our CSI driver.
