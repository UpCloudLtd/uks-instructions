module "cluster" {
  source = "./cluster"

  basename         = var.basename
  store_kubeconfig = false
  zone             = var.zone
}

module "deployment" {
  source = "./deployment"

  cluster_id = module.cluster.cluster_id
}
