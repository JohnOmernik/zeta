#!/bin/bash

#############
# Simple Script to Create Zeta Packages ready for deployment on reference Zeta Layout


PKG_DIR="./zeta_packages"

# Loop through directories ignoring $PKG_DIR as well as .

if [ ! -d "$PKG_DIR" ]; then
    mkdir $PKG_DIR
fi


for D in `find . -type d`
do
    if [ "$D" != "." ]; then
        if [ "$D" != "$PKG_DIR" ]; then
            PKG=$(echo $D|sed "s/\.\///g")
            ZETA_PKG="zeta_inst_$PKG.tgz"
            echo "Packaging $PKG into $ZETA_PKG"
            tar zcf ${ZETA_PKG} $D
            mv ${ZETA_PKG} ${PKG_DIR}/
        fi
    fi
done

echo "Packing all packages redundantly into packages tgz for use"
tar zcf zeta_packages.tgz $PKG_DIR
mv zeta_packages.tgz ../
