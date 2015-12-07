# flannel-conf

This is intended for configuring flannel on RancherOS for Kubernetes on AWS.

The container will:
- auto-detect AWS autoscaling group in which the Kubernetes master nodes are
  running
- based on that generate etcd endpoints config
- verify that there is valid config in etcd
- if not, then create one if we're allowed
- generate flannel config file

Variables:
Most of the things can be parametrised, check flannel-conf script. Basic ones
are:

- **K8S_CLUSTER_NAME** - Name of Kubernetes cluster. Required.
- **K8S_MASTER_ASG_NAME** - name of Kubernetes ASG group, defaults to
  `kubernetes-master`.
- **FLANNEL_CONFIG** _ location of Flannel config file, defaults to
  `/etc/flannel`.


