variable "basename" {
  default     = "uks-cluster-example"
  description = "Basename to use when naming resources created by this configuration."
  type        = string
}

variable "zone" {
  default     = "de-fra1"
  description = "UpCloud zone for resource provisioning."
  type        = string
}

variable "store_kubeconfig" {
  default     = true
  description = "If set to `true`, store kubeconfig as a file with `local_file` to module path."
  type        = bool
}

variable "ip_network_range" {
  default = "172.16.1.0/24"
  description = "CIDR range used by the cluster SDN network."
  type = string
}
