# etcd-conf

Configures etcd on AWS using info from autoscaling groups.

By default will write configuration to `/etc/etcd/etcd.env` and expects all the
etcd data to live in `/srv/etcd`.

Simple example how to use this as systemd servcice:
```
[Unit]
Description=Etcd-conf one-time service
Requires=early-docker.service
After=early-docker.service
Before=etcd2.service

[Service]
Type=oneshot
RemainAfterExit=yes
Environment="DOCKER_HOST=unix:///var/run/early-docker.sock"
ExecStart=/usr/bin/docker run --net host --rm \
                          -v "/etc/etcd:/etc/etcd" \
                          quay.io/stepanstipl/etcd-conf:latest
ExecStartPost=/bin/bash -c '[[ -d /srv/etcd ]] || (/bin/mkdir /srv/etcd && /bin/chown etcd:etcd /srv/etcd)'
```
