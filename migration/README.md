# Migrating workloads from one UKS cluster to another using Velero

This is an example of how to migrate workloads from an existing
[UKS](https://upcloud.com/products/managed-kubernetes)
cluster to a new UKS cluster.

## Prerequisites

- Your existing UKS cluster
- A new, fresh UKS cluster (the one you want to migrate to)
- [Velero
  CLI](https://velero.io/docs/main/basic-install/#install-the-cli)
- [s3cmd](https://s3tools.org/s3cmd)

## Some notes before migrating

- Velero doesn't support restoring into a cluster with a lower
  Kubernetes version than where the backup was taken.
- This guide will not cover migrating persistent volumes.
- Going forth, the initial cluster will be referred to as "Cluster A"
  and the new cluster, "Cluster B".

## Set up object storage bucket

We will configure Velero to use [Object Storage
2.0](https://upcloud.com/products/object-storage) to store backup data
from Cluster A. We will then use this to restore into Cluster B.

- In the [Hub](https://hub.upcloud.com), head to the Object Storages
  page and hit 'Create Object Storage'. Choose your desired region,
  storage size and name and hit create.
- Then, head to the Users tab under your new Object Storage instance and
  click '+ Access Key'. Give it a name, and copy the resulting Access
  and Secret keys into a text file somewhere. We will need this to
  create our bucket next.
- To create a bucket in your new Object Storage instance, we will use
  `s3cmd`. Let's use the interactive configuration wizard:

  ```
  s3cmd --configure

  Access Key: {access_key}
  Secret Key: {secret_key}
  Default Region [US]:    # leave as default

  S3 Endpoint [s3.amazonaws.com]: {hostname}

  DNS-style bucket+hostname:port template for accessing a bucket [%(bucket)s.s3.amazonaws.com]: %(bucket).{hostname}

  Encryption password:   # hit enter
  Path to GPG program:   # leave as default

  Use HTTPS protocol [Yes]:  # hit enter

  HTTP Proxy server name:   # leave empty

  ...

  Test access with supplied credentials? [Y/n]
  Please wait, attempting to list all buckets...
  Success. Your access key and secret key worked fine :-)

  Now verifying that encryption works...
  Not configured. Never mind.

  Save settings? [y/N] y
  ```
- Replace `{access_key}` and `{secret_key}` with the values copied from
  earlier. Replace `{hostname}` with the displayed hostname under the
  section labeled 'Public access' in your Object Storage instance. This
  will create an `~/.s3cfg` file (in your user's home directory).
- Finally, run
  ```
  s3cmd -c ~/.s3cfg mb s3://velero
  ```
  to create a bucket called `velero`. Head to the 'Buckets' tab under
  your Object Storage instance to verify it got created.

## Performing the migration

- First, create a config file for Velero containing your bucket's access
  and secret keys like so (`velero.conf`):

  ```config
  [default]
  aws_access_key_id={access_key}
  aws_secret_access_key={secret_key}
  ```
- We will use Velero's AWS S3 provider to interface with UpCloud Object
  Storage. Now, let's install Velero on both clusters A and B. Ensure your
  kubeconfigs are pointing to the correct clusters:

  ```
  export KUBECONFIG=path/to/cluster-A-kubeconfig
  velero install --provider aws \
      --plugins velero/velero-plugin-for-aws:v1.8.0 \
      --bucket velero --secret-file ./velero.conf \
      --backup-location-config region=europe-1,s3ForcePathStyle="true",s3Url=https://{hostname} \
      --use-volume-snapshots=false
  
  export KUBECONFIG=path/to/cluster-B-kubeconfig
  # repeat for cluster B
  ```
- In Cluster A, run:
  ```
  velero backup create backup-1 --include-resources='*' --wait
  velero backup logs backup-1    # to inspect backup logs
  ```
- Once done, in Cluster B, check to see if the backup we created in
  Cluster A is visible:
  ```
  velero backup describe backup-1
  ```
  You may need to wait a bit for it to show up since Velero in Cluster B
  might need to synchronize against the configured object storage
  bucket.

- Restore from the backup using:
  ```
  velero restore create --from-backup backup-1
  velero restore get
  velero restore describe <restore-name-from-get-command>
  ```
