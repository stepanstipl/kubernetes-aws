# kube-labels

Add info about your AWS nodes as labels to Kubernetes cluster.

Expects following env variables:
- **K8S_MASTER** - Kubernetes api endpoint
- **K8S_POD** - Current POD name
- **K8S_ROLE** - Additional info *I use it do differentiate between master and
  different types of worker nodes*

and following certificates to be used when connecting to Kubernetes API:
**/srv/kubernetes/client.pem** - client cert
**/srv/kubernetes/client-key.pem** - client key
**/srv/kubernetes/ca.pem** - CA cert


Will add following labels to the node:
**kubernetes.io/aws-id** - AWS instance ID
**kubernetes.io/aws-type** - AWS instance type
**kubernetes.io/aws-az** - AWS availability zone
**kubernetes.io/aws-region** - AWS region
**kubernetes.io/role** - Whatever you pass in `$K8S_ROLE` env variable


Examle of Kubernetes manifest to run this:
```
apiVersion: v1
kind: Pod
metadata:
  name: kube-labels
  namespace: kube-system
spec:
  hostNework: true
  restartPolicy: OnFailure
  containers:
    - name: kube-labels
      image: quay.io/stepanstipl/kube-labels:latest
      env:
        - name: K8S_POD
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: K8S_ROLE
          value: "worker"
        - name: K8S_MASTER
          value: "kubernetes.my.domain"
      volumeMounts:
        - mountPath: /srv/kubernetes
          name: kubesrv
          readOnly: true
  volumes:
    - name: kubesrv
      hostPath:
        path: /srv/kubernetes
