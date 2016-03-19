#!/bin/bash


MESOS_ROLE="$1"



INS="\ \ \ \ { \"principals\": { \"values\": [\"zeta${MESOS_ROLE}control\"] }, \"roles\": { \"values\": [\"${MESOS_ROLE}\"] } },"
sed -i "/\"register_frameworks\": \[/a $INS" ./acls.json


INS="\ \ \ \ { \"principals\": { \"values\": [\"zeta${MESOS_ROLE}control\"] }, \"users\": { \"values\": [\"svc${MESOS_ROLE}data\"]} },"
sed -i "/\"run_tasks\": \[/a $INS" ./acls.json


INS="\ \ \ \ { \"principals\": { \"values\": [\"zeta${MESOS_ROLE}control\"] },\"framework_principals\": { \"values\": \"zeta${MESOS_ROLE}control\" } },"
sed -i "/\"shutdown_frameworks\": \[/a $INS" ./acls.json
