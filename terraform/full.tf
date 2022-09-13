variable "name" {
  default = "terraform-provider-upcloud-test"
  type    = string
}

variable "cluster_zone" {
  default = "fi-hel2"
  type    = string
}

resource "upcloud_network" "cluster_private_network" {
  name = "terraform-provider-upcloud-test"
  zone = var.cluster_zone
  ip_network {
    address = "10.0.10.0/24"
    dhcp    = true
    family  = "IPv4"
  }
}

resource "upcloud_kubernetes_cluster" "c" {
  auto_upgrade = true
  description  = "test"
  labels = {
    managedBy = var.name
  }
  maintenance_period = {
    dow  = "mon"
    hour = 0
  }
  name    = var.name
  network = resource.upcloud_network.cluster_private_network.id
  node_groups = [
    {
      count = 1
      labels = {
        managedBy = var.name
        env       = "dev"
      }
      name = var.name
      plan = "1xCPU-1GB"
    },
    {
      count = 1
      labels = {
        managedBy = var.name
        env       = "qa"
      }
      name = var.name
      plan = "1xCPU-2GB"
    }
  ]
  type    = "standalone"
  version = "1.23.5"
  zone    = cluster_zone
}
