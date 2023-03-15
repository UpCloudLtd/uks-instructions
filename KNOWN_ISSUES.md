# Known issues

This document lists current known issues with UKS Open Beta.

## Cluster configuration

- You cannot specify control plane size. In the beta control plane is run as a standalone instance.
- You need to wait for cluster to get into `running` state before attempting to scale node groups or deleting the cluster, otherwise some resources might
not be cleaned up properly
- If you are attempting to access your cluster with a brand new `KubeConfig` and receive an error `no route to host`, this means that the DNS has not been
fully configured, and you will need to wait a few more minutes. Alternatively, you can flush your local DNS cache with:
`sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder` (or the alike)

## UI

- Upon cluster deletion, the UI might show cluster status as "running".

## Terraform

- When creating an `upcloud_network` resource that will be used to deploy `upcloud_kubernetes_cluster`, the user has to use `ignore_changes=[router]` lifecycle meta-argument (see [terraform example](terraform/main.tf)). This is caused by the fact that UKS creates a router and attaches it to the provided network to ensure that cluster networking works correctly. Without the `ignore_changes` argument, TF will attempt to detach a router on the next apply.
- When running `terraform destroy` on a config that has both `upcloud_kubernetes_cluster` and `upcloud_network` (and if that network was used to create a cluster) user might encounter `PART_OF_SERVICE` error during network deletion. If that happens - just wait some time (10-15 minutes) and rerun `terraform destroy`. Network should be deleted on the next attempt.

## Security

- Currently cluster users have wider permissions than we would hope. CSI user within the cluster has access to all the servers within the main account and sub accounts can use these credentials to gain wider access than would be normally allowed. We will be limiting this during the public beta.
