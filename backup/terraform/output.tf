output "velero_url" {
  value = upcloud_object_storage.velero.url
}

output "access_key" {
  value = nonsensitive(upcloud_object_storage.velero.access_key)
}

output "secret_key" {
  value = nonsensitive(upcloud_object_storage.velero.secret_key)
}
