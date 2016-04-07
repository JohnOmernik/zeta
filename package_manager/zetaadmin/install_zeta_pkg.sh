#!/bin/bash

CLUSTERNAME=$(ls /mapr)


WORKING="/tmp"
PKG_ROOT="/home/zetaadm/zeta_packages"
ZETA_PKG=$1
PKG_TEMPLATES="/mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/"

mkdir -p ${PKG_TEMPLATES}
tar zxf ${PKG_ROOT}/zeta_inst_zetaincludes.tgz -C ${PKG_TEMPLATES}


if [ "$ZETA_PKG" == "" ]; then
        echo "No package selected"
        echo "To install package, use just the name of the package (i.e. zeta_inst_marathon_native.tgz) as an argument"
        echo ""
        echo "List of packages available to install:"
        echo "--------------------------------------"
        ls -1 $PKG_ROOT
        echo ""
        exit 0
fi

PKG=$(echo $ZETA_PKG|sed "s/zeta_inst_//g"|sed "s/\.tgz//g")

echo "Package tgz: $ZETA_PKG"

echo "Package Name: $PKG"

if [ ! -f "${PKG_ROOT}/${ZETA_PKG}" ]; then
        echo "Can't find that file ... exiting"
        exit 1
fi

tar zxf ${PKG_ROOT}/${ZETA_PKG} -C $WORKING


if [ ! -d "$WORKING/$PKG" ]; then
        echo "This did not work as intended, are you sure it's a valid zeta install package"
        exit 1
fi

if [ ! -f "$WORKING/$PKG/zeta_install.sh" ]; then
        echo "There doesn't seem to be a zeta_install.sh script here. Invalid Package?"
        rm -rf $WORKING/$PKG
        exit 1
else
        chmod +x $WORKING/$PKG/zeta_install.sh
fi

$WORKING/$PKG/zeta_install.sh

rm -rf $WORKING/$PKG

