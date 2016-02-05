# kubelet-conf

This will configure Kubernetes kubelet and components for HA Kubernetes cluster.


- **K8S_CLUSTER_ID** - Name of Kubernetes cluster. Required.
- **K8S_MASTER** - Kubenretes endpoint API
- **K8S_S3_BUCKET** - name of S3 bucket to download certificates and kubelet from


At the moment lot of assumptions about paths and other cluster aspects are made
and hardcoded, uses Podmaster to ensure availability of non-clustered
components.

Following pods will be started:
- **kube-apiserver** - Kubernetes api
- **kube-labels** - Add info about AWS pods as labels
- **podmaster** - ensures that always one instance of following components is stareted
  - **kube-controller-manager** - Kubernetes Controller-Manager
  - **kube-scheduler** - Kubernetes Scheduler

