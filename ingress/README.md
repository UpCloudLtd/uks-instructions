# UpCloud Kubernetes Service with Nginx Ingress Controller

UpCloud Kubernetes Service uses UpCloud Managed Load Balancer to provide Service Type: Load Balancer capabilities to Kubernetes. By default, the deployed Load Balancer will use Development Plan and it will be in HTTP Mode. For normal usage this is fine, but in conjuction with an Ingress Controller such as Nginx Ingress, you might need to change the Load Balancer settings. This example shows how you can use annotations to modify the Load Balancer that Nginx deploys during installation to support a production grade plan and switch the mode to TCP. The mode switch is needed if you want to terminate TLS in the Ingress Controller. The UpCloud Managed Load Balancer also supports the TLS to be terminated in the load balancer itself, in which case HTTP mode is sufficient.

## Prerequisites

In addition to a [working UKS Cluster](https://upcloud.com/products/managed-kubernetes), you will need these tools to be installed and configured:

* helm
* [cert-manager](https://cert-manager.io/docs/installation/helm/)
* DNS server

We will be using Helm to deploy the [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/). In order to test the TLS termination in the Ingress, you will need cert-manager deployed and configured to generate the necessary certificates on demand.

In addition, if you want to preserve your client IP addresses, proxy protocol will need to be enabled on the Load Balancer backend as well as on the Ingress Controller.

## Installation

Helm installation method for Nginx Ingress uses a `values.yaml` file to insert the necessary annotations to the Controller while it deploys the load balancer and configures itself. The file below is an example on how to configure and deploy the following things:

* Enable TCP mode on the Load Balancer
* Enable proxy protocol (v1 and v2 supported) on the Load Balancer backends
* Switch Load Balancer plan to production-small
* Change the name of the Load Balancer
* Enable Proxy Protocol support on Nginx Ingress

`values.yaml`:
```
metadata:
  namespace: ingress-nginx
rbac:
  create: true
controller:
  replicaCount: 3
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/upcloud-load-balancer-config: |
        {
          "name": "nginx-ingress-loadbalancer",
          "plan": "production-small",
          "frontends": [
            {
              "name": "https",
              "mode": "tcp",
              "port": 443
            },
            {
              "name": "http",
              "mode": "tcp",
              "port": 80
            }
          ],
          "backends": [
          {
            "name": "https",
            "properties": { "outbound_proxy_protocol": "v2"}
          },
          {
            "name": "http",
            "properties": { "outbound_proxy_protocol": "v2"}
          }
        ]
        }
  config:
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    use-proxy-protocol: "true"
    real-ip-header: "proxy_protocol"
```

Run the helm command to install Nginx Ingress using the latest version available:

```
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace --values values.yaml
```

## Testing

Assuming everything went smooth, let's try the implementation with a test app and an Ingress rule. You should have `cert-manager` up and running to try this.

Deploy a simple test app in the Default namespace. The app has just a stock nginx container listening on port 80:
```
kubectl apply -f demo-app.yaml
```

Next we create the Ingress rule. You need to modify the cert-manager `issuer` and `hostnames` to fit your environment.

```
kubectl apply -f ingress-rule-https.yaml
```

Lastly, modify your DNS server to point the Ingress rule hostname to the UpCloud Load Balancer DNS name that the Ingress Controller is using.

Load Balancer DNS name:
```
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath={.status.loadBalancer.ingress[0].hostname}
```
Load the test app web page using the provided Ingress hostname, and you should see in the Nginx Ingress logs the client IP!

```
kubectl logs deployment/ingress-nginx-controller -n ingress-nginx
```