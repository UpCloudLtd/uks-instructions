# Persistent Volumes

## UpCloud CSI Driver

UpCloud [CSI](https://github.com/container-storage-interface/spec) [Driver](https://github.com/UpCloudLtd/upcloud-csi) provides a basis for using the UpCloud Storage service in Kubernetes, to obtain stateful application deployment with ease.

See https://github.com/UpCloudLtd/upcloud-csi/tree/main/example for various examples for our CSI driver.

## Deploy MariaDB using persistent volume

This example shows how we can make MariaDB survive reboots and pod re-creations by using persistent volume claim (PVC).   

*This example is meant for demonstration purposes only. Do not use as is in production.*

### Define MariaDB root password as environment variable
```sh
$ export MARIADB_PASSWORD=myp4ss!
```

### Create `mariadb` secret to store password securely inside cluster
```sh
$ kubectl create secret generic mariadb --from-literal=password=$MARIADB_PASSWORD
```

### Create persistent volume claim manifest

Save following content to file named `volume.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb-pvc
spec:
  storageClassName: upcloud-block-storage-maxiops
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

Apply manifest
```sh
$ kubectl apply -f volume.yaml
```

This will create 10GB storage device using [UpCloud CSI Driver](https://github.com/UpCloudLtd/upcloud-csi) that can be referenced using its name `mariadb-pvc`.

### Create new deployment manifest 
Deployment makes sure that one MariaDB container is running and that persistent volume claim `mariadb-pvc` is available for containers to use. 
MariaDB saves all of its data under directory defined by `datadir` configuration variable which defaults to `/var/lib/mysql`. We can use `datadir` variables default value and mount persistent volume `mariadb-pvc` into path `/var/lib/mysql`.

Save following content to file named `deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  labels:
    app: mariadb
spec:
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
        - name: mariadb
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
            claimName: mariadb-pvc
```

Apply manifest
```sh
$ kubectl apply -f deployment.yaml
```

### Test data persistence 
We can check deployment status using kubectl
```sh
$ kubectl get deployments/mariadb
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
mariadb   1/1     1            1           22s
```
When "ready" column shows `1/1` we can try to connect MariaDB server
```sh
$ kubectl exec -it deployments/mariadb -- mysql -uroot -p$MARIADB_PASSWORD -e "SELECT CURRENT_TIMESTAMP()"
+---------------------+
| CURRENT_TIMESTAMP() |
+---------------------+
| 2022-10-12 10:48:18 |
+---------------------+
```

For testing purposes create new database `test` with single column `id` and fill it with couple of rows
```sh
$ kubectl exec -it deployments/mariadb -- mysql -uroot -p$MARIADB_PASSWORD -e "CREATE DATABASE test;CREATE TABLE test.number(id int PRIMARY KEY);INSERT INTO test.number (id) VALUES (1), (2), (3), (4)"
```
Now table should have 4 rows
```sh
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

Data persistence can be tested by deleting our deployment and then re-creating it and checking that same rows still exists. Without persistent volume we would loss newly created database rows.  
```sh
$ kubectl delete -f deployment.yaml
$ kubectl get deployments
No resources found in default namespace.
$ kubectl apply -f deployment.yaml
$ kubectl get deployments
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
mariadb   1/1     1            1           38s
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

# What's next
- Read how [snapshots](snapshots.md) can be used to restore `mariadb-pvc` state if something goes wrong
- See how volume size can be [extended](expand.md) by patching PVC object
- See [volume cloning](cloning.md) to find out how `mariadb-pvc` can be used as base volume using clone feature
- Read [migrating persistent volume claim (PVC) from one cluster to another](migration.md)