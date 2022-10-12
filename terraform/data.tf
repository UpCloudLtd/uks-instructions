# Gather available pricing plans for Kubernetes node groups via data source
data "upcloud_kubernetes_plan" "small" {
  # Currently valid plan names include "small", "medium" and "large"
  name = "small"
}

# Gather details of the newly created cluster via data source
data "upcloud_kubernetes_cluster" "example" {
  # ID references an output field of a `upcloud_kubernetes_cluster` resource in this particular Terraform configuration.
  # If referencing a cluster created outside this Terraform configuration, one can use a literal string value
  # (`id = "my-cluster"`) instead.
  id = upcloud_kubernetes_cluster.example.id
}
