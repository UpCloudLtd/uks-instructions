# Example Terraform configuration

This directory contains a basic configuration for Terraform to get started with our UpCloud Kubernetes Service (UKS).

## Structure

Configuration is organized into separate files:

- [data.tf](data.tf)
    - read-only data sources like `upcloud_kubernetes_credentials` 
- [main.tf](main.tf)
    - managed resources like `upcloud_kubernetes_cluster` 
- [provider.tf](provider.tf)
    - main `terraform` block and provider specific configurations 
- [variables.tf](variables.tf)
    - (input) variables like `zone`

## Setup

### UpCloud
See [the official UpCloud Terraform provider documentation](https://registry.terraform.io/providers/UpCloudLtd/upcloud/latest/docs) on how to configure the actual `upcloud` provider.

### Kubernetes
There are default values for [provider.tf](provider.tf) that allow the provider to authenticate against the Kubernetes cluster defined in this configuration. Credentials are acquired from `upcloud_kubernetes_credentials`, defined in [data.tf](data.tf).

[Official documentation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) covers additional information needed to on how use the provider and it's resources.

## Provisioning

Running apply in this directory will create a network, a cluster and a namespace in the cluster:

```shell
terraform init
terraform plan
terraform apply
```