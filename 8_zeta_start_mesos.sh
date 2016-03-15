#!/bin/bash


MESOS_ROLE="prod"
CLUSTERNAME=$(ls /mapr)

cd /home/zetaadm/zetaadmin
./startmesos.sh 1


echo "Mesos should be started now.  At this point you should ssh in  and create a SOCKS proxy connection so you can see the UIs of various services"
echo "Note: After you install mesos-dns, if you drop your SSH Connection and re-establish, and you use remote dns in firefox, you'll get name resolution!"

