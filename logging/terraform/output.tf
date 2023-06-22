output "opensearch_host" {
  value = upcloud_managed_database_opensearch.dbaas_opensearch.service_host
}

output "opensearch_user" {
  value = upcloud_managed_database_user.fluentbit_user.username
}
output "opensearch_pass" {
  value = nonsensitive(upcloud_managed_database_user.fluentbit_user.password)
}
