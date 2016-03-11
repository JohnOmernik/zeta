#!/bin/bash

CLUSTERNAME=$(ls /mapr)
. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_prod.sh
cd "$(dirname "$0")"

# This is a basic script to add users to a basic Zeta Setup.  This should have better automation in the future. 

TEST=0

USERMOD="/usr/sbin/usermod"

USERNAME=""  # This should be a valid user in the login domain

MESOSPROD=0
MESOSDEV=1
ETLPROD=0
ETLDEV=1
APPSPROD=0
APPSDEV=1
DATAPROD=0
DATADEV=1
GUIUSER=0
CLUSTERADMIN=0

echo "Step 1: Adding $USERNAME to zetausers on all nodes"
if [ "$TEST" == 0 ]; then
  ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetausers $USERNAME" 2> /dev/null
fi


echo "Now Creating the Users Home Volume"
if [ "$TEST" == 0 ]; then
   maprcli volume create -name ${USERNAME} -path /user/${USERNAME} -rootdirperms 775 -user ${USERNAME}:fc,a,dump,restore,m,d zetaadm:fc,a,d,m,restore,dump
   sudo chown $USERNAME /mapr/$CLUSTERNAME/user/$USERNAME
   sudo chmod 755 /mapr/$CLUSTERNAME/user/$USERNAME
fi


if [ "$MESOSPROD" == 1 ]; then
   echo "Adding to Mesos Prod"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetaprodmesos $USERNAME" 2> /dev/null
   fi
fi

if [ "$MESOSDEV" == 1 ]; then
   echo "Adding to Mesos Dev"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetadevmesos $USERNAME" 2> /dev/null
   fi
fi
if [ "$ETLPROD" == 1 ]; then
   echo "Adding to ETL Prod"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetaprodetl $USERNAME" 2> /dev/null
   fi
fi

if [ "$ETLDEV" == 1 ]; then
   echo "Adding to ETL Dev"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetadevetl $USERNAME" 2> /dev/null
   fi
fi

if [ "$APPSPROD" == 1 ]; then
   echo "Adding to Apps Prod"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetaprodapps $USERNAME" 2> /dev/null
   fi
fi

if [ "$APPSDEV" == 1 ]; then
   echo "Adding to Apps Dev"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetadevapps $USERNAME" 2> /dev/null
   fi
fi

if [ "$DATAPROD" == 1 ]; then
   echo "Adding to Data Prod"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetaproddata $USERNAME" 2> /dev/null
   fi
fi

if [ "$DATADEV" == 1 ]; then
   echo "Adding to Data Dev"
   if [ "$TEST" == 0 ]; then
      ./run_cmd.sh "hostname;sudo $USERMOD -a -G zetadevdata $USERNAME" 2> /dev/null
   fi
fi

