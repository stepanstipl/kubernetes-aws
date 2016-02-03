#!/bin/bash
APP='flannel-conf'

[[ "$DEBUG" == 'true' ]] && set -x

K8S_CLUSTER_ID=${K8S_CLUSTER_ID:?"${APP}: \$K8S_CLUSTER_ID is not set"}
K8S_S3_BUCKET=${K8S_S3_BUCKET:?"${APP}:\$K8S_S3_BUCKET is not set"}

SERVER_CERTIFICATES="flannel.pem flannel-key.pem"
CERTIFICATES="ca.pem"

ETCD_CLIENT_PORT=${ETCD_CLIENT_PORT:-'2379'}
ETCD_PROTO=${ETCD_PROTO:-'http'}

FLANNEL_PATH=${FLANNEL_CONFIG_PATH:-'/etc/flannel'}
# Client/server
FLANNEL_MODE=${FLANNEL_MODE:-'client'}
FLANNEL_ENV_FILE=${FLANNEL_CONF_FILE:-"${FLANNEL_PATH}/${FLANNEL_MODE}.env"}
FLANNEL_LISTEN=${FLANNEL_LISTEN:="0.0.0.0:8888"}
[[ "$FLANNEL_MODE" == 'client' ]] && FLANNEL_REMOTE=${FLANNEL_REMOTE:?"${APP}: \$FLANNEL_REMOTE needs to be set in client mode"}

FLANNEL_NETWORK=${FLANNEL_NETWORK:-'10.0.0.0/8'}
FLANNEL_SUBNET_LEN=${FLANNEL_SUBNET_LEN:-'24'}
FLANNEL_SUBNET_MIN=${FLANNEL_SUBNET_MIN:-'10.32.0.0'}
FLANNEL_SUBNET_MAX=${FLANNEL_SUBNET_MAX:-'10.255.0.0'}
FLANNEL_BACKEND_TYPE=${FLANNEL_BACKEND_TYPE:-'host-gw'}
FLANNEL_BACKEND_PORT=${FLANNEL_BACKEND_PORT:-''}
FLANNEL_ETCD_PREFIX=${FLANNEL_ETCD_PREFIX:-'/coreos.com/network'}
FLANNEL_KEY="${FLANNEL_ETCD_PREFIX}/config"
FLANNEL_SUBNET_FILE=${FLANNEL_SUBNET_FILE:-'/etc/flannel/subnet.env'}

IPTABLES_CMD='/sbin/iptables'
CURL_OPTS=${CURL_OPTS:-'-s -f --connect-timeout 30'}
CURL="/usr/bin/curl ${CURL_OPTS}"

[[ "$FLANNEL_MODE" == 'server' ]] && CERTIFICATES=$SERVER_CERTIFICATES

# Get certificates
echo "${APP}: Downloading certificates"
for i in $CERTIFICATES; do
  echo "${APP}: ${i}"
  [[ -f "${FLANNEL_PATH}/$i" ]] || (/usr/bin/aws s3api get-object --bucket "${K8S_S3_BUCKET}" --key "certs/${i}" "${FLANNEL_PATH}/${i}")
  [[ -f "${FLANNEL_PATH}/$i" ]] || { echo "${APP}: Error - failed to download ${i} certificate"; exit 1; }
done

# Get AWS AZ
AWS_AZ=$($CURL 'http://169.254.169.254/latest/meta-data/placement/availability-zone')
AWS_REGION=${AWS_AZ%%[a-z]}
AWS_REGION=${AWS_REGION:?"${APP}: Error - failed to get aws ec2 region"}
echo "${APP}: Found aws region - ${AWS_REGION}"

# Get Instance ID
AWS_INSTANCE_ID=$($CURL 'http://169.254.169.254/latest/meta-data/instance-id')
AWS_INSTANCE_ID=${AWS_INSTANCE_ID:?"${APP}: Error - failed to get aws instance-id"}
echo "${APP}: Found aws instance-id - ${AWS_INSTANCE_ID}"

AWS="/usr/bin/aws --region ${AWS_REGION} --output text"

# If we're running in server mode
if [[ "$FLANNEL_MODE" == server ]]; then

    # Get Autoscaling group
  AWS_ASG=$($AWS autoscaling describe-auto-scaling-instances --instance-ids $AWS_INSTANCE_ID --query 'AutoScalingInstances[].AutoScalingGroupName' | xargs)
  AWS_ASG=${AWS_ASG:?"${APP}: Error - failed to get aws autoscaling group name"}
  echo "${APP}: Found aws autoscaling group name - ${AWS_ASG}"

  # Get autoscaling group instance ids
  AWS_INSTANCE_IDS=$($AWS autoscaling describe-auto-scaling-groups --auto-scaling-group-names $AWS_ASG --query 'AutoScalingGroups[].Instances[]|[?LifecycleState==`InService`].InstanceId' | xargs)
  AWS_INSTANCE_IDS=${AWS_INSTANCE_IDS:?"${APP}: Error - failed to get aws ec2 instance ids"}
  echo "${APP}: Found aws instance ids - ${AWS_INSTANCE_IDS}"

  # Get ip addresses
  # And get IDs again, becuase ordering
  tmp=$($AWS ec2 describe-instances --instance-ids $AWS_INSTANCE_IDS --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress]')
  AWS_INSTANCE_IDS=$(echo "$tmp" | cut -f1 | xargs)
  AWS_IPS=$(echo "$tmp" | cut -f2 | xargs)
  AWS_IPS=${AWS_IPS:?"${APP}: Error - unable to get cluster IPs from AWS"}
  echo "${APP}: Found cluster IPs - ${AWS_IPS}"

  # Construct ETCDCTL url
  for current_ip in $AWS_IPS; do
    [[ -z "${ETCDCTL_ENDPOINT}" ]] || ETCDCTL_ENDPOINT="${ETCDCTL_ENDPOINT},"
    ETCDCTL_ENDPOINT="${ETCDCTL_ENDPOINT}${ETCD_PROTO}://${current_ip}:${ETCD_CLIENT_PORT}"
  done
  ETCDCTL_ENDPOINT=${ETCDCTL_ENDPOINT:?"${APP}: Error - failed to construct etcdctl endpoint addresses"}
  echo "${APP}: Found etcd endpoints - ${ETCDCTL_ENDPOINT}"

  # Wait for etcd cluster
  echo "${APP}: Waiting for etcd cluster"
  attempt=1
  while true; do
    echo "${APP}: Attempt ${attempt}"
    if /etcdctl cluster-health; then
      echo "${APP}: Found healthy etcd"
      break
    fi
    attempt=$(($attempt+1))
    sleep 2
  done

  # Get or try to create new flannel config in etcd
  if FLANNEL_VALUE=$(/etcdctl get "${FLANNEL_KEY}"); then
    echo "${APP}: Found flannel config - ${FLANNEL_VALUE}"
  else 
    echo "${APP}: Unable to find flannel config key, creating one"

    # Construct Flannel backend part
    if [[ -n "${FLANNEL_BACKEND_PORT}" ]]; then
      FLANNEL_BACKEND="\"Backend\": {\"Type\": \"${FLANNEL_BACKEND_TYPE}\", \"Port\": ${FLANNEL_BACKEND_PORT}"
    else
      FLANNEL_BACKEND="\"Backend\": {\"Type\": \"${FLANNEL_BACKEND_TYPE}\"}"
    fi

    # Construct Flannel value and save it to etcd
    FLANNEL_VALUE="{ \"Network\": \"${FLANNEL_NETWORK}\", \"SubnetLen\": ${FLANNEL_SUBNET_LEN}, \"SubnetMin\": \"${FLANNEL_SUBNET_MIN}\", \"SubnetMax\": \"${FLANNEL_SUBNET_MAX}\", ${FLANNEL_BACKEND} }"
    if /etcdctl set "${FLANNEL_KEY}" "${FLANNEL_VALUE}"; then
      echo "${APP}: Set flannel config - ${FLANNEL_VALUE}"
    else
      echo "${APP}: Error - failed to set flannel config in etcd"
      exit 1
    fi
  fi

  cat << EOF > $FLANNEL_ENV_FILE
FLANNELD_ETCD_ENDPOINTS=${ETCDCTL_ENDPOINT}
FLANNELD_ETCD_PREFIX=${FLANNEL_ETCD_PREFIX}
FLANNELD_LISTEN=${FLANNEL_LISTEN}
FLANNELD_REMOTE_CERTFILE=${FLANNEL_PATH}/flannel.pem
FLANNELD_REMOTE_KEYFILE=${FLANNEL_PATH}/flannel-key.pem
EOF

else
  # Disable source-dest check for the instance
  echo "${APP}: Disabling source-destination check for the instance"
  $AWS ec2 modify-instance-attribute --instance-id "${AWS_INSTANCE_ID}" --source-dest-check "{\"Value\": false}"
  [[ $? -eq 0 ]] || { echo "${APP}: Error - failed to disable source-destination check for the instance"; exit 1; }

  # Add iptables nat to be able to talk to outside the overlay network world
  echo "${APP}: Configuring iptables"
  $IPTABLES_CMD -w -t nat -A POSTROUTING -o eth0 -j MASQUERADE \! -d "${FLANNEL_NETWORK}"
  [[ $? -eq 0 ]] || { echo "${APP}: Error - failed to configure iptables"; exit 1; }

  cat << EOF > $FLANNEL_ENV_FILE
FLANNELD_REMOTE=${FLANNEL_REMOTE}
FLANNELD_REMOTE_CAFILE=${FLANNEL_PATH}/ca.pem
FLANNELD_SUBNET_FILE=${FLANNEL_SUBNET_FILE}
EOF

fi

echo "${APP}: Done. Written env config file to ${FLANNEL_ENV_FILE}"
cat $FLANNEL_ENV_FILE
