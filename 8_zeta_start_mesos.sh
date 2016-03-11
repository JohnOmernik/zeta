#!/bin/bash


MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)

cd /home/zetaadm/zetaadmin
./startmesos.sh 1
