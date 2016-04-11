#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ZETA_SYNC="/mapr/${CLUSTERNAME}/mesos/kstore/zetasync"

ZETA_ADM="/mapr/${CLUSTERNAME}/user/zetaadm/zetaadmin"

USER_LIST="zetausers.list"
GROUP_LIST="zetagroups.list"

USER_NAME=$1
GROUP_NAME=$2

if [ "$USER_NAME" == "" ] || [ "$GROUP_NAME" == "" ]; then
    echo "User or Group cannot be blank"
    echo "./addtozetagroup.sh %USERNAME% %GROUPNAME%"
    exit 1
fi

UTEST=$(grep $USER_NAME $ZETA_SYNC/$USER_LIST)
GTEST=$(grep $GROUP_NAME $ZETA_SYNC/$GROUP_LIST)

if [ "$UTEST" == "" ]; then
    echo "User $USER_NAME not in $ZETA_SYNC/$USER_LIST... exiting"
    exit 1
fi

if [ "$GTEST" == "" ]; then
    echo "Group $GROUP_NAME not in $ZETA_SYNC/$GROUP_LIST... exiting"
    exit 1
fi


DUPTEST=$(grep $GROUP_NAME $ZETA_SYNC/$GROUP_LIST|grep $USER_NAME)

if [ "$DUPTEST" != "" ]; then
    echo "User $USER_NAME is already in group $GROUP_NAME"
    echo "Exiting"
    exit 1
fi

echo "Add $USER_NAME to $GROUP_NAME"

echo "Current:"
echo $GTEST
GNEW="$GTEST,$USER_NAME"
echo "Proposed:"
echo $GNEW
echo ""
echo "New zetagroups.list"

sed "s/$GTEST/$GNEW/" $ZETA_SYNC/$GROUP_LIST
echo ""
echo "Running on nodes"
${ZETA_ADM}/run_cmd.sh "sudo usermod -a -G $GROUP_NAME $USER_NAME"
sed -i "s/$GTEST/$GNEW/" $ZETA_SYNC/$GROUP_LIST
