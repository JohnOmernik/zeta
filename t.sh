#!/bin/bash

GID="2500"
ROOT_DIRS="apps data etl mesos"
for R in $ROOT_DIRS
do
   echo "Role: $R - $GID"
   GID=$(($GID + 1))
done
