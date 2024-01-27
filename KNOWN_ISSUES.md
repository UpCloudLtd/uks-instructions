# Known issues

This document lists current known issues with UpCloud Kubernetes Service.

## Cluster configuration
- Before creating the cluster, note that there are the following reserved CIDRs (your SDN should have CIDR not intersected with):
  * Control Plane CIDR: `172.31.240.0/24`
  * Service CIDR: `10.128.0.0/12`
  * POD CIDR: `192.168.0.0/16`
  * Forwarder CIDR: `10.33.128.0/22`
  * Utility CIDR (per cluster zone):
    - fi-hel1: `10.1.0.0/16`
    - uk-lon1: `10.2.0.0/16`
    - us-chi1: `10.3.0.0/16`
    - de-fra1: `10.4.0.0/16`
    - nl-ams1: `10.5.0.0/16`
    - fi-hel2: `10.6.0.0/16`
    - es-mad1: `10.7.0.0/16`
    - us-sjo1: `10.8.0.0/16`
    - us-nyc1: `10.9.0.0/16`
    - sg-sin1: `10.10.0.0/16`
    - pl-waw1: `10.11.0.0/16`
    - au-syd1: `10.12.0.0/16`
    - se-sto1: `10.13.0.0/16`
    
- You need to wait for cluster to get into `running` state before attempting to scale node groups or deleting the cluster, otherwise some resources might
not be cleaned up properly


## Load balancing

- Network configuration for automatically provisioned load balancers is not supported yet. Internal load balancers cannot be used.

## UI

- Upon cluster deletion, the UI might show cluster status as "running".

## Terraform

- When creating an `upcloud_network` resource that will be used to deploy `upcloud_kubernetes_cluster`, the user has to use `ignore_changes=[router]` lifecycle meta-argument (see [terraform example](terraform/main.tf)). This is caused by the fact that UKS creates a router and attaches it to the provided network to ensure that cluster networking works correctly. Without the `ignore_changes` argument, TF will attempt to detach a router on the next apply.
- When running `terraform destroy` on a config that has both `upcloud_kubernetes_cluster` and `upcloud_network` (and if that network was used to create a cluster) user might encounter `PART_OF_SERVICE` error during network deletion. If that happens - just wait some time (10-15 minutes) and rerun `terraform destroy`. Network should be deleted on the next attempt.
