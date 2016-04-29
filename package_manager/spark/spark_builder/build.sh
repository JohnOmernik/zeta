#!/bin/bash
cp /working/builds/${SPARKVER}.tgz /tmp
cd /tmp
tar zxf ${SPARKVER}.tgz

cd ${SPARKVER}
./make-distribution.sh --name ${SPARKNAME} --tgz ${SPARKOPTS}
cp -f ${SPARKVER}-bin-${SPARKNAME}.tgz /working/builds/.
cp -f ${SPARKVER}-bin-${SPARKNAME}.tgz /working/builds/spark-latest.tgz
