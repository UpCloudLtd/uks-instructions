#######################################
# Cluster with public IP connectivity #
#######################################

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

####################################
# Cluster with private node groups #
####################################

#module "cluster_private" {
#  source = "./cluster-with-private-node-groups"
#
#  basename         = "${var.basename}-private"
#  store_kubeconfig = false
#  zone             = var.zone
#}
#
#module "deployment_private" {
#  source = "./deployment"
#
#  cluster_id = module.cluster_private.cluster_id
#}
