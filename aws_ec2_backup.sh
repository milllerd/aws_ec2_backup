#!/bin/bash
LOGFILE=$(touch /var/log/aws_backup.log)
DATES=`date +%s`
DATENAME=`date +%F\ %H-%M-%S`
DATE=$(date +%F)
DATE8AGO=`date --date="7 day ago" +%s`
LGREEN='\033[1;32m'
LYELLOW='\033[1;33m'
NORM='tput sgr0'
INSTANCE_IDS=$(aws ec2 describe-instances --filters Name=tag:Backup,Values=true Name=instance-state-name,Values=running|grep InstanceId|cut -d '"' -f 4)
INSTANCE_DESCRIPTION=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID|grep Value|grep -v true|cut -d '"' -f 4)
AMI_ID_LIST=$(aws ec2 describe-images --owners self --query Images[].ImageId|cut -d '"' -f 2|egrep -v '\[|\]')

CLEANUP_AMI() {
for AMI_ID in $AMI_ID_LIST; do
AMI_DATE=$(aws ec2 describe-images --image-id $AMI_ID --query Images[].CreationDate|cut -d '"' -f2|awk -F "T" '{printf "%s\n", $1}'|egrep -v '\[|\]')
AMI_DATE_IN_SECONDS=$(date "--date=$AMI_DATE" +%s)
SNAPSHOT_ID=$(aws ec2 describe-images --image-id $AMI_ID|grep SnapshotId|cut -d '"' -f4)
if (( $AMI_DATE_IN_SECONDS <= $DATE8AGO )); then
echo -e "Deregistering AMI - $AMI_ID for $AMI_DATE \\nDeleting Snapshot $SNAPSHOT_ID"
aws ec2 deregister-image --image-id $AMI_ID
aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID
fi
done
}

for INSTANCE_ID in $INSTANCE_IDS; do
INSTANCE_NAME=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID|egrep -B1 '"Key": "Name"'|grep Value|cut -d '"' -f 4)
aws ec2 create-image --instance-id $INSTANCE_ID --name "$DATENAME $INSTANCE_NAME" --description "$DATENAME $INSTANCE_NAME" --no-reboot
done

CLEANUP_AMI

sleep 40
echo -e "$LGREEN$(aws ec2 describe-images --owners self|grep -w Name|cut -d '"' -f 4|sort -r|grep $DATE)`$NORM`"
echo -e "$LYELLOW$(aws ec2 describe-images --owners self|grep -w Name|cut -d '"' -f 4|sort -r|grep -v $DATE)`$NORM`"





