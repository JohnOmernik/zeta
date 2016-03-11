#!/bin/bash

. ./cluster.conf

cd package_manager

./package_tgzs.sh

cd ..
scp -i $PRVKEY zeta_packages.tgz $IUSER@$IHOST:/home/$IUSER/

ssh -i $PRVKEY $IUSER@$IHOST "tar zxf zeta_packages.tgz && sudo cp -R /home/$IUSER/zeta_packages/ /home/zetaadm/ && sudo chown -R zetaadm:zetaadm /home/zetaadm/zeta_packages"
