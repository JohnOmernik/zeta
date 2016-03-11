#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_prod.sh


DEVSLAVES="None"
DEVPERC="20"

MASTERPORT="$ZETA_MESOS_LEADER_PORT"

ZKSTR="zk://$ZETA_MESOS_ZK"


MASTER_OPS="--cluster=$CLUSTERNAME --roles=prod,dev --quorum=2 --authenticate --authenticate_slaves --credentials=/mapr/$CLUSTERNAME/mesos/kstore/mesosconf/secrets/allcredentials.json --acls=/mapr/$CLUSTERNAME/mesos/kstore/mesosconf/mesos_acls.json"

SLAVE_OPS="--gc_delay=600mins --disk_watch_interval=60secs --executor_registration_timeout=3mins --credential=/mapr/$CLUSTERNAME/mesos/kstore/agents/credential.json"

EXE_RUN="mesos-daemon.sh"

CONTAINERIZERS="docker,mesos"

ISOLATION="cgroups/cpu,cgroups/mem"
MASTER_WORK="/opt/mapr/mesos/tmp/master/"
MASTER_LOG="/opt/mapr/mesos/tmp/master_log/"


SLAVE_WORK="/opt/mapr/mesos/tmp/slave"
SLAVE_LOG="/opt/mapr/mesos/tmp/slave_log/"

echo "Starting Masters:"



IPCOMMAND1="/sbin/ifconfig eth0|grep -o -P \"inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"|cut -d\" \" -f2"
IPCOMMAND2="/sbin/ifconfig eth1|grep -o -P \"inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"|cut -d\" \" -f2"


for MASTER in $ZETA_MESOS_MASTERS
do
    MASTERIP=`ssh $MASTER "$IPCOMMAND1" 2> /dev/null`
    if [ "$MASTERIP" == "" ]; then
        MASTERIP=`ssh $MASTER "$IPCOMMAND2" 2> /dev/null`
    fi
    echo "Master: $MASTER on $MASTERIP:$MASTERPORT"
    echo ""
    CMD="hostname;$EXE_RUN mesos-master --ip=$MASTERIP --work_dir=$MASTER_WORK --log_dir=$MASTER_LOG --zk=$ZKSTR $MASTER_OPS"

    echo "ssh $MASTER \"$CMD\""
    echo ""
#    ssh $MASTER "$CMD" 2> /dev/null
#    echo "$CMD"
    echo ""
done

echo ""
echo "------------------------------------------------------"
echo ""
echo "Putting Agents to Work"
echo ""
for SLAVE in $ZETA_MESOS_AGENTS
do

    IP=`ssh $SLAVE "$IPCOMMAND1" 2>/dev/null`

    if [ "$IP" == "" ]; then
        IP=`ssh $SLAVE "$IPCOMMAND2" 2>/dev/null`
    fi

    echo "$SLAVE on $IP"

    if [[ $DEVSLAVES == *"$SLAVE"* ]]
    then
        echo "Dev Slave running at $DEVPERC percent of total resources"
        ALLRESOURCES=$(./createmesos.sh $SLAVE $DEVPERC 2>/dev/null)
    else
        echo "Prod Only Slave"
        ALLRESOURCES=$(./createmesos.sh $SLAVE 2>/dev/null)
    fi




    echo "Res: $ALLRESOURCES"
    echo ""
    CMD="hostname;$EXE_RUN mesos-slave --master=$ZKSTR --ip=$IP $SLAVE_WORK --log_dir=$SLAVE_LOG --containerizers=$CONTAINERIZERS --isolation=$ISOLATION $SLAVE_OPS --work_dir=$SLAVE_WORK --resources=\\\"$ALLRESOURCES\\\""
    echo "ssh $SLAVE \"$CMD\""
    echo ""
#   ssh $SLAVE "$CMD" 
 #   ssh $SLAVE "$CMD" 2> /dev/null
#    echo "$CMD"



done
