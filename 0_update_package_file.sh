#!/bin/bash

. ./cluster.conf

# This script is not part of the Zeta install, but instead, uses your cluster.conf file and allows you to update packages that may have been added to the repo on your currently running cluster. 
# Invoking this (after you've pulled/updated your repo) repackages the package_manager options, sends them to the edge node using $IUSER and then copies them to zetaadm and makes them ready
# After doing this, just running ~/zetaadmin/install_zeta_pkg.sh will show the new packages. 

cd package_manager

./package_tgzs.sh

cd ..
scp -i $PRVKEY zeta_packages.tgz $IUSER@$IHOST:/home/$IUSER/

ssh -i $PRVKEY $IUSER@$IHOST "tar zxf zeta_packages.tgz && sudo cp -R /home/$IUSER/zeta_packages/ /home/zetaadm/ && sudo chown -R zetaadm:zetaadm /home/zetaadm/zeta_packages"
