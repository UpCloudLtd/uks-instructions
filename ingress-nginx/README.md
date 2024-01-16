# Using [Ingress NGINX Controller](https://kubernetes.github.io/ingress-nginx/) to expose Kubernetes deployments and services

In this tutorial we will create a Managed Kubernetes cluster, deploy an example app and expose it with Ingress Nginx
Controller. Last optional step will be to keep exxternal DNS records in sync for public access.

## Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- UpCloud API username and password set in `UPCLOUD_USERNAME` and `UPCLOUD_PASSWORD` env variables
- (optional) [CloudFlare DNS service](https://www.cloudflare.com/application-services/products/dns/) for setting up
  public DNS resolving
    - (optional) CloudFlare API key and email set in `TF_VAR_CF_API_KEY` and `TF_VAR_CF_API_EMAIL` env variables

## Create UpCloud Managed Kubernetes cluster with Terraform UpCloud provider

First, we'll create a Managed Kubernetes cluster to contain our workloads, like the ingress-nginx controller and our
example backend application deployment.

The following Terraform configurations can be split into multiple `.tf` files in the same directory or put in a single
file,
for example `main.tf`.

Replace the contents of `control_plane_ip_filter` property of `upcloud_kubernetes_cluster` resource with IP address(es)
and / or IP ranges that you want to access the cluster from.

```terraform
# Terraform block including `helm` and `kubernetes` providers for next steps
terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 3.3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
  }
}

# UpCloud provider
provider "upcloud" {
  # Username and password configuration arguments can be omitted, 
  # if environment variables UPCLOUD_USERNAME and UPCLOUD_PASSWORD are set.
  # username = ""
  # password = ""
}

# Router
resource "upcloud_router" "example-router" {
  name = "example-router"
}

# Network
resource "upcloud_network" "example-network" {
  name = "example-network"
  zone = "se-sto1"
  ip_network {
    address = "172.16.1.0/24"
    dhcp    = true
    family  = "IPv4"
  }

  router = upcloud_router.example-router.id
}

# Managed Kubernetes cluster
resource "upcloud_kubernetes_cluster" "example-cluster" {
  # Allow access to the cluster control plane from specified IPv4 ranges or addresses.
  control_plane_ip_filter = [
    "1.2.3.0/24",
    "1.2.4.1"
  ]
  name                = "example-cluster"
  network             = upcloud_network.example-network.id
  # Disable private node groups so Ingress NGINX controller can be accessed from external sources.
  private_node_groups = false
  zone                = upcloud_network.example-network.zone
}

# Managed Kubernetes node group
resource "upcloud_kubernetes_node_group" "example-node-group" {
  cluster    = upcloud_kubernetes_cluster.example-cluster.id
  name       = "example-node-group"
  node_count = 3
  plan       = "2xCPU-4GB"
}

```

Terraform `init` and `apply` commands to be run in the shell:

```shell
# To initialize Terraform configuration by acquiring the required providers
terraform init
# To apply the current configuration
terraform apply
```

## Deploy Ingress NGINX controller with Terraform Helm provider

Next we'll deploy [Ingress NGINX controller](https://kubernetes.github.io/ingress-nginx/) that we will need later on for
Kubernetes ingress objects.

Add the following to the Terraform configuration:

```terraform
# Managed Kubernetes cluster data source
data "upcloud_kubernetes_cluster" "example-cluster" {
  id = upcloud_kubernetes_cluster.example-cluster.id
}

# Helm provider
provider "helm" {
  kubernetes {
    client_certificate     = data.upcloud_kubernetes_cluster.example-cluster.client_certificate
    client_key             = data.upcloud_kubernetes_cluster.example-cluster.client_key
    cluster_ca_certificate = data.upcloud_kubernetes_cluster.example-cluster.cluster_ca_certificate
    host                   = data.upcloud_kubernetes_cluster.example-cluster.host
  }
}

# Helm release for Ingress NGINX controller
resource "helm_release" "example-release-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"

  values = [
    <<-EOT
    controller:
      hostNetwork: true
      replicaCount: 3
    service:
      type: NodePort
    EOT
  ]
}
```

Terraform `apply` command to be run in the shell:

```shell
# To apply the current configuration
terraform apply
```

## Expose services over Ingress objects with Terraform Kubernetes provider

Now that we have an ingress controller, next step is to create a deployment for our backend application and expose it
inside the cluster via service object. We will also create an ingress object for the incoming external traffic.

In this example, we gather the objects under the `example-namespace` namespace for easier management.

Add the following to the Terraform configuration:

```terraform
# Kubernetes provider
provider "kubernetes" {
  client_certificate     = data.upcloud_kubernetes_cluster.example-cluster.client_certificate
  client_key             = data.upcloud_kubernetes_cluster.example-cluster.client_key
  cluster_ca_certificate = data.upcloud_kubernetes_cluster.example-cluster.cluster_ca_certificate
  host                   = data.upcloud_kubernetes_cluster.example-cluster.host
}

# Kubernetes namespace
resource "kubernetes_namespace_v1" "example-namespace" {
  metadata {
    name = "example-namespace"
  }
}

# Kubernetes deployment
resource "kubernetes_deployment_v1" "example-deployment" {
  metadata {
    name      = "example-deployment"
    namespace = kubernetes_namespace_v1.example-namespace.metadata.0.name
    labels    = {
      app = "example-app"
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "example-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "example-app"
        }
      }
      spec {
        container {
          image = "ghcr.io/upcloudltd/hello:hello-v1.1.0"
          name  = "hello"

          port {
            container_port = 80
          }
        }
        host_network = false
      }
    }
  }
}

# Kubernetes service
resource "kubernetes_service_v1" "example-service" {
  metadata {
    name      = "example-service"
    namespace = kubernetes_namespace_v1.example-namespace.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.example-deployment.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = kubernetes_deployment_v1.example-deployment.spec.0.template.0.spec.0.container.0.port.0.container_port
    }
  }
}

# Kubernetes ingress
resource "kubernetes_ingress_v1" "example-ingress" {
  metadata {
    name      = "example-ingress"
    namespace = kubernetes_namespace_v1.example-namespace.metadata.0.name
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/example-path"
          backend {
            service {
              name = kubernetes_service_v1.example-service.metadata.0.name
              port {
                number = kubernetes_service_v1.example-service.spec.0.port.0.port
              }
            }
          }
        }
      }
    }
  }
}

# Kubeconfig local file for accessing the cluster with kubectl 
resource "local_file" "kubeconfig-example" {
  content  = data.upcloud_kubernetes_cluster.example-cluster.kubeconfig
  filename = "${path.module}/kubeconfig-example.yml"
}

```

Terraform `apply` command to be run in the shell:

```shell
# To apply the current configuration
terraform apply
```

To find out the external IP addresses of the Kubernetes nodes for accessing your apps, you can use kubectl:

```shell
# To output the Kubernetes node information
KUBECONFIG=./kubeconfig-example.yml kubectl get nodes -o wide
```

Pointing your browser to `http://<EXTERNAL-IP>/example-app` will respond with the contents of our example app.

## (Optional) Keep external DNS records in sync with [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) and [CloudFlare DNS service](https://www.cloudflare.com/application-services/products/dns/)

In this example, we are using CloudFlare DNS service as an example for managing the DNS records.

Modify the existing Helm release for Ingress NGINX controller to match the following in the Terraform configuration: (
replace `example.com` with your hostname)

```terraform
# Helm release for Ingress NGINX controller
resource "helm_release" "example-release-ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"

  values = [
    <<-EOT
    controller:
      hostNetwork: true
      replicaCount: 3
      service:
        annotations:
          external-dns.alpha.kubernetes.io/hostname: example.com.
        type: NodePort
    EOT
  ]
}
```

Add the following to the Terraform configuration:

```terraform
# Input variables for configuring ExternalDNS CloudFlare authentication
variable "CF_API_KEY" {
  type = string
}

variable "CF_API_EMAIL" {
  type = string
}

# Helm release for ExternalDNS
resource "helm_release" "example-release-external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.13.1"

  values = [
    <<-EOT
    env:
      - name: CF_API_KEY
        value: ${var.CF_API_KEY}
      - name: CF_API_EMAIL
        value: ${var.CF_API_EMAIL}
    provider: cloudflare
    EOT
  ]
}
```

Terraform `apply` command to be run in the shell:

```shell
# To apply the current configuration
terraform apply
```

After the DNS records have propagated, the example app is now available via `http://<HOSTNAME>/example-app`.


## Destroy the provisioned infrastructure

Terraform `destroy` command to be run in the shell:
```shell
# To destroy the current configuration
terraform destroy
```
