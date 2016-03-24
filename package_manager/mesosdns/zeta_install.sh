#!/bin/bash

MESOS_ROLE="prod"

CLUSTERNAME=$(ls /mapr)

cd "$(dirname "$0")"

. /mapr/$CLUSTERNAME/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

INST_DIR="/mapr/$CLUSTERNAME/mesos/$MESOS_ROLE/mesosdns"

if [ -d "$INST_DIR" ]; then
    echo "The Installation Directory already exists at $INST_DIR"
    echo "Installation will not continue over that, please rename or delete the existing directory to install fresh"
    exit 1
fi
echo "Making Directories for mesosdns"
mkdir -p $INST_DIR


SRC="https://github.com/mesosphere/mesos-dns/releases/download"
VER="v0.5.2"

mkdir -p ${INST_DIR}/mesos-dns-${VER}

FILENAME="mesos-dns-${VER}-linux-amd64"

FULL_URL="${SRC}/${VER}/${FILENAME}"

wget ${FULL_URL}

cp ${FILENAME} ${INST_DIR}/mesos-dns-$VER/

chmod +x ${INST_DIR}/mesos-dns-$VER/${FILENAME}

H=$(hostname -f)
I=$(sudo maprcli node list -columns ip|grep $H)
IP=$(echo $I|grep -E -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
echo $IP

RESOLVER=$(cat /etc/resolv.conf|grep nameserver|cut -d" " -f 2)



cat > $INST_DIR/config.json << EOL
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

cat > $INST_DIR/mesosdns.marathon << EOF
{
"cmd": "/mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/mesosdns/mesos-dns-${VER}/mesos-dns-${VER}-linux-amd64 -config /mapr/$CLUSTERNAME/mesos/${MESOS_ROLE}/mesosdns/config.json",
"cpus": 1.0,
"mem": 768,
"labels": {
"PRODUCTION_READY":"True", "CONTAINERIZER": "Mesos", "ZETAENV":"Prod"
},
"id": "mesosdns",
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
/home/zetaadm/zetaadmin/marathonprod_submit.sh $INST_DIR/mesosdns.marathon ${MAR_HOST}
echo ""
echo ""
sleep 5
echo "Updating resolve.conf This won't survive reboot. This is fragile make stronger for production"
echo ""
echo ""
/home/zetaadm/zetaadmin/run_cmd.sh "sudo sed -i -r 's/nameserver $RESOLVER/nameserver $IP/' /etc/resolv.conf"
echo ""
echo "Mesos DNS is installed"
