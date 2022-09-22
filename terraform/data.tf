# Gather available pricing plans for Kubernetes node groups via data source
data "upcloud_kubernetes_plans" "example" {}

# Gather details of the newly created cluster via data source
data "upcloud_kubernetes_cluster" "example" {
  id = upcloud_kubernetes_cluster.example.id
}
