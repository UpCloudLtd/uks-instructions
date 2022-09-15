# Gather details of the newly created cluster via data source
data "upcloud_kubernetes_cluster" "example" {
  id = upcloud_kubernetes_cluster.example.id
}
