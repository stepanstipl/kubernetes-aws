# docker-conf

This is intended for configuring user docker on RancherOS for Kubernetes on AWS.

This container will source docker args from flannel expected in
/etc/flannel-conf and run ros config to set additional params for user docker.
