# CSI volume cloning

Volume cloning is the process of using an existing persistent volume claim (PVC) as a data source when creating a new one.  
Some of the use-cases for cloning might be:
- use as backup before upgrading application that uses volume by deploying new version of application using cloned version of the original volume
- pre-populate volume with some data and use that data as base state by deploying new version of application using cloned version of the original volume


Read more about [volume cloning](https://kubernetes.io/docs/concepts/storage/volume-pvc-datasource/#introduction) from Kubernetes documentation. 

Cloning persistent volume requires following steps:
- shut down application that uses persistent volume that is going to be cloned
- create new persistent volume claim and define existing persistent volume claim as data source
- when cloning is done, start application(s)


## Prerequisites
- `kubectl` installed
- cluster config (kubeconfig)


This document uses `mariadb` deployment from [README](README.md) as an example. To test this out, follow the steps from `README` and fill the database with test data (numbers).   
Goal here is to use pre-populated (numbers from 1 to 4) data from `mariadb-pvc` as base numbers for new MariaDB instance and add some more numbers on top of those.

## Shut down application
Shut down the application that uses PVC that is going to be cloned. This will detach the storage device from the worker node and allow the back-end to clone the storage. 

```shell
$ kubectl -n default scale deployment mariadb --replicas=0
deployment.apps/mariadb scaled
```

## Create persistent volume
Save following content to file named `clone.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc-clone
spec:
  storageClassName: upcloud-block-storage-maxiops
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  dataSource:
    kind: PersistentVolumeClaim
    name: mariadb-pvc
```
*PVC `mariadb-pvc-clone` uses `mariadb-pvc` as a data-source by cloning the underlying storage device.*

Apply manifest
```shell
$ kubectl apply -f clone.yaml
```

Wait until cloned PVC status changes from `pending` to `bound` 
```shell
$ kubectl get pvc mariadb-pvc-clone
NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                    AGE
mariadb-pvc-clone   Bound    pvc-a328c082-6cfb-4607-9f0c-fb0d26a17f14   10Gi       RWO            upcloud-block-storage-maxiops   5m8s
```

# Start application
Save following content to file named `deployment-clone.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-clone
  labels:
    app: mariadb-clone
spec:
  selector:
    matchLabels:
      app: mariadb-clone
  template:
    metadata:
      labels:
        app: mariadb-clone
    spec:
      containers:
        - name: mariadb-clone
          image: mariadb:10.9
          env:
            - name: MARIADB_ALLOW_EMPTY_ROOT_PASSWORD
              value: "0"
            - name: MARIADB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mariadb
                  key: password
          ports:
            - containerPort: 3306
              name: mariadb
          volumeMounts:
            - name: mariadb-datadir
              mountPath: /var/lib/mysql
      volumes:
        - name: mariadb-datadir
          persistentVolumeClaim:
            claimName: mariadb-pvc-clone
```

Start new MariaDB instance using cloned storage as base data by applying the manifest
```shell
$ kubectl apply -f deployment-clone.yaml
deployment.apps/mariadb-clone created
```

# Testing MariaDB cloned numbers
Check that `mariadb-clone` deployment has cloned base numbers.  
Table should have 4 cloned rows
```shell
$ kubectl exec -it deployments/mariadb-clone -- mysql -uroot -p$MARIADB_PASSWORD -e "SELECT id FROM test.number";
+----+
| id |
+----+
|  1 |
|  2 |
|  3 |
|  4 |
+----+
```

Add some more numbers and check that numbers are added on top of cloned numbers
```shell
$ kubectl exec -it deployments/mariadb-clone -- mysql -uroot -p$MARIADB_PASSWORD -e "INSERT INTO test.number (id) VALUES (5), (6), (7), (8), (9), (10)"
```
```shell
$ kubectl exec -it deployments/mariadb-clone -- mysql -uroot -p$MARIADB_PASSWORD -e "SELECT id FROM test.number";
+----+
| id |
+----+
|  1 |
|  2 |
|  3 |
|  4 |
|  5 |
|  6 |
|  7 |
|  8 |
|  9 |
| 10 |
+----+
```

Start initial `mariadb` deployment just to check that base numbers are still there
```shell
$ kubectl -n default scale deployment mariadb --replicas=1
deployment.apps/mariadb scaled
```
Table should still have 4 rows
```shell
$ kubectl exec -it deployments/mariadb -- mysql -uroot -p$MARIADB_PASSWORD -e "SELECT id FROM test.number";
+----+
| id |
+----+
|  1 |
|  2 |
|  3 |
|  4 |
+----+
```