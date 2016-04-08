#!/bin/bash


CONF_LOC="/conf"
NEW_CONF="/conf_new"

mkdir $NEW_CONF
cp ${CONF_LOC}/* ${NEW_CONF}/


echo "id=$HOSTNAME" >> ${NEW_CONF}/kafkarest.properties

