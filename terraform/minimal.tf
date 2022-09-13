variable "name" {
  default = "terraform-provider-upcloud-acc-test"
  type    = string
}

variable "cluster_zone" {
  default = "fi-hel2"
  type    = string
}

resource "upcloud_network" "cluster_private_network" {
  name = var.name
  zone = var.cluster_zone
  ip_network {
    address = "10.0.10.0/24"
    dhcp    = true
    family  = "IPv4"
  }
}

resource "upcloud_kubernetes_cluster" "cluster" {
  name    = var.name
  network = resource.upcloud_network.cluster_private_network.id
  node_groups = [
    {
      name = var.name
    }
  ]
  zone = cluster_zone
}
