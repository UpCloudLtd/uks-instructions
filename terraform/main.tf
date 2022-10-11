# Create a network for your cluster
resource "upcloud_network" "example" {
  name = "my-cluster-network"
  zone = var.zone
  ip_network {
    address = "10.0.95.0/24"
    dhcp    = true
    family  = "IPv4"
  }
}

# Create a cluster
resource "upcloud_kubernetes_cluster" "example" {
  name    = "my-cluster"
  network = upcloud_network.example.id
  zone    = var.zone

  # Node group allows you to create a number of worker nodes with common customizations
  node_group {
    # Amount of worker nodes in this group
    count    = 2

    # Group name
    name     = "maingroup"

    # Plan for each worker node in this group 
    plan     = data.upcloud_kubernetes_plan.small.description

    # Keys that will be added to `autorized_keys` file on each worker node; allows you to SSH into the worker node if needed
    ssh_keys = ["your_public_ssh_key"]

    # Labels that will be added to each node in the group
    labels = {
      managedBy = "terraform"
    }

    # Arguments that will be passed to kubelet CLI for each of the worker nodes in this group
    # WARNING - those arguments are passed without any validation; using invalid arguments will prevent your worker nodes from being functional
    # Use this only if you know exactly what you are doing
    kubelet_args = {
      arg1 = "arg1value"
    }

    # Taint that will be added to each node in the group
    taint {
      effect = "NoExecute"
      key = "taintKey"
      value = "taintValue"
    }
  }

  # Another group of worker nodes
  node_group {
    count    = 2
    name     = "secondarygroup"
    plan     = data.upcloud_kubernetes_plan.small.description
    ssh_keys = ["your_other_public_ssh_key"]

    labels = {
      managedBy = "also_terraform"
    }
  }
}

# This create a kubeconfig file for you that you can easily use with `kubectl`
resource "local_file" "kubeconfig" {
  content = data.upcloud_kubernetes_cluster.prod_data.kubeconfig
  filename = "${path.module}/kubeconfig.yml"
}
