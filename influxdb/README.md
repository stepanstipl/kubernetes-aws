# influxdb

Busybox based minimal image for Influxdb, with dicovery mechanism for
Kubernetes.

When starting we'll try to connect to Kubernetes service (determined by env var
`$K8S_SVC`, defaults to `monitoring-influxdb`) and get nodes that will be used in
-join parameter for lustering.

First member of a cluster should be started with. env variable `$JOIN` se to
`false`, to skip the discovery phase and bootstrap new cluster.

Variables:
- **K8S_SVC** - Name of Kubernetes service to get the nodes from, defaults to
  `monitoring-influxdb`.
- **POD_IP** - Should conaint IP address to bind to.
- **JOIN** - Whether to join existing or bootstrap new cluster, defaults to
  `true`. 


Example of Kubernetes rc & svc definition:
```
apiVersion: v1
kind: ReplicationController
metadata:
  name: monitoring-influxdb-v2
  namespace: kube-system
  labels:
    k8s-app: monitoring-influxdb
    version: v2
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: monitoring-influxdb
    version: v2
  template:
    metadata:
      labels:
        k8s-app: monitoring-influxdb
        version: v2
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
        - image: quay.io/stepanstipl/influxdb:latest
          name: influxdb
          resources:
            limits:
              cpu: 100m
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 200Mi
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: JOIN
              value: "true" 
          ports:
            - containerPort: 8083
              hostPort: 8083
            - containerPort: 8086
              hostPort: 8086
            - containerPort: 8088
              hostPort: 8088
            - containerPort: 8091
              hostPort: 8091
```
```
apiVersion: v1
kind: Service
metadata:
  name: monitoring-influxdb
  namespace: kube-system
  labels:
    k8s-app: monitoring-influxdb
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "InfluxDB"
spec:
  ports:
  - port: 8083
    protocol: TCP
    targetPort: 8083
    name: http
  - port: 8086
    protocol: TCP
    targetPort: 8086
    name: api
  selector:
    k8s-app: monitoring-influxdb
```
