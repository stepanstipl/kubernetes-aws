#!/bin/bash
APP='kube-labels'

[[ "$DEBUG" == 'true' ]] && set -x

K8S_MASTER=${K8S_MASTER:?'$K8S_MASTER is not set'}
K8S_POD=${K8S_POD:?'$K8S_POD is not set'}
K8S_ROLE=${K8S_ROLE:?'$K8S_ROLE is not set'}

CURL_OPTS=${CURL_OPTS:-'-s -f --connect-timeout 30'}
CURL="/usr/bin/curl ${CURL_OPTS}"

echo "${APP}: Pod ${K8S_POD}"

# Get AWS AZ
AWS_AZ=$($CURL 'http://169.254.169.254/latest/meta-data/placement/availability-zone')
AWS_REGION=${AWS_AZ%%[a-z]}
AWS_REGION=${AWS_REGION:?"${APP}: Error - failed to get aws ec2 region"}
echo "${APP}: Found aws region - ${AWS_REGION}"

# Get Instance ID
AWS_INSTANCE_ID=$($CURL 'http://169.254.169.254/latest/meta-data/instance-id')
AWS_INSTANCE_ID=${AWS_INSTANCE_ID:?"${APP}: Error - failed to get aws instance-id"}
echo "${APP}: Found aws instance-id - ${AWS_INSTANCE_ID}"

# Get Instance Type
AWS_INSTANCE_TYPE=$($CURL 'http://169.254.169.254/latest/meta-data/instance-type')
AWS_INSTANCE_TYPE=${AWS_INSTANCE_TYPE:?"${APP}: Error - failed to get aws instance-type"}
echo "${APP}: Found aws instance-id - ${AWS_INSTANCE_TYPE}"

# Wait for API server and get Node name
attempt=1
while [[ -z "$NODE" ]] || [[ "$NODE" == "null" ]]; do
  echo "${APP}: Retrieving host name, attempt ${attempt}"
  sleep 2
  NODE=$($CURL --cert /srv/kubernetes/client.pem --key /srv/kubernetes/client-key.pem --cacert /srv/kubernetes/ca.pem  \
         ${K8S_MASTER}/api/v1/namespaces/kube-system/pods/${K8S_POD} | jq -r '.spec.nodeName'
       )
  attempt=$(($attempt+1))
done

# Create json
NL=$'\n'
LABELS=""

for i in $@; do
  PA=$(echo $i | cut -f1 -d'=')
  PB=$(echo $i | cut -f2 -d'=')
  LABELS+="      \"${PA}\": \"${PB}\",${NL}"
done

echo "${APP}: Updating node labels"
$CURL --cert /srv/kubernetes/client.pem --key /srv/kubernetes/client-key.pem --cacert /srv/kubernetes/ca.pem  \
     --request PATCH -H "Content-Type: application/strategic-merge-patch+json" \
     -d @- "${K8S_MASTER}/api/v1/nodes/${NODE}" <<EOF
{
  "metadata": {
    "labels": {
      "kubernetes.io/aws-id":     "${AWS_INSTANCE_ID}",
      "kubernetes.io/aws-type":   "${AWS_INSTANCE_TYPE}",
      "kubernetes.io/aws-az":     "${AWS_AZ}",
      "kubernetes.io/aws-region": "${AWS_REGION}",
      "kubernetes.io/role":       "${K8S_ROLE}"
    }
  }
}
EOF
[[ "$?" -eq 0 ]] || { echo "${APP}: Error - failed to update node labels"; exit 1; }
