#!/bin/bash
CLUSTERNAME=$(ls /mapr)

ZETA_SYNC="/mapr/$CLUSTERNAME/mesos/kstore/zetasync"

ZETA_ADM="/mapr/${CLUSTERNAME}/user/zetaadm/zetaadmin"

USER_LIST="zetausers.list"

GROUP_LIST="zetagroups.list"

GROUP_NAME=$1


if [ "$GROUP_NAME" == "" ]; then
    echo "Group cannot be blank"
    echo "./addzetagroup.sh %GROUPNAME%"
    exit 1
fi


GTEST=$(grep $GROUP_NAME $ZETA_SYNC/$GROUP_LIST)


if [ "$GTEST" != "" ]; then
    echo "Group $GROUP_NAME already exists in $ZETA_SYNC/$GROUP_LIST... exiting"
    exit 1
fi


# 2500 = zetaadm:zetaadm
# 2501 = zetausers # Special group
# 2600 = zeta users and their groups (for individuals) and service accounts
# 3500 zeta groups


GRPLIST="$ZETA_SYNC/$GROUP_LIST"

echo "Getting GID for group"
T=$(cat $GRPLIST|grep -E "35[0-9][0-9]")
if [ "\$T" != "" ];then
    echo "Found existing zeta groups, finding the next highest GID"
    TP=$(cat $GRPLIST |grep -E "35[0-9][0-9]"|cut -d":" -f2|sort -r|head -1)
    ZETA_GID=$(($TP + 1))
else
    ZETA_GID="3500"
fi

echo "Adding Group $GROUP_NAME with GID $ZETA_GID to all nodes"


echo "Creating the group on all nodes"
${ZETA_ADM}/run_cmd.sh "sudo groupadd --gid $ZETA_GID $GROUP_NAME"

echo "Adding mapr and zetaadm to all nodes"
${ZETA_ADM}/run_cmd.sh "sudo usermod -a -G $GROUP_NAME mapr"
${ZETA_ADM}/run_cmd.sh "sudo usermod -a -G $GROUP_NAME zetaadm"

echo "Adding group to zeta_sync group list"
echo "$GROUP_NAME:$ZETA_GID:mapr,zetaadm" >> $GRPLIST
