#!/bin/bash

help() {
  echo " Lease a Chameleon node"
  echo " USAGE: create_instance.sh [OPTIONS]"
  echo "    [OPTIONS]"
  echo "    -help         Print help"
  echo "    -days         Number of days to lease"
}

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -help)
    help
    exit 0
    ;;
    -days)
    re='^[0-9]+$'
    if ! [[ $2 =~ $re ]]; then
      echo "-days $2 option must be a number"
      exit 1
    fi
    LEASE_DAYS="$2"
    shift
    shift
    ;;
    *)
    shift
    ;;
  esac
done


if [ -z ${IMAGE+x} ]; then
  export IMAGE='CC-Ubuntu18.04-CUDA10'
fi

echo "Using image ${IMAGE}..."


#export IMAGE='CC-Ubuntu18.04'
export platform_type="x86_64"

# list of possible resource properties to ask for
# '["=", "$architecture.platform_type", "x86_64"]'



if [[ -z "${OS_AUTH_URL}" ]] ; then
    echo "Enviornment variable OS_AUTH_URL not defined. Please mount your \"OpenStack RC File v3\" file to /openrc.sh"
fi

if [[ -z "${OS_USERNAME}" ]] ; then
    echo "Enviornment variable OS_USERNAME not defined. Please mount your \"OpenStack RC File v3\" file to /openrc.sh"
fi


# detect the key for this lease
if [ -z ${KEY_NAME+x} ]; then
  export KEY_NAME_COUNT=$( openstack keypair list -f json | jq -r .[].Name | wc -l )

  if [ ${KEY_NAME_COUNT} -eq 0 ] ; then
    echo "no key found, please register your key on Chameleon first"
    exit 1
  fi

  if [ ${KEY_NAME_COUNT} -gt 1 ] ; then
    export KEY_NAMES=$( openstack keypair list -f json | jq -r .[].Name )
    echo ${KEY_NAMES}
    echo "more than one key found, please specify key name via enviornment variable KEY_NAME=..."
    exit 1
  fi

  export KEY_NAME=$( openstack keypair list -f json | jq -r .[].Name )  #works with key only
  echo "KEY_NAME: ${KEY_NAME}"
fi


# try to detect available lease name

LEASE_LIST=$(blazar lease-list -f json | jq -r '.[].name')

LEASE_NAME=""


for i in {1..100} ; do
  TRY_NAME="${OS_USERNAME}_${i}"
  #echo "trying ${TRY_NAME}"
  for LEASE_X in ${LEASE_LIST} ; do
    if [[ ${LEASE_X}_ == ${TRY_NAME}_ ]] ; then
        #echo "${TRY_NAME} already used (${LEASE_X})"
        continue 2
    fi
  done
  #echo "${TRY_NAME} seems available"
  LEASE_NAME=${TRY_NAME}
  break
done


echo "LEASE_NAME: ${LEASE_NAME}"

# set start and end date of the lease if LEASE_DAYS is set
if [ -z ${LEASE_DAYS+x} ]; then
  echo "leasing ${LEASE_NAME} for a day. To lease longer see -help"
  export START_DATE=$(date -u +"%Y-%m-%d %H:%M")
  export END_DATE=$(date -u +"%Y-%m-%d %H:%M" -d "$(date)+1 days")
else
  export START_DATE=$(date -u +"%Y-%m-%d %H:%M")
  export END_DATE=$(date -u +"%Y-%m-%d %H:%M" -d "$(date)+${LEASE_DAYS} days")
fi

set -e


#create lease
set -x
blazar lease-create --physical-reservation min=1,max=1,resource_properties='["=", "$gpu.gpu", "True"]',before_end='' \
  --reservation resource_type=virtual:floatingip,network_id=6189521e-06a0-4c43-b163-16cc11ce675b \
  --start-date "${START_DATE}" \
  --end-date "${END_DATE}" \
  ${LEASE_NAME}
set +x


sleep 1

while [ $(blazar lease-show ${LEASE_NAME} -f json | jq -r '.status') != "ACTIVE" ] ; do
  echo "waiting for lease ${LEASE_NAME} to be in state \"ACTIVE\"..."
  sleep 2
done
echo "Lease ${LEASE_NAME} is active."

export INSTANCE_NAME=${LEASE_NAME}


### collect information

export RESERVATION_ID=$(blazar lease-show ${LEASE_NAME} -f json | jq -rc '.reservations' | jq -c '.'  | grep physical:host | jq -r .id)
echo "RESERVATION_ID: ${RESERVATION_ID}"


# get network
export NETWORK_SHAREDNET1=$(openstack network list -f json | jq -r  '.[] | select(.Name=="sharednet1" ) | .ID')
echo "NETWORK_SHAREDNET1: ${NETWORK_SHAREDNET1}"



set -x
openstack server create \
--image ${IMAGE} \
--flavor baremetal \
--key-name "${KEY_NAME}" \
--nic net-id=${NETWORK_SHAREDNET1} \
--hint reservation=${RESERVATION_ID} \
${INSTANCE_NAME}
set +x

# wait for instance to be active
while true ; do
  INSTANCE_STATE=$(openstack server show ${INSTANCE_NAME} -f json | jq -r '.status')
  if [ ${INSTANCE_STATE} == "ACTIVE" ] ; then
    echo "instance ${INSTANCE_NAME} active."
    break
  fi
  echo "instance ${INSTANCE_NAME} in state ${INSTANCE_STATE} ..."
  sleep 3
done


# collect information

export FLOATING_IP_RESOURCE_ID=$(blazar lease-show ${LEASE_NAME} -f json | jq -rc '.reservations' | jq -c '.'  | grep virtual:floatingip | jq -r .id)
echo "FLOATING_IP_RESOURCE_ID: ${FLOATING_IP_RESOURCE_ID}"

export FLOATING_IP_ID=$(openstack floating ip list --tags reservation:${FLOATING_IP_RESOURCE_ID} -f json | jq -r '.[].ID')
echo "FLOATING_IP_ID: ${FLOATING_IP_ID}"

export FLOATING_IP=$(openstack floating ip list --tags reservation:${FLOATING_IP_RESOURCE_ID} -f json | jq -r '.[]."Floating IP Address"')
echo "FLOATING_IP: ${FLOATING_IP}"


set -x
openstack server add floating ip ${INSTANCE_NAME} ${FLOATING_IP}
set +x


echo "Try to log into your instance: (please use correct path to you ssh key)"
echo "ssh -i ~/.ssh/${KEY_NAME}.pem cc@${FLOATING_IP}"
echo ""
echo "For clean-up use: blazar lease-delete ${LEASE_NAME}"



