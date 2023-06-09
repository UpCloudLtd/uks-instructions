terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = ">= 2.11.0"
    }
  }
}

# Empty provider block disabled by default
#provider "upcloud" {
# username and password configuration arguments can be omitted
# if environment variables UPCLOUD_USERNAME and UPCLOUD_PASSWORD are set
# username = ""
# password = ""
#}

data "upcloud_kubernetes_cluster" "example" {
  id = var.cluster_id
}

# Kubernetes provider configuration uses the data source
provider "kubernetes" {
  client_certificate     = data.upcloud_kubernetes_cluster.example.client_certificate
  client_key             = data.upcloud_kubernetes_cluster.example.client_key
  cluster_ca_certificate = data.upcloud_kubernetes_cluster.example.cluster_ca_certificate
  host                   = data.upcloud_kubernetes_cluster.example.host
}
