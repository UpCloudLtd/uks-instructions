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
  $ s3cmd --configure

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
  $ s3cmd -c ~/.s3cfg mb s3://velero
  ```
  to create a bucket called `velero`. Head to the 'Buckets' tab under
  your Object Storage instance to verify it got created.
