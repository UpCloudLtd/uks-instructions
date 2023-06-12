# Terraform examples

This directory contains an example on how to create a Kubernetes cluster and deploy an application into it using UpCloud and Kubernetes Terraform providers.

The implementation is split into the following directories:

- [cluster](./cluster/) contains configuration to create a Kubernetes cluster and its dependencies. It provides the UUID of the created cluster as its output.
- [cluster-with-private-node-groups](./cluster-with-private-node-groups) contains configuration to create a Kubernetes cluster with private node groups which are connected to the Internet through a Managed NAT GW. Same output as above.
- [deployment](./deployment/) contains configuration for creating and exposing an Kubernetes deployment 

You can either run these separately by following the instruction in the sub-directories or as a combined setup by running the `terraform` commands in this directory.

## Provider setup

### UpCloud

To be able to deploy resources, you will need to configure `UPCLOUD_USERNAME` and `UPCLOUD_PASSWORD` environment variables. See [the official UpCloud Terraform provider documentation](https://registry.terraform.io/providers/UpCloudLtd/upcloud/latest/docs) for more details on how to configure the `upcloud` provider.

### Kubernetes

The Kubernetes provider is configured using certificates acquired with [upcloud_kubernetes_cluster data source](https://registry.terraform.io/providers/UpCloudLtd/upcloud/latest/docs/data-sources/kubernetes_cluster).

[Official documentation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) covers additional information needed to on how use the provider and it's resources.

## Provisioning

By default, we create a cluster where all cluster nodes have public IPs attached to them.

Running `terraform apply` in this directory will configure both cluster and deployment inside the cluster. See configurations in sub-directories for details.

```shell
terraform init
terraform plan
terraform apply
```

## Provisoning a cluster with private node groups

You can also create a cluster with private node groups by doing the following:

- Modify `main.tf` and uncomment `module.cluster_private` and `module.deployment_private`
- Modify `outputs.tf` and uncomment the relevant outputs

And then proceed with creating the resources:

```shell
terraform init
terraform plan
terraform apply
```