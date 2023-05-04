variable "cluster_id" {
  description = "UUID of the cluster to use for the deployment."
  type        = string
}

variable "app_name" {
  default     = "hello-uks"
  description = "Name for the application."
  type        = string
}
