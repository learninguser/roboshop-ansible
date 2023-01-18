#!/bin/bash

##### Change these values ###
ZONE_ID="Z097444713DPZHXLPARU8"
DOMAIN="learninguser.online"
SG_NAME="Allow-all"
env=dev
#############################

create_ec2() {
  PRIVATE_IP=$(aws ec2 run-instances \
      --image-id ${AMI_ID} \
      --instance-type t2.micro \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}}, {Key=Monitor,Value=yes}]"  \
      --security-group-ids ${SGID} \
      | jq '.Instances[].PrivateIpAddress' | sed -e 's/"//g')

  sed -e "s/IPADDRESS/${PRIVATE_IP}/" -e "s/COMPONENT/${COMPONENT}/" -e "s/DOMAIN/${DOMAIN}/" route53.json >/tmp/record.json
  aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/record.json 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "Server Created - SUCCESS - DNS RECORD - ${COMPONENT}.${DOMAIN}"
  else
     echo "Server Created - FAILED - DNS RECORD - ${COMPONENT}.${DOMAIN}"
     exit 1
  fi
}

## Main Program
AMI_ID=$(aws ec2 describe-images --filters "Name=name,Values=Centos-8-DevOps-Practice" | jq '.Images[].ImageId' | sed -e 's/"//g')
if [ -z "${AMI_ID}" ]; then
  echo "AMI_ID not found"
  exit 1
fi

SGID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${SG_NAME} | jq  '.SecurityGroups[].GroupId' | sed -e 's/"//g')
if [ -z "${SGID}" ]; then
  echo "Given Security Group does not exit"
  exit 1
fi

component=$*
if [ -z $component ]; then
  for component in catalogue cart user shipping payment frontend mongodb mysql rabbitmq redis dispatch; do
    COMPONENT="${component}-${env}"
    create_ec2
  done
else
  for serv in component; do
  COMPONENT="${serv}-${env}"
  create_ec2
  done
fi
