variable "cluster_version" {
  default     = "1.23.5"
  description = "Kubernetes version for the cluster"
  type        = string
}

variable "zone" {
  default     = "de-fra1"
  description = "UpCloud zone for resource provisioning"
  type        = string
}
