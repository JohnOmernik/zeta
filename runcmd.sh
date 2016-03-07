#!/bin/bash

HOSTS="./nodes.list"

# This file allows you to run a command on all the nodes for ease of administration. This assumes that your key is on all nodes

while read HOST; do
  ssh -o StrictHostKeyChecking=no -n $HOST $1
done < $HOSTS
