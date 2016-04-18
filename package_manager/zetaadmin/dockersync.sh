#!/bin/bash

# Script to sync a user, and the various groups that user is in to a docker container at run time. 


ZETA_SYNC="/zeta_sync"
USER_NAME=$1
TMPDIR=$2

if [ "$TMPDIR" != "" ]; then
    ZETA_SYNC=$TMPDIR
fi

GROUP_FILE="zetagroups.list"
USER_FILE="zetausers.list"


if [ -f "/usr/sbin/usermod" ]; then
    echo "usermod found, assuming ubuntu or similar base image"
    BASE_IMG="ubuntu"
else
    echo "Assuming Alpine image, if useradd can't add users to groups, this will fail"
    BASE_IMG="alpine"
fi



if [ "$BASE_IMG" == "ubuntu" ] || [ "$BASE_IMG" == "alpine" ]; then
    echo "Provided imaged $BASE_IMG is approved"
else
    echo "Only ubuntu and alpine images are supported at this time."
    echo "./dockersync.sh %USERNAME% %BASE_IMG%"
    echo "where %BASE_IMG% is alpine or ubuntu"
    exit 1
fi

USER_ID=$(grep $USER_NAME $ZETA_SYNC/$USER_FILE|cut -d":" -f2)

if [ "$USER_ID" == "" ]; then
    echo "Specified user not found in $USER_FILE"
    echo "Exiting"
    exit 1
fi

echo "User to Sync: $USER_NAME"
echo "UID for User: $USER_ID"
echo ""
echo "Image type: $BASE_IMG"

if [ "$BASE_IMG" == "ubuntu" ]; then
    echo "Running Ubuntu Scripts"
    echo ""
    adduser --disabled-password --gecos '' --uid=$USER_ID $USER_NAME
    while read P
    do
        G=$(echo $P|grep $USER_NAME)
        if [ "$G" != "" ]; then
            GRP=$(echo $G|cut -d":" -f1)
            GID=$(echo $G|cut -d":" -f2)
            echo "Adding group $GRP via addgroup --gid $GID $GRP"
            addgroup --gid $GID $GRP
            echo "Adding $USER_NAME to $GRP via usermod -a -G $GRP $USER_NAME"
            usermod -a -G $GRP $USER_NAME
        fi
    done < $ZETA_SYNC/$GROUP_FILE
elif [ "$BASE_IMG" == "alpine" ]; then
    echo "Running alpine scripts"
    echo ""
    echo "Adding user $USER_NAME with UID $USER_ID"
    adduser -D -g '' -u $USER_ID -s /bin/bash $USER_NAME
    while read P
    do
        G=$(echo $P|grep $USER_NAME)
        if [ "$G" != "" ]; then
            GRP=$(echo $G|cut -d":" -f1)
            GID=$(echo $G|cut -d":" -f2)
            echo "Adding group $GRP via addgroup -g $GID $GRP"
            addgroup -g $GID $GRP
            echo "Adding $USER_NAME to $GRP via adduser $USERNAME $GRP"
            adduser $USER_NAME $GRP
        fi
    done < $ZETA_SYNC/$GROUP_FILE
else
    echo "We shouldn't ever get here"
fi
