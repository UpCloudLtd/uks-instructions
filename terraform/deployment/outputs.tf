output "app_url" {
  value = kubernetes_service.this.status[0].load_balancer[0].ingress[0].hostname
}
