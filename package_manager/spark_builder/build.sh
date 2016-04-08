#!/bin/bash
cp /working/builds/${SPARKVER}.tgz /working
tar zxf ${SPARKVER}.tgz
cd ${SPARKVER}

./make-distribution.sh --name ${SPARKNAME} --tgz ${SPARKOPTS}

cp -f ${SPARKVER}-bin-${SPARKNAME}.tgz /working/builds/.
cp -f ${SPARKVER}-bin-${SPARKNAME}.tgz /working/builds/spark-latest.tgz

