# Create a router for your network
resource "upcloud_router" "example" {
  name = "${var.basename}-router"
}

# Create a network for your cluster
resource "upcloud_network" "example" {
  name = "${var.basename}-net"
  zone = var.zone

  ip_network {
    address = var.ip_network_range
    dhcp    = true
    dhcp_default_route = true
    family  = "IPv4"
  }

  router = upcloud_router.example.id
}

# Create a Managed NAT GW for Internet connectivity from the SDN network
resource "upcloud_gateway" "example" {
  name     = "${var.basename}-gw"
  zone     = var.zone
  features = ["nat"]

  router {
    id = upcloud_router.example.id
  }
}

# Create a cluster
resource "upcloud_kubernetes_cluster" "example" {
  name                = "${var.basename}-cluster"
  network             = upcloud_network.example.id
  zone                = var.zone
  private_node_groups = true

  depends_on = [upcloud_gateway.example]
}

# Create a node group for your cluster
# Node group is a group of worker nodes that are created based on the same template
# You can have multiple node groups with different configurations in your cluster
resource "upcloud_kubernetes_node_group" "group" {
  name = "medium"

  // All nodes in this group will be joined to this cluster
  cluster = upcloud_kubernetes_cluster.example.id

  // The amount of created nodes (servers)
  node_count = 2

  // Plan for each node; you can check available plans with upcloud CLI tool (`upctl server plans`) or by making a call to API (https://developers.upcloud.com/1.3/7-plans/)
  plan = "2xCPU-4GB"

  // With `anti_affinity` set to true, UKS will attempt to deploy nodes in this group to different compute hosts
  anti_affinity = true

  // Each node in this group will have the following labels
  labels = {
    managedBy = "terraform"
    project   = "uks-instructions"
  }

  // If uncommented, Eeach node in this group will have this taint
  # taint {
  #   effect = "NoExecute"
  #   key    = "key"
  #   value  = "value"
  # }

  // Each node in this group will have keys defined in this list configured as authorized keys (for "debian" user)
  ssh_keys = []
}

data "upcloud_kubernetes_cluster" "example" {
  id = upcloud_kubernetes_cluster.example.id
}

# With `hashicorp/local` Terraform provider one can output the kubeconfig to a file. The file can be easily
# used to configure `kubectl` or any other Kubernetes client.
resource "local_file" "kubeconfig" {
  count = var.store_kubeconfig ? 1 : 0

  content  = data.upcloud_kubernetes_cluster.example.kubeconfig
  filename = "${path.module}/kubeconfig.yml"
}
