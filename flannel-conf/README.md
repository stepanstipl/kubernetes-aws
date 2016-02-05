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

- **K8S_CLUSTER_ID** - Name of Kubernetes cluster. Required.
- **FLANNEL_MODE** - Run server or client
- **FLANNEL_REMOTE** - Endpoint for client. Required in client mode.
- **FLANNEL_CONFIG** _ location of Flannel config file, defaults to
  `/etc/flannel`.
- **K8S_S3_BUCKET** - name of S3 bucket to download certificates from


Example of how to use this as systemd service:
```
[Unit]
Description=Flannel-conf one-time service for flannel server
Requires=early-docker.service etcd2.service
After=early-docker.service etcd2.service

[Service]
Type=oneshot
RemainAfterExit=yes
Environment="DOCKER_HOST=unix:///var/run/early-docker.sock"
ExecStart=/usr/bin/docker run --net host --rm \
                              -e "K8S_CLUSTER_ID={{ K8S_CLUSTER_ID }}" \
                              -e "K8S_S3_BUCKET={{ K8S_S3_BUCKET }}" \
                              -e "FLANNEL_MODE=server" \
                              -v "/etc/flannel:/etc/flannel" \
                              quay.io/stepanstipl/flannel-conf:{{ K8S_KUBE_AWS_VERSION }}

[Install]
WantedBy=multi-user.target
```
