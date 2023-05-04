terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = ">= 2.8.4"
    }
  }
}

provider "upcloud" {
  # It is recommended to use UPCLOUD_USERNAME and UPCLOUD_PASSWORD for providing the credentials to the provider.
}

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
