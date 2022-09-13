# Create a network for the Kubernetes cluster
resource "upcloud_network" "example" {
  name = "example-network"
  zone = var.zone
  ip_network {
    address = "172.16.1.0/24"
    dhcp    = true
    family  = "IPv4"
  }
}

# Create a Kubernetes cluster
resource "upcloud_kubernetes_cluster" "example" {
  auto_upgrade = true
  description  = "example cluster"
  labels = {
    managedBy = "terraform"
  }
  maintenance_period = {
    dow  = "sun"
    hour = 3
  }
  name    = "example"
  network = upcloud_network.cluster_private_network.id
  node_groups = [
    {
      count = 4
      labels = {
        managedBy = "terraform"
      }
      name = "node-group-large"
      plan = "K8S-8xCPU-32GB"
    },
    {
      count = 8
      labels = {
        managedBy = "terraform"
      }
      name = "node-group-medium"
      plan = "K8S-4xCPU-8GB"
    }
  ]
  type    = "standalone"
  version = var.cluster_version
  zone    = var.zone
}
