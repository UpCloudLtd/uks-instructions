# Customizing Load Balancer's network configuration

*In the following examples, `$UKS_NETWORK_ID` refers to SDN network UUID that is used as worker node network in the cluster.*

Load Balancer can be attached to different networks by defining custom list of [network](https://developers.upcloud.com/1.3/17-managed-loadbalancer/#networks) objects in load balancer's configuration. Once network is defined, frontend can be configured to listen configured network(s).  

Network configuration constraints:
- list __must__ include cluster's private SDN network
- cloud controller manager account needs to have permission to use all attached private networks

By default, load balancer is created with two network interfaces. Interface connected to internet is `public-IPv4` and interface connected to private SDN is `private-IPv4`. Each frontend can be configured to listen multiple interfaces.  

For example, to disable public interface completely, network configuration can be overwritten by only providing private network configuration:
```json
{
  "networks": [
      {
          "name": "private-IPv4",
          "type": "private",
          "family": "IPv4",
          "uuid": "$UKS_NETWORK_ID"
      }
  ],
  "frontends": [
      {
          "networks": [
              {
                  "name": "private-IPv4"
              }
          ]
      }
  ]
}      
```


## Examples
Create example deployment:
```shell
$ kubectl create deployment --image=ghcr.io/upcloudltd/hello hello-uks-networks
```

### Expose services only to private SDN
```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/upcloud-load-balancer-config: |
      {
          "networks": [
              {
                  "name": "private-IPv4",
                  "type": "private",
                  "family": "IPv4",
                  "uuid": "$UKS_NETWORK_ID"
              }
          ],
          "frontends": [
              {
                  "networks": [
                      {
                          "name": "private-IPv4"
                      }
                  ]
              }
          ]
      }      
  labels:
    app: hello-uks-networks
  name: hello-uks-networks
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: hello-uks-networks
  type: LoadBalancer
```

### Expose services to internet and to private SDN
This example: 
- exposes HTTP service to private network 
- exposes HTTP service to internet using secured HTTPS (443) port and only allow connections from `$IP_ADDRESS` address
- use custom backend configuration to share single backend with frontends and define custom backend properties

*Note that source IP address filtering shouldn't be used as only security measure when dealing with sensitive data*

```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    service.beta.kubernetes.io/upcloud-load-balancer-config: |
      {
          "frontends": [
              {
                  "name": "http",
                  "mode": "http",
                  "port": 80,
                  "networks": [
                      {
                          "name": "private-IPv4"
                      }
                  ]
              },
              {
                  "name": "https",
                  "mode": "http",
                  "port": 443,
                  "networks": [
                      {
                          "name": "public-IPv4"
                      }
                  ],
                  "default_backend": "http",
                  "rules": [
                      {
                          "name": "whitelist-ip",
                          "matchers": [
                              {
                                  "type": "src_ip",
                                  "inverse": true,
                                  "match_src_ip": {
                                      "value": "$IP_ADDRESS"
                                  }
                              }
                          ],
                          "actions": [
                              {
                                  "type": "tcp_reject",
                                  "action_tcp_reject": {}
                              }
                          ]
                      }
                  ]
              }
          ],
          "backends": [
              {
                  "name": "http",
                  "properties": {
                      "timeout_server": 30
                  }
              }
          ]
      }
  labels:
    app: hello-uks-networks
  name: hello-uks-networks
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: hello-uks-networks
```