# Create a network for your cluster
resource "upcloud_network" "example" {
  name = "my-cluster-network"
  zone = var.zone
  ip_network {
    address = "172.16.1.0/24"
    dhcp    = true
    family  = "IPv4"
  }
}

# Create a cluster
resource "upcloud_kubernetes_cluster" "example" {
  name    = "my-cluster"
  network = upcloud_network.example.id
  zone    = var.zone
}

# Create a node group for your cluster
# Node group is a group of worker nodes that are created based on the same template
# You can have multiple node groups with different configurations in your cluster
resource "upcloud_kubernetes_node_group" "group" {
  name       = "medium"

  // All nodes in this group will be joined to this cluster
  cluster    = upcloud_kubernetes_cluster.example.id

  // The amount of created nodes (servers)
  node_count = 2

  // Plan for each node; you can check available plans with upcloud CLI tool (`upctl server plans`) or by making a call to API (https://developers.upcloud.com/1.3/7-plans/)
  plan       = "2xCPU-4GB"

  // Each node in this group will have the following labels
  labels = {
    managedBy = "terraform"
  }

  // Each node in this group will have this taint
  taint {
    effect = "NoExecute"
    key    = "taintKey"
    value  = "taintValue"
  }
}


data "upcloud_kubernetes_cluster" "example" {
  id = upcloud_kubernetes_cluster.example.id
}

# With `hashicorp/local` Terraform provider one can output the kubeconfig to a file. The file can be easily
# used to configure `kubectl` or any other Kubernetes client.
resource "local_file" "kubeconfig" {
  content = data.upcloud_kubernetes_cluster.example.kubeconfig
  filename = "${path.module}/kubeconfig.yml"
}
