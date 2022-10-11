# Cluster configuration

- You cannot control control plane size. In the Alpha test control plane is run as a standalone instance.
- You cannot modify cluster configuration after cluster creation. Please create a new cluster.

# UI

- Upon cluster deletion, the UI might show cluster status as "running".

# Terraform

- Cluster deletion might take as long as 20 minutes.

# Load balancing

- Load balancers are not always deleted upon cluster deletion. Please check after tests that there are no leftover load balancers on your account.
