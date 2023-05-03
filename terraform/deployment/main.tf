resource "kubernetes_deployment" "this" {
  metadata {
    labels = { app = var.app_name }
    name   = var.app_name
  }

  spec {
    replicas = "8"
    template {
      metadata { labels = { app = var.app_name } }
      spec {
        container {
          image             = "ghcr.io/upcloudltd/hello"
          image_pull_policy = "Always"
          name              = "hello"
        }
      }
    }
    selector {
      match_labels = { app = var.app_name }
    }
  }
}

resource "kubernetes_service" "this" {
  metadata {
    labels = { app = var.app_name }
    name   = var.app_name
  }
  spec {
    type = "LoadBalancer"
    port {
      port        = 80
      protocol    = "TCP"
      target_port = "80"
    }
    selector = { app = var.app_name }
  }
}
