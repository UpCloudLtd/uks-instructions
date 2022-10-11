# Welcome to UKS Alpha!

This repository contains sample configurations for Terraform and Kubernetes manifests to get started with our UpCloud Kubernetes Service (UKS).

Note that this repository is still under construction. We're updating the repository until the test period begins.

## Terraform

See [terraform/README.md](terraform/README.md).

## Exposing Services

Create a deployment and expose it to the public Internet by running the following commands:

```
kubectl create deployment --image=ghcr.io/upcloudltd/hello hello-uks
kubectl expose deployment hello-uks --port=80 --target-port=80 --type=LoadBalancer
kubectl get svc -w
```

This process will take a few minutes as our system will create a new load balancer to handle the traffic.

You can verify that it works by running this simple command:

```
$ curl http://lb-231912371233.upcloudlb.com
```

## Persistent storage

See https://github.com/UpCloudLtd/upcloud-csi/tree/main/example for various examples for our CSI driver.
