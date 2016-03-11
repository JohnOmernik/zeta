#!/bin/bash

WORKING="/tmp"

ZETA_PKG=$1


PKG=$(echo $ZETA_PKG|sed "s/zeta_inst_//g"|sed "s/\.tgz//g")

echo "$ZETA_PKG"

echo "$PKG"


tar zxf $ZETA_PKG -C $WORKING


if [ ! -d "$WORKING/$PKG" ]; then
        echo "This did not work as intended, are you sure it's a valid zeta install package"
        exit 1
fi

if [ ! -f "$WORKING/$PKG/zeta_install.sh" ]; then
        echo "There doesn't seem to be a zeta_install.sh script here. Invalid Package?"
        exit 1
else
        chmod +x $WORKING/$PKG/zeta_install.sh
fi

$WORKING/$PKG/zeta_install.sh

rm -rf $WORKING/$PKG
