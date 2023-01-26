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

  // Each node in this group will have this key added to authorized keys (for "debian" user)
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC12QhxQ0h3LeBILTNhQOOva6WsRG1Lk5urtCZt00I1c16mKF3Y1d1F4qFPgPOnjfr80XhkNnRAMArwdBbCJ/iqDPsYk6hhJH6FVgRafk3C6OwyeqLe3EuzzcjLYWP+9U/r6hfsTcSp9ndPHVad4mn970iz45wfSAGzk0jb9IcXo/2pH/T8YByCRPg3+OzAL8dDRAT/qVH+cM+xTnZHo47XNhFLR/PavWtV0vgYmjem32qdx4qdFGI5nLdh8+e2nGPd2f28z8qQkHRteORUfTYTmnWc2oqNSL7mapsRia2F1t83rKzHJpMoNUXzDnIDcGGb8Zhvo1+epc/B2lUV6OB+/aTrfYp0T/PQTBHMJBLFbl4avEEUBFjS/bR8pvYeR+YEzl0ou4j65zVJOL1vezX/j+fNYrgxI4IN18o3WBmS6vuUDlRFStjsxLGAKfoiwDMHo96M4bCuVBbICqGqjjjrb7WnalQzEmMAeCqjcs5q/Wr1T0X5Lv1+TulYBjNHgl2HhgO5tl+Ljthu3zad1+N6oy5ofxrNbFUOwyGmv4b1zGNksYG55s5XC1+kPBQhg0fFS1c5/M4kaf5a/thaW6RtmuzbMr5S01EUpMmh1+ygwgA8rcniPFW0ruebUcBktAq/K+1DE9a+JfCmqYYXgly0CGgk0+NYzCgi3suot1Emlw== admin@user.com"
  ]
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
