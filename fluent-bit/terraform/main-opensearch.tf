terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 2.11"
    }
  }
}

provider "upcloud" {
  # Your UpCloud credentials are read from the environment variables:
  # export UPCLOUD_USERNAME="Username of your UpCloud API user"
  # export UPCLOUD_PASSWORD="Password of your UpCloud API user"
}

resource "upcloud_managed_database_opensearch" "dbaas_opensearch" {
  name           = "opensearch-uks-demo"
  plan           = var.opensearch_plan
  zone           = var.zone
  access_control = true
  #If enabled, the user gets access to _bulk, _msearch and _mget for all allowed indices 
  extended_access_control = false
  properties {
    #To access the dashboard from public cloud, this needs to be enabled. The API traffic goes through private network
    public_access = true
    #Allow access from all IPs, disable in production
    ip_filter = ["0.0.0.0/0"]
  }
}

resource "upcloud_managed_database_user" "fluentbit_user" {
  service  = upcloud_managed_database_opensearch.dbaas_opensearch.id
  username = "fluentbit"
  opensearch_access_control {
    rules {
      index      = "uks*"
      permission = "readwrite"
    }
    rules {
      #Fluent-bit needs _bulk access in addition to index access
      index      = "_bulk*"
      permission = "readwrite"
    }
  }
}

# Use this as a Helm values file when installing the fluent-bit Helm chart
resource "local_file" "opensearch-fluentbit-output" {
  content  = <<-EOT
config:
  outputs: |
    [OUTPUT]
        Name opensearch
        Match *
        Host ${upcloud_managed_database_opensearch.dbaas_opensearch.service_host}
        Port ${upcloud_managed_database_opensearch.dbaas_opensearch.service_port}
        HTTP_User ${upcloud_managed_database_user.fluentbit_user.username}
        HTTP_Passwd ${upcloud_managed_database_user.fluentbit_user.password}
        tls on
        Suppress_Type_Name On
        Index uks
        Trace_Error off
        Replace_Dots On
EOT
  filename = "${path.module}/opensearch-fluentbit-helm-values.yaml"

}