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

resource "random_password" "access_key" {
  length      = 20
  special     = false
  min_numeric = 2
  lower       = false
}

resource "random_password" "secret_key" {
  length           = 40
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_string" "objstorage_suffix" {
  length      = 8
  special     = false
  upper       = false
  min_numeric = 2
}

resource "upcloud_object_storage" "velero" {
  description = "S3 Object Storage Target for Velero Backups"
  name        = "${var.objstorage_name}-${random_string.objstorage_suffix.result}"
  size        = var.objstorage_size
  zone        = var.zone

  # Keep these values as empty string to let the provider know that it should take 
  # the values from environment variables. If no environmental values are available,
  # autogenerate keys
  access_key = var.access_key == "" ? random_password.access_key.result : var.access_key
  secret_key = var.secret_key == "" ? random_password.secret_key.result : var.secret_key

  bucket {
    name = var.bucket_name
  }
}

# Authentication file for Velero to connect with the object storage bucket
resource "local_file" "velero-secret-file" {
  content  = <<-EOT
[default]
aws_access_key_id=${upcloud_object_storage.velero.access_key}
aws_secret_access_key=${upcloud_object_storage.velero.secret_key}
EOT
  filename = "${path.module}/velero-secret-file.txt"

}

# Bash script to install Velero. The Kubernetes volumesnapshotclass needs to be labeled with velero tag to enable CSI snapshots.
# Run the script after terraform has finished.
resource "local_file" "velero-install" {
  content  = <<-EOT
#!/bin/bash
velero install --features=EnableCSI --plugins velero/velero-plugin-for-aws:v1.7.0 --bucket ${var.bucket_name} --backup-location-config region=${var.zone},s3ForcePathStyle=true,s3Url=${upcloud_object_storage.velero.url} --secret-file ./velero-secret-file.txt --provider aws --snapshot-location-config region=${var.zone}
velero plugin add velero/velero-plugin-for-csi:v0.5.0
kubectl label volumesnapshotclasses.snapshot.storage.k8s.io upcloud-csi-snapshotclass velero.io/csi-volumesnapshot-class="true"
EOT
  filename = "${path.module}/velero-install.sh"
} 