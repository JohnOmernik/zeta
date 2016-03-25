#!/bin/bash
APP="mesosdns"
APP_ID="mesosdnsprod"
APP_VER="v0.5.2"
CLUSTERNAME=$(ls /mapr)

. /mapr/${CLUSTERNAME}/mesos/kstore/zeta_inc/zetaincludes/inc_general.sh

H=$(hostname -f)
I=$(sudo maprcli node list -columns ip|grep $H)
IP=$(echo $I|grep -E -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
echo $IP

RESOLVER=$(cat /etc/resolv.conf|grep nameserver|cut -d" " -f 2)

cat > ${APP_HOME}/config.json << EOL
{
  "zk": "zk://${ZETA_MESOS_ZK}",
  "refreshSeconds": 10,
  "ttl": 15,
  "domain": "${ZETA_MESOS_DOMAIN}",
  "ns": "ns1",
  "port": 53,
  "resolvers": ["$RESOLVER"],
  "timeout": 5,
  "listener": "0.0.0.0",
  "SOAMname": "root.ns1.${ZETA_MESOS_DOMAIN}",
  "SOARname": "ns1.${ZETA_MESOS_DOMAIN}",
  "SOARefresh": 60,
  "SOARetry":   600,
  "SOAExpire":  86400,
  "SOAMinttl": 60,
  "dnson": true,
  "httpon": true,
  "httpport": 8123,
  "externalon": true,
  "recurseon": true,
  "IPSources": ["host", "netinfo", "mesos"]
}
EOL

cat > ${APP_HOME}/${APP_ID}.marathon << EOF
{
"cmd": "${APP_ROOT}/${APP}_packages/mesos-dns-${APP_VER}-linux-amd64 -config ${APP_HOME}/config.json",
"cpus": 1.0,
"mem": 768,
"labels": {
"PRODUCTION_READY":"True", "CONTAINERIZER": "Mesos", "ZETAENV":"${MESOS_ROLE}"
},
"id": "${APP_ID}",
"ports":[],
"instances": 1,
"user": "root",
"constraints": [["hostname", "LIKE", "$H"]]
}
EOF


echo "Getting a marathon hostname from the env script"
MAR_HOST=$(echo $ZETA_MARATHON_MASTERS|cut -d" " -f1)

echo "Starting mesosdns"
echo ""
${MARATHON_SUBMIT} ${APP_HOME}/${APP_ID}.marathon ${MAR_HOST}
echo ""
echo ""
sleep 5
echo "Updating resolve.conf This won't survive reboot. This is fragile make stronger for production"
echo ""
echo ""
/home/zetaadm/zetaadmin/run_cmd.sh "sudo sed -i -r 's/nameserver $RESOLVER/nameserver $IP/' /etc/resolv.conf"
echo ""
echo "Mesos DNS is installed"



echo ""
echo ""
echo "Mesos DNS instance ${APP_ID} installed and submitted"
echo ""
echo ""
