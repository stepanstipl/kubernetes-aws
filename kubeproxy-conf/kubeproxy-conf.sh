#!/bin/bash
APP='kubelet-conf'

[[ "$DEBUG" == 'true' ]] && set -x

K8S_CLUSTER_ID=${K8S_CLUSTER_ID:?'$K8S_CLUSTER_ID is not set'}
K8S_S3_BUCKET=${K8S_S3_BUCKET:?'$K8S_S3_BUCKET is not set'}

KUBECONFIGS_PATH='/srv/kubernetes/kubeconfigs'
K8S_PATH='/srv/kubernetes'

CERTIFICATES="ca.pem client.pem client-key.pem"

# Copy kubeconfig to final destination
[[ -d "${KUBECONFIGS_PATH}" ]] || mkdir ${KUBECONFIGS_PATH}
echo "${APP}: Creating ${KUBECONFIGS_PATH}/kube-proxy.kubeconfig"
cp '/kube-proxy.kubeconfig' "${KUBECONFIGS_PATH}/kube-proxy.kubeconfig"

# Get certificates
echo "${APP}: Downloading certificates"

for i in ${CERTIFICATES}; do
  echo "${APP}: ${i}"
  [[ -f "${K8S_PATH}/$i" ]] || aws s3api get-object --bucket "${K8S_S3_BUCKET}" --key "certs/${i}" "${K8S_PATH}/${i}"
  [[ -f "${K8S_PATH}/$i" ]] || { echo "${APP}: Error - failed to download ${i} certificate"; exit 1; }
done

# Touch log files, so they exists
touch /var/log/kube-proxy.log
