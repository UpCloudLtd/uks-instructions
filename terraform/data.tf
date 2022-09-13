# Read the credentials of the newly created cluster
data "upcloud_kubernetes_credentials" "example" {
  cluster_id = upcloud_kubernetes_cluster.example.id
}
