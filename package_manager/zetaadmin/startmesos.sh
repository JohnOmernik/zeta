#!/bin/bash

RUN=$1
MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

DEVAGENTS="None"
DEVPERC="20"

MASTERPORT="$ZETA_MESOS_LEADER_PORT"

ZKSTR="zk://$ZETA_MESOS_ZK"


MASTER_OPS="--cluster=$CLUSTERNAME --roles=prod,dev --quorum=2 --authenticate --authenticate_slaves --credentials=file:///mapr/$CLUSTERNAME/mesos/kstore/mesosconf/secrets/allcredentials.json --acls=file:///mapr/$CLUSTERNAME/mesos/kstore/mesosconf/mesos_acls.json"

AGENT_OPS="--gc_delay=600mins --disk_watch_interval=60secs --executor_registration_timeout=3mins --credential=file:///mapr/$CLUSTERNAME/mesos/kstore/agents/credential.json"

EXE_RUN="sudo /usr/sbin/mesos-daemon.sh"

CONTAINERIZERS="docker,mesos"

ISOLATION="cgroups/cpu,cgroups/mem"

MASTER_WORK="/opt/mapr/mesos/tmp/master/"
MASTER_LOG="/opt/mapr/mesos/tmp/master_log/"


AGENT_WORK="/opt/mapr/mesos/tmp/slave"
AGENT_LOG="/opt/mapr/mesos/tmp/slave_log/"

echo "Starting Masters:"

INTS="eth0 eth1 p4p1 p5p1 em1 em2"

for MASTER in $ZETA_MESOS_MASTERS
do


    for X in $INTS;
    do
        CHECKCMD="/sbin/ifconfig $X 2> /dev/null|grep -o -P \"inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"|cut -d\" \" -f2"
        CHECK=`ssh $MASTER $CHECKCMD 2> /dev/null`
        if [ "$CHECK" == "" ];then
            CHECKCMD="/sbin/ifconfig $X 2> /dev/null|grep -o -P \"inet addr\:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"|cut -d\" \" -f2"
            CHECK=`ssh $MASTER $CHECKCMD 2> /dev/null`
            CHECK=$(echo $CHECK|sed "s/addr://")
        fi
        if [ "$CHECK" != "" ]; then
            break
        fi
    done
    if [ "$CHECK" != "" ]; then
        echo "Using IP $CHECK"
        MASTERIP="$CHECK"
    else
        echo "Couldn't determine IP for master $MASTER exiting"
        exit 1
    fi

    echo "Master: $MASTER on $MASTERIP:$MASTERPORT"
    echo ""
    CMD="hostname;$EXE_RUN mesos-master --ip=$MASTERIP --work_dir=$MASTER_WORK --log_dir=$MASTER_LOG --zk=$ZKSTR $MASTER_OPS"

    echo "ssh $MASTER \"$CMD\""
    echo ""
    if [ "$RUN" == "1" ]; then
        ssh $MASTER "$CMD"
    fi
    echo ""
done

echo ""
echo "------------------------------------------------------"
echo ""
echo "Putting Agents to Work"
echo ""
for AGENT in $ZETA_MESOS_AGENTS
do
  for X in $INTS;
    do
        CHECKCMD="/sbin/ifconfig $X 2> /dev/null|grep -o -P \"inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"|cut -d\" \" -f2"
        CHECK=`ssh $AGENT $CHECKCMD 2> /dev/null`
        if [ "$CHECK" == "" ];then
            CHECKCMD="/sbin/ifconfig $X 2> /dev/null|grep -o -P \"inet addr\:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"|cut -d\" \" -f2"
            CHECK=`ssh $AGENT $CHECKCMD 2> /dev/null`
            CHECK=$(echo $CHECK|sed "s/addr://")
        fi
        if [ "$CHECK" != "" ]; then
            break
        fi
    done
    if [ "$CHECK" != "" ]; then
        echo "Using IP $CHECK"
        IP="$CHECK"
    else
        echo "Couldn't determine IP for agent $AGENT exiting"
        exit 1
    fi

    echo "$AGENT on $IP"

    if [[ $DEVAGENTS == *"$AGENT"* ]]
    then
        echo "Dev Agent running at $DEVPERC percent of total resources"
        ALLRESOURCES=$(./createmesos.sh $AGENT $DEVPERC 2>/dev/null)
    else
        echo "Prod Only Slave"
        ALLRESOURCES=$(./createmesos.sh $AGENT 2>/dev/null)
    fi




    echo "Res: $ALLRESOURCES"
    echo ""
    CMD="hostname;$EXE_RUN mesos-slave --master=$ZKSTR --ip=$IP --log_dir=$AGENT_LOG --containerizers=$CONTAINERIZERS --isolation=$ISOLATION $AGENT_OPS --work_dir=$AGENT_WORK --resources=\\\"$ALLRESOURCES\\\""
    SSHCMD="hostname;$EXE_RUN mesos-slave --master=$ZKSTR --ip=$IP --log_dir=$AGENT_LOG --containerizers=$CONTAINERIZERS --isolation=$ISOLATION $AGENT_OPS --work_dir=$AGENT_WORK --resources=\"$ALLRESOURCES\""
    echo "ssh $AGENT \"$CMD\""
    echo ""
    echo $SSHCMD
    if [ "$RUN" == "1" ]; then
        ssh $AGENT "$SSHCMD"
    fi


done
