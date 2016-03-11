#!/bin/bash

# Zeta Packager Install

CLUSTERNAME=$(ls /mapr)

# RUN THIS SCRIPT AS zetaadm
if [[ $EUID -ne 2500 ]]; then
   echo "This script must be run as zetaadm" 1>&2
   exit 1
fi


# Change to the root dir
cd "$(dirname "$0")"

. ./cluster.conf


#######################
# Ensure we are zetaadm and load cluster information
# untar zeta_packages.tgz
# get the zetaadmin package move it to /home/zetaadm
# untar zetaadmin package
# cp to /mapr/$CLUSTERNAME/user/zetaadm/
# ensure scripts are set to be executable

echo "Untarring Packages"
tar zxf zeta_packages.tgz

echo "Copying zetaadmin.tgz, untarring, and copying to maprfs location"
cp ./zeta_packages/zeta_inst_zetaadmin.tgz ./
tar zxf zeta_inst_zetaadmin.tgz
cp -R zetaadmin /mapr/$CLUSTERNAME/user/zetaadm/

echo "Removing install package and setting scripts to executable"
rm zeta_inst_zetaadmin.tgz
chmod +x ./zetaadmin/*
chmod +x /mapr/$CLUSTERNAME/user/zetaadm/zetaadmin/*
