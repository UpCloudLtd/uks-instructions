# Cluster configuration

- You cannot control control plane size. In the Alpha test control plane is run as a standalone instance.
- You cannot modify cluster configuration after cluster creation. Please create a new cluster.

# UI

- Upon cluster deletion, the UI might show cluster status as "running".

# Terraform

- When running `terraform destroy` on a config that has both `upcloud_kubernetes_cluster` and `upcloud_network` (and if that network was used to create a cluster) user might encounter `PART_OF_SERVICE` error during network deletion. If that happens - just wait some time (10-15 minutes) and rerun `terraform destroy`. Network should be deleted on the next attempt.

# Networking

- Intermittent timeout issues when running `kubectl logs` and `kubectl exec`. Work around it by re-running the command(s).
- Load balancers are not always deleted upon cluster deletion. Please check after tests that there are no leftover load balancers on your account.
