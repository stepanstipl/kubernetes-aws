#!/bin/bash
APP='etcd-conf'

[[ "$DEBUG" == 'true' ]] && set -x

ETCD_ENV_FILE=${ETCD_ENV_FILE:-'/etc/etcd/etcd.env'}
ETCD_DATA_DIR='/srv/etcd'

ETCD_CLIENT_PORT=${ETCD_CLIENT_PORT:-'2379'}
ETCD_PEER_PORT=${ETCD_PEER_PORT:-'2380'}
ETCD_PROTO=${ETCD_PROTO:-'http'}
ETCD_LISTEN_CLIENT_IP=${ETCD_LISTEN_CLIENT_LISTEN:-'0.0.0.0'}
ETCD_LISTEN_CLIENT_URLS=${ETCD_LISTEN_CLIENT_URLS:-"${ETCD_PROTO}://${ETCD_LISTEN_CLIENT_IP}:${ETCD_CLIENT_PORT}"}
ETCD_LISTEN_PEER_IP=${ETCD_LISTEN_PEER_IP:-'0.0.0.0'}
ETCD_LISTEN_PEER_URLS=${ETCD_LISTEN_PEER_URLS:-"${ETCD_PROTO}://${ETCD_LISTEN_PEER_IP}:${ETCD_PEER_PORT}"}

CURL_OPTS=${CURL_OPTS:-'-s -f --connect-timeout 30'}
CURL="/usr/bin/curl ${CURL_OPTS}"

# Get AWS AZ
AWS_AZ=$($CURL 'http://169.254.169.254/latest/meta-data/placement/availability-zone')
AWS_REGION=${AWS_AZ%%[a-z]}
AWS_REGION=${AWS_REGION:?"${APP}: Error - failed to get aws ec2 region"}
echo "${APP}: Found aws region - ${AWS_REGION}"

# Get IP from AWS
AWS_IP=$($CURL 'http://169.254.169.254/latest/meta-data/local-ipv4')
AWS_IP=${AWS_IP:?"${APP}: Error - unable to get local IP from AWS"}
echo "${APP}: Found aws local IP - ${AWS_IP}"

# Get Instance ID
AWS_INSTANCE_ID=$($CURL 'http://169.254.169.254/latest/meta-data/instance-id')
AWS_INSTANCE_ID=${AWS_INSTANCE_ID:?"${APP}: Error - failed to get aws instance-id"}
echo "${APP}: Found aws instance-id - ${AWS_INSTANCE_ID}"


AWS="/usr/bin/aws --region ${AWS_REGION} --output text"

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

# Try to connect to existing cluster
for ip in $AWS_IPS; do
  # If it's out IP, skip it
  [[ "$IP" == "$AWS_IP" ]] && continue

  ETCD_MEMBERS=$($CURL "${ETCD_PROTO}://${IP}:${ETCD_CLIENT_PORT}/v2/members")

  if [[ $? == 0 && $etcd_members ]]; then
    ETCD_GOOD_MEMBER_URL="${ETCD_PROTO}://${ip}:${ETCD_CLIENT_PORT}"
    ETCD_EXISTING_PEER_URLS=$(echo "${ETCD_MEMBERS}" | jq --raw-output '.[][].peerURLs[0]' | xargs)
    ETCD_EXISTING_PEER_NAMES=$(echo "${ETCD_MEMBERS}" | jq --raw-output '.[][].name' | xargs)
    break
  fi
done

echo "${APP}: Exisiting peers - ${ETCD_EXISTING_PEER_URLS}"
echo "${APP}: Exisiting names - ${ETCD_EXISTING_PEER_NAMES}"

# If I've found peers, but I'm not a member -> join exising
if [[ -n "$ETCD_EXISTING_PEER_URLS" && "$ETCD_EXISTING_PEER_NAMES" != *"$AWS_INSTANCE_ID"* ]]; then
  echo "${APP}: Joining existing cluster"

  # Take care of missing peers
  IPS_REGEX=$(echo "${AWS_IPS}" | tr '[:blank:]' '|') 
  MISSING_PEERS=$(echo "$ETCD_MEMBERS" | jq --raw-output ".[] | map(select(.peerURLs[] | test(\"${IPS_REGEX}\") | not )) | .[].id" | xargs)
  
  echo "${APP}: Missing peers: ${MISSING_PEERS}"

  for i in $MISSING_PEERS; do
    echo "${APP}: Removing bad peer ${i}"
    status=$($CURL -w %{http_code} "${ETCD_GOOD_MEMBER_URL}/v2/members/${i}" -XDELETE)
    [[ $status == '204' ]] || { echo "${APP}: ERROR - failed to remove bad peer: $i"; exit 1; }
  done

  # Get current good peers after cleanup
  ETCD_INITIAL_CLUSTER=$(echo "${ETCD_GOOD_MEMBER_URL}/v2/members" | jq --raw-output '.[] | map(.name + "=" + .peerURLs[0]) | .[]' | xargs | tr '[:blank:]' ',')
  ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER},${AWS_INSTANCE_ID}=${ETCD_PROTO}://${AWS_IP}:${ETCD_PEER_PORT}"

  # Joining existing cluster 
  echo "${APP}: Adding instance to existing cluster"
  status=$($CURL -w %{http_code} -o /dev/null -XPOST "$ETCD_GOOD_MEMBER_URL/v2/members" -H "Content-Type: application/json" -d "{\"peerURLs\": [\"${ETCD_PROTO}://${AWS_IP}:${ETCD_PEER_PORT}\"], \"name\": \"${AWS_INSTANCE_ID}\"}")
  [[ $status == '204' || $status == '409' ]] || { echo "${APP}: ERROR - unable to add instance to exisitng cluster"; exit 1; }

  ETCD_INITIAL_CLUSTER_STATE='existing'

# looks like a new cluster 
else
    echo "${APP}: Creating new cluster"

    ETCD_INITIAL_CLUSTER_STATE='new'

    for id in $AWS_INSTANCE_IDS; do
      current_ip=$(echo $AWS_IPS | cut -f1 -d' ')
      [[ -z "${ETCD_INITIAL_CLUSTER}" ]] || ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER},"
      ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER}${id}=${ETCD_PROTO}://${current_ip}:${ETCD_PEER_PORT}"
      AWS_INSTANCE_IDS=$(echo $AWS_INSTANCE_IDS | cut -f'2-' -d' ')
      AWS_IPS=$(echo $AWS_IPS | cut -f'2-' -d' ')
    done
fi

# Set rancheros env
cat << EOF > $ETCD_ENV_FILE
ETCD_LISTEN_PEER_URLS=${ETCD_LISTEN_PEER_URLS}
ETCD_LISTEN_CLIENT_URLS=${ETCD_LISTEN_CLIENT_URLS}
ETCD_INITIAL_ADVERTISE_PEER_URLS=${ETCD_PROTO}://${AWS_IP}:${ETCD_PEER_PORT}
ETCD_ADVERTISE_CLIENT_URLS=${ETCD_PROTO}://${AWS_IP}:${ETCD_CLIENT_PORT}
ETCD_INITIAL_CLUSTER_STATE=${ETCD_INITIAL_CLUSTER_STATE}
ETCD_NAME=${AWS_INSTANCE_ID}
ETCD_INITIAL_CLUSTER=${ETCD_INITIAL_CLUSTER}
ETCD_DATA_DIR=${ETCD_DATA_DIR}
EOF

echo "${APP}: Done. Written env config file to ${ETCD_ENV_FILE}"
cat $ETCD_ENV_FILE
