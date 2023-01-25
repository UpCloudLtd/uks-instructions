# Cluster configuration

- You cannot specify control plane size. In the Closed Beta control plane is run as a standalone instance.

# UI

- Upon cluster deletion, the UI might show cluster status as "running".

# Terraform

- When running `terraform destroy` on a config that has both `upcloud_kubernetes_cluster` and `upcloud_network` (and if that network was used to create a cluster) user might encounter `PART_OF_SERVICE` error during network deletion. If that happens - just wait some time (10-15 minutes) and rerun `terraform destroy`. Network should be deleted on the next attempt.
