#!/bin/bash



SSH="ssh -o StrictHostKeyChecking=no -n"

HOST=$1
DEVPERC=$2
if [ "$DEVPERC" == "" ]; then
        DEVPERC=0
fi
DEBUG=$3

FREECMD="free -m|grep Mem|sed -r \"s/\s{1,}/~/g\"|cut -d\"~\" -f2"
ROLESCMD="ls /opt/mapr/roles"
WARDEN="cat /opt/mapr/conf/warden.conf"

#while read HOST; do
   RES=0
   RES_VCORES=1
   TOTAL_MEM=$($SSH $HOST $FREECMD)
   ROLES=$($SSH $HOST $ROLESCMD)
   OUTROLES=""
   TOTAL_VCORES=$($SSH $HOST nproc)

   if [[ $ROLES == *"cldb"* ]]
   then
       OUTROLES=$(echo "$OUTROLES cldb")
       TMP=$($SSH $HOST $WARDEN|grep "service\.command\.cldb\.heapsize\.max="|cut -d'=' -f2)
       RES=$(echo $TMP + $RES|bc)
       if [ "$DEBUG" == "1" ]; then
          echo "==============================================="
          echo "CLDB Role Found"
          echo "CLDB Heap Max: $TMP"
          echo "Current RES: $RES"
       fi
#       MB=$(echo "$TMP * 1000"|bc)
#       RES=$(echo $MB + $RES|bc)
   fi

   if [[ $ROLES == *"fileserver"* ]]
   then
       OUTROLES=$(echo "$OUTROLES fileserver")
       TMP=$($SSH $HOST $WARDEN|grep "service\.command\.mfs\.heapsize\.maxpercent="|cut -d'=' -f2)
       TMP1=$(echo -n "0.$TMP")
       MB=$(echo "$TOTAL_MEM * $TMP1"|bc)
       RES=$(echo $MB + $RES|bc)

       if [ "$DEBUG" == "1" ]; then
          echo "==============================================="
          echo "Fileserver Role Found"
          echo "Fileserver  Heap MaxPercent: $TMP"
          echo "Expressed as double:: $TMP1"
          echo "TOTAL * expressed as double: $MB"
          echo "Current RES: $RES"
       fi
   fi

   if [[ $ROLES == *"webserver"* ]]
   then
       OUTROLES=$(echo "$OUTROLES webserver")
       TMP=$($SSH $HOST $WARDEN|grep "service\.command\.webserver\.heapsize\.max="|cut -d'=' -f2)
       RES=$(echo $TMP + $RES|bc)

       if [ "$DEBUG" == "1" ]; then
          echo "==============================================="
          echo "Webserver Role Found"
          echo "Webserver Heap Max: $TMP"
          echo "Current RES: $RES"
       fi
   fi

   if [[ $ROLES == *"nfs"* ]]
   then
       OUTROLES=$(echo "$OUTROLES nfs")
       TMP=$($SSH $HOST $WARDEN|grep "service\.command\.nfs\.heapsize\.max="|cut -d'=' -f2)
       RES=$(echo $TMP + $RES|bc)
       if [ "$DEBUG" == "1" ]; then
          echo "==============================================="
          echo "NFS Role Found"
          echo "NFS Heap Max: $TMP"
          echo "Current RES: $RES"
       fi
   fi

   if [[ $ROLES == *"zookeeper"* ]]
   then
       OUTROLES=$(echo "$OUTROLES zk")
       TMP=$($SSH $HOST $WARDEN|grep "service\.command\.zk\.heapsize\.max="|cut -d'=' -f2)
       RES=$(echo $TMP + $RES|bc)
       if [ "$DEBUG" == "1" ]; then
          echo "==============================================="
          echo "ZK Role Found"
          echo "ZK Heap Max: $TMP"
          echo "Current RES: $RES"
       fi
   fi
   AVAIL_MEM=$(echo "$TOTAL_MEM - $RES"|bc)
   AVAIL_VCORES=$(echo "$TOTAL_VCORES - $RES_VCORES"|bc)

if [ "$DEVPERC" -gt "0" ]; then

    DEVPERCDBL=$(echo -n "0.$DEVPERC")

    DEVCORES=$(echo "$AVAIL_VCORES * $DEVPERCDBL"|bc)
    DEVCORESINT=$(echo $DEVCORES | awk '{print int($1+0.5)}')

    DEVMEM=$(echo "$AVAIL_MEM * $DEVPERCDBL"|bc)
    DEVMEMINT=$(echo $DEVMEM | awk '{print int($1+0.5)}')

    DEVOUT=";cpus(dev):$DEVCORESINT;mem(dev):$DEVMEM"

    # MB=$(echo "$TOTAL_MEM * $TMP1"|bc)


fi
#       DEVRESOURCES="cpus(dev):2;mem(dev):2048"
#       ALLRESOURCES="$ALLRESOURCES;$DEVRESOURCES"



if [ "$DEBUG" == "1" ]; then
    if [ "$DEVPERC" -gt "0" ]; then 
        echo ""
        echo "====================================="
        echo "This is the Dev percentage: $DEVPERC and as a double: $DEVPERCDBL"
        echo "====================================="
        echo ""
        echo "Number of Devcores: $DEVCORES and rounded $DEVCORESINT"
        echo "Availble Memory for Dev: $DEVMEM and rounded $DEVMEMINT (not using INT)"
    fi


   echo "==============================================="

   echo "Host: $HOST"
   echo "Memory: $AVAIL_MEM available out of $TOTAL_MEM"
   echo "Cores: $AVAIL_VCORES available out of $TOTAL_VCORES"
   echo "Roles: $OUTROLES"

fi



   echo "cpus(*):$AVAIL_VCORES;mem(*):${AVAIL_MEM}$DEVOUT"


#done < $HOSTS
