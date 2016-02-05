#!/bin/bash
APP='kubelet-conf'

[[ "$DEBUG" == 'true' ]] && set -x

K8S_CLUSTER_ID=${K8S_CLUSTER_ID:?'$K8S_CLUSTER_ID is not set'}
K8S_MASTER=${K8S_MASTER:?'$K8S_MASTER is not set'}
K8S_S3_BUCKET=${K8S_S3_BUCKET:?'$K8S_S3_BUCKET is not set'}
K8S_VERSION=${K8S_VERSION:?'$K8S_VERSION is not set'}
KUBE_AWS_VERSION=${KUBE_AWS_VERSION:="latest"}

DOWNLOAD_FILES="kubelet"
DOWNLOAD_CERTS="ca.pem client.pem client-key.pem"
MANIFESTS="kube-labels.yaml"

K8S_PATH='/srv/kubernetes'

MANIFESTS_PATH='/etc/kubernetes/manifests'
PODMASTER_MANIFESTS_PATH='/etc/kubernetes/podmaster'

KUBECONFIGS_PATH='/srv/kubernetes/kubeconfigs'
KUBECONFIGS='kubelet.kubeconfig'

if [[ "$K8S_ROLE" == 'master' ]]; then

  mkdir $PODMASTER_MANIFESTS_PATH
  for i in $(ls '/podmaster-manifests'); do
    echo "${APP}: Creating manifest ${PODMASTER_MANIFESTS_PATH}/${i}"
    sed "s@{{ K8S_CLUSTER_ID }}@${K8S_CLUSTER_ID}@g;s@{{ K8S_MASTER }}@${K8S_MASTER}@g;s@{{ K8S_ROLE }}@${K8S_ROLE}@g;s@{{ KUBE_AWS_VERSION }}@${KUBE_AWS_VERSION}@g;s@{{ K8S_VERSION }}@${K8S_VERSION}@g" "/podmaster-manifests/${i}" > "${PODMASTER_MANIFESTS_PATH}/${i}"
  done

  KUBECONFIGS=$(ls '/kubeconfigs')
  MANIFESTS=$(ls '/manifests');
  DOWNLOAD_CERTS="$DOWNLOAD_CERTS kubernetes.pem kubernetes-key.pem"

  # Touch log files, so they exists
  touch /var/log/kube-apiserver.log
  touch /var/log/kube-scheduler.log
  touch /var/log/kube-controller-manager.log

  # Auth file
  touch /srv/kubernetes/known_tokens.csv

fi

mkdir $MANIFESTS_PATH
for i in $MANIFESTS; do
  echo "${APP}: Creating manifest ${MANIFESTS_PATH}/${i}"
  sed "s@{{ K8S_CLUSTER_ID }}@${K8S_CLUSTER_ID}@g;s@{{ K8S_MASTER }}@${K8S_MASTER}@g;s@{{ K8S_ROLE }}@${K8S_ROLE}@g;s@{{ KUBE_AWS_VERSION }}@${KUBE_AWS_VERSION}@g;s@{{ K8S_VERSION }}@${K8S_VERSION}@    g" "/manifests/${i}" > "${MANIFESTS_PATH}/${i}"
done

mkdir $KUBECONFIGS_PATH
for i in $KUBECONFIGS; do
  echo "${APP}: Creating kubeconfig ${KUBECONFIGS_PATH}/${i}"
  cp "/kubeconfigs/${i}" "${KUBECONFIGS_PATH}/${i}"
done

# Get certificates
echo "${APP}: Downloading certificates"
for i in $DOWNLOAD_CERTS; do
  echo "${APP}: ${i}"
  [[ -f "${K8S_PATH}/$i" ]] || aws s3api get-object --bucket "${K8S_S3_BUCKET}" --key "certs/${i}" "${K8S_PATH}/${i}"
  [[ -f "${K8S_PATH}/$i" ]] || { echo "${APP}: Error - failed to download ${i}"; exit 1; }
done

# Get other files - for now only kubelet
echo "${APP}: Downloading kubelet"
for i in $DOWNLOAD_FILES; do
  echo "${APP}: ${i}"
  [[ -f "${K8S_PATH}/$i" ]] || aws s3api get-object --bucket "${K8S_S3_BUCKET}" --key "${i}" "${K8S_PATH}/${i}"
  [[ -f "${K8S_PATH}/$i" ]] || { echo "${APP}: Error - failed to download ${i}"; exit 1; }
done

# Make sure kubelet is executable
chmod a+x "${K8S_PATH}/kubelet"
