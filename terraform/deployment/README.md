# Example Terraform configuration for a deployment

This directory contains a basic Terraform configuration to get started with using Kubernetes provider with our UpCloud Kubernetes Service (UKS).

## Structure

Configuration is organized into separate files:

- [data.tf](data.tf)
    - read-only data sources (`upcloud_kubernetes_cluster`, `upcloud_kubernetes_plans`)
- [main.tf](main.tf)
    - managed resources (`upcloud_kubernetes_cluster`, `upcloud_network`) 
- [provider.tf](provider.tf)
    - main `terraform` block and provider specific configurations
- [variables.tf](variables.tf)
    - (input) variables (`app_name`, `cluster_id`)
- [outputs.tf](outputs.tf)
    - (output) values (`app_url`)

## Provider setup

### UpCloud

See [the official UpCloud Terraform provider documentation](https://registry.terraform.io/providers/UpCloudLtd/upcloud/latest/docs) on how to configure the actual `upcloud` provider.

### Kubernetes

There are default values for [provider.tf](provider.tf) that allow the provider to authenticate against the Kubernetes cluster defined by `cluster_id` variable.

[Official documentation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) covers additional information needed to on how use the provider and it's resources.

## Provisioning

Running apply in this directory will create a deployment and expose it through an load-balancer:

```shell
terraform init
terraform plan
terraform apply
```
