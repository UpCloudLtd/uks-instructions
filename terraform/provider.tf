terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 2.6"
    }
  }
}

provider "upcloud" {
  # username and password configuration arguments can be omitted  
  # if environment variables UPCLOUD_USERNAME and UPCLOUD_PASSWORD are set
  # username = ""
  # password = ""
}

provider "kubernetes" {
  client_certificate     = data.upcloud_kubernetes_credentials.example.client_certificate
  client_key             = data.upcloud_kubernetes_credentials.example.client_key
  cluster_ca_certificate = data.upcloud_kubernetes_credentials.example.cluster_ca_certificate
  host                   = data.upcloud_kubernetes_credentials.example.host
}