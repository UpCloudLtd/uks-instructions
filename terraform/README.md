# Example Terraform configuration

This directory contains a basic Terraform configuration to get started with our UpCloud Kubernetes Service (UKS).

## Structure

Configuration is organized into separate files:

- [data.tf](data.tf)
    - read-only data sources (`upcloud_kubernetes_cluster`, `upcloud_kubernetes_plans`)
- [main.tf](main.tf)
    - managed resources (`upcloud_kubernetes_cluster`, `upcloud_network`) 
- [provider.tf](provider.tf)
    - main `terraform` block and provider specific configurations
- [variables.tf](variables.tf)
    - (input) variables (`zone`)

## Provider setup

### UpCloud

See [the official UpCloud Terraform provider documentation](https://registry.terraform.io/providers/UpCloudLtd/upcloud/latest/docs) on how to configure the actual `upcloud` provider.

### Kubernetes

There are default values for [provider.tf](provider.tf) that allow the provider to authenticate against the Kubernetes cluster defined in this configuration. Credentials are acquired from `upcloud_kubernetes_cluster`, defined in [data.tf](data.tf).

[Official documentation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) covers additional information needed to on how use the provider and it's resources.

## Provisioning

Running apply in this directory will create a network, a cluster and a Kubernetes namespace in the newly created cluster:

```shell
terraform init
terraform plan
terraform apply
```
