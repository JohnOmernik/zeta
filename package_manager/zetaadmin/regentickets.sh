#!/bin/bash

MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

ZETA_USERS=$(cat /etc/group|grep zetausers|cut -d":" -f4)

DURATION="30:0:0"
AGE="730:0:0"

MAPR_TICKETFILE_DIR="/mapr/$CLUSTERNAME/mesos/kstore/maprtickets/maprticket_"

for user in $(echo $ZETA_USERS | sed "s/,/ /g")
do

    id=$(id -u $user)
    echo "User: $user - ID: $id"

    TICKET="${MAPR_TICKETFILE_DIR}${id}"

    echo "Attempting to remove current ticket"


    echo "Removing Old Ticket"
    if [ "$user" != "mapr" ]; then
        rm $TICKET
    fi
    echo "Creating new Ticket"

    CMD="maprlogin generateticket -type service -user $user -out $TICKET -duration $DURATION -renewal $AGE"
    echo $CMD
    su -c "$CMD" mapr

    echo "Setting ownership to $user:mapr"
    chown $user:mapr $TICKET
    echo "Setting permissions to 660"
    chmod 660 $TICKET

done

