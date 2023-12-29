# Migrating workloads from one UKS cluster to another using Velero

This is an example of how to migrate workloads from an existing
[UKS](https://upcloud.com/products/managed-kubernetes)
cluster to a new UKS cluster.

## Prerequisites

- Your existing UKS cluster
- A new, fresh UKS cluster (the one you want to migrate to)
- [Velero
  CLI](https://velero.io/docs/main/basic-install/#install-the-cli)

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
  page and hit 'Create Object Storage'.
