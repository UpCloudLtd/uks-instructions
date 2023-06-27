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


resource "upcloud_object_storage" "velero" {
  description = "S3 Object Storage Target for Velero Backups"
  name        = var.objstorage_name
  size        = var.objstorage_size
  zone        = var.zone

  # Keep thoese values as empty string to let the provider know that it should take 
  # the values from environment variables
  access_key = var.access_key
  secret_key = var.secret_key

  bucket {
    name = var.bucket_name
  }
}

# Authentication file for Velero to connect with the object storage bucket
resource "local_file" "velero-secret-file" {
  content  = <<-EOT
[default]
aws_access_key_id=${var.access_key}
aws_secret_access_key=${var.secret_key}
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