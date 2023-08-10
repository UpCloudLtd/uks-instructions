variable "objstorage_name" {
  type = string
}
variable "objstorage_size" {
  type = number
}

variable "bucket_name" {
  type = string
}
variable "zone" {
  type = string
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}
