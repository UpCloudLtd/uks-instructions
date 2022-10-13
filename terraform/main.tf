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

  # Node group allows you to create a given amount of worker nodes with common set of customizations
  node_group {
    # Amount of worker nodes in this group
    count    = 2

    # Group name
    name     = "maingroup"

    # Plan for each worker node in this group
    plan     = data.upcloud_kubernetes_plan.small.description

    # Keys that will be added to `authorized_keys` file on each worker node; allows you to SSH into the worker node if needed
    ssh_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC12QhxQ0h3LeBILTNhQOOva6WsRG1Lk5urtCZt00I1c16mKF3Y1d1F4qFPgPOnjfr80XhkNnRAMArwdBbCJ/iqDPsYk6hhJH6FVgRafk3C6OwyeqLe3EuzzcjLYWP+9U/r6hfsTcSp9ndPHVad4mn970iz45wfSAGzk0jb9IcXo/2pH/T8YByCRPg3+OzAL8dDRAT/qVH+cM+xTnZHo47XNhFLR/PavWtV0vgYmjem32qdx4qdFGI5nLdh8+e2nGPd2f28z8qQkHRteORUfTYTmnWc2oqNSL7mapsRia2F1t83rKzHJpMoNUXzDnIDcGGb8Zhvo1+epc/B2lUV6OB+/aTrfYp0T/PQTBHMJBLFbl4avEEUBFjS/bR8pvYeR+YEzl0ou4j65zVJOL1vezX/j+fNYrgxI4IN18o3WBmS6vuUDlRFStjsxLGAKfoiwDMHo96M4bCuVBbICqGqjjjrb7WnalQzEmMAeCqjcs5q/Wr1T0X5Lv1+TulYBjNHgl2HhgO5tl+Ljthu3zad1+N6oy5ofxrNbFUOwyGmv4b1zGNksYG55s5XC1+kPBQhg0fFS1c5/M4kaf5a/thaW6RtmuzbMr5S01EUpMmh1+ygwgA8rcniPFW0ruebUcBktAq/K+1DE9a+JfCmqYYXgly0CGgk0+NYzCgi3suot1Emlw== admin@user.com"]

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

    # Kubernetes taint that will be added to each node in the group.
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
    ssh_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC12QhxQ0h3LeBILTNhQOOva6WsRG1Lk5urtCZt00I1c16mKF3Y1d1F4qFPgPOnjfr80XhkNnRAMArwdBbCJ/iqDPsYk6hhJH6FVgRafk3C6OwyeqLe3EuzzcjLYWP+9U/r6hfsTcSp9ndPHVad4mn970iz45wfSAGzk0jb9IcXo/2pH/T8YByCRPg3+OzAL8dDRAT/qVH+cM+xTnZHo47XNhFLR/PavWtV0vgYmjem32qdx4qdFGI5nLdh8+e2nGPd2f28z8qQkHRteORUfTYTmnWc2oqNSL7mapsRia2F1t83rKzHJpMoNUXzDnIDcGGb8Zhvo1+epc/B2lUV6OB+/aTrfYp0T/PQTBHMJBLFbl4avEEUBFjS/bR8pvYeR+YEzl0ou4j65zVJOL1vezX/j+fNYrgxI4IN18o3WBmS6vuUDlRFStjsxLGAKfoiwDMHo96M4bCuVBbICqGqjjjrb7WnalQzEmMAeCqjcs5q/Wr1T0X5Lv1+TulYBjNHgl2HhgO5tl+Ljthu3zad1+N6oy5ofxrNbFUOwyGmv4b1zGNksYG55s5XC1+kPBQhg0fFS1c5/M4kaf5a/thaW6RtmuzbMr5S01EUpMmh1+ygwgA8rcniPFW0ruebUcBktAq/K+1DE9a+JfCmqYYXgly0CGgk0+NYzCgi3suot1Emlw== admin@user.com"]

    labels = {
      managedBy = "also_terraform"
    }
  }
}

# With `hashicorp/local` Terraform provider one can output the kubeconfig to a file. The file can be easily
# used to configure `kubectl` or any other Kubernetes client.
resource "local_file" "kubeconfig" {
  content = data.upcloud_kubernetes_cluster.example.kubeconfig
  filename = "${path.module}/kubeconfig.yml"
}
