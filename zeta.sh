#!/usr/bin/env bash

# SANE DEFAULTS
LOG=/tmp/configure_mapr.log
CONFIG_FL=cluster.conf.default
DIR="$(command cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_MESOS_VER=0.27.2
DEFAULT_MESOS_RPM_ROOT="http://repos.mesosphere.com/el/7/x86_64/RPMS/"
DEFAULT_MESOS_RPM="mesos-0.27.2-2.0.15.centos701406.x86_64.rpm"
DEFAULT_IUSER=ec2-user
DEFAULT_OUTCONF=cluster.conf.final

cd $DIR
if [[ -e $LOG ]]; then rm $LOG; fi

function info(){ echo "[INFO] $1" | tee -a $LOG; }
function err(){ echo "[ERROR] $1" | tee -a $LOG; exit 1; }
function warn(){ echo "[WARN] $1" | tee -a $LOG; }
function git_latest()( git pull origin master )
function test() {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        err "Exit Code: $status with command: $1" >&2
    fi
    return $status
}
function print_conf(){
    awk -F\= '!/^($|[:space:]*#)/{ gsub(/"/,"",$2 ); print "[INFO][CONF_FL]: " $1 " as " $2}' $1
}
function mkpasswd()(openssl rand -base64 300 | sha256sum | awk '{print $1}')
function update_packages(){
    cd package_manager
    ./package_tgzs.sh
    cd ..
}
#source $DIR/steps/step*

# Validate the config file
info "Validating the configuration file"
if [[ -f $DIR/$CONFIG_FL &&  -r $DIR/$CONFIG_FL ]]; then
    source "$DIR/$CONFIG_FL"
    print_conf "$DIR/$CONFIG_FL"

    # Check Mandatory Fields
    if [[ ! $IHOST =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        err "Not a valid IP address"
    fi

    # Mandatory Inputs
    if [[ -z ${IUSER+x} ]];  then err "IUSER not set"; fi
    #if [[ -z ${CLUSTERNAME+x} ]];  then err "CLUSTERNAME not set"; fi
    if [[ -z ${PRVKEY+x} || ! -f ${PRVKEY} || ! -r ${PRVKEY} ]];  then
        err "Private key variable is not set, doesn't exist, or unreadable";
    fi

    # Optional
    IHOST_PORT=${IHOST_PORT:-22}
    MESOS_DOMAIN=${MESOS_DOMAIN:-'mesos'}
    MESOS_VER=${MESOS_DOMAIN:-DEFAULT_MESOS_VER}
    MESOS_RPM_ROOT=${MESOS_RPM_ROOT:-DEFAULT_MESOS_RPM_ROOT}
    MESOS_RPM=${MESOS_RPM:-DEFAULT_MESOS_RPM}
    MESOS_AGENT_USER=${MESOS_AGENT_USER:-"zetaagents"}
    MESOS_AGENT_PASS=${MESOS_AGENT_PASS:-`mkpasswd `}
    MESOS_PROD_PRNCPL=${MESOS_PROD_PRNCPL:-"zetaprodcontrol"}
    MESOS_PROD_PASS=${MESOS_PROD_PASS:-`mkpasswd`}
    MESOS_DEV_PRNCPL=${MESOS_DEV_PRNCPL:-"zetadevcontrol"}
    MESOS_DEV_PASS=${MESOS_DEV_PASS:-`mkpasswd`}
    MAPR_HOME=${MAPR_HOME:-/opt/mapr}
    MAPR_UID=${MAPR_UID:-2000}
    MAPR_USER=${MAPR_USER:-mapr}
    MAPR_GROUP=${MAPR_GROUP:-mapr}
    ZETAADM_UID=${ZETAADM_UID:-2001}
    ZETAADM_USER=${ZETAADM_USERS:-zetaadm}
    ZETAADM_GROUP=${ZETAADM_GROUP:-zetaadm}

    # Make sure the UIDs are not the same for users
    if [[ $ZETAADDM_UID == $MAPR_UID ]]; then err "User UIDs are the same!" && exit 1; fi

    # Output a standard configuration Field
    if [[ -f $DIR/$DEFAULT_OUTCONF ]]; then rm $DIR/$DEFAULT_OUTCONF; fi
    cat $DIR/$CONFIG_FL > $DIR/$DEFAULT_OUTCONF

    # Standardize the config file to be distributed
    impt_conf=(IHOST IHOST_PORT MESOS_DOMAIN MESOS_VER MESOS_RPM_ROOT MESOS_RPM MESOS_AGENT_USER MESOS_AGENT_PASS MESOS_PROD_PRNCPL MESOS_PROD_PASS MESOS_DEV_PRNCPL MESOS_DEV_PASS MAPR_HOME MAPR_UID MAPR_USER MAPR_GROUP ZETAADM_UID ZETAADM_USER ZETAADM_GROUP)

    info "Outputting final config file format"
    for cfvar in "${impt_conf[@]}"
    do
        hldr="${cfvar}"
        echo "$cfvar=${!hldr}"
    done > $DIR/config.final

    # Display Mesos Creds
    info "MESOS AGENT: $MESOS_AGENT_USER / $MESOS_AGENT_PASS"
    info "MESOS PROD: $MESOS_PROD_PRNCPL / $MESOS_PROD_PASS"
    info "MESOS DEV: $MESOS_DEV_PRNCPL /  $MESOS_DEV_PASS"
else
    err "Could not find or read: $DIR/$CONFIG_FL"
fi

SSHHOST="${IUSER}@${IHOST}"
SSHCMD="ssh -o StrictHostKeyChecking=no -p ${IHOST_PORT} -i ${PRVKEY} -t $SSHHOST"
SCPCMD="scp -o StrictHostKeyChecking=no -P ${IHOST_PORT} -i ${PRVKEY}"

 # Test Connection
info "Checking host connectivity"
SSHCHK="ssh -q -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=10 -p ${IHOST_PORT} -i ${PRVKEY} -t ${SSHHOST} hostname"
if [[ $(test $SSHCHK) ]]; then
    info "Successfully connected to the host"
else
    err "Unable to connect to the host via $SSHCHK"
fi

 # Pull Node Data
info "Pulling available nodes..."
NODES=$($SSHCMD "sudo maprcli node list -columns ip | awk 'NR > 1 {print \$2}'")
NODE_CNT=$(echo $NODES | wc -w | xargs)
if [[ "$NODES" == "" ]]; then err "Did not find any nodes" && exit 1; fi
if [[ $NODE_CNT -le 2 ]]; then err "Need > 2 nodes to work" && exit 1; fi
info "Found $NODE_CNT MapR nodes from the cluster"

# Updates Packages
info "Running the Packager to get the latest packages"
update_packages

# Upload
info "Uploading the private key"
$SCPCMD ${PRVKEY} $SSHHOST:/home/${IUSER}/.ssh/id_rsa

# Use your public key linked to AWS to encrypt credentials and save it into the config file
ssh-keygen -f ~/.ssh/id_rsa.pub -e -m PKCS8 > $DIR/encrypt.pub

info "Gathering credentials..."
MAPR_PASS1=''; MAPR_PASS2='adsasf'
ZETAADM_PASS1=''; ZETAADM_PASS2='adsasf'

while [ "$MAPR_PASS1" != "$MAPR_PASS2" ]
do
    read -rs -p "[PROMPT] Enter a password for user [$MAPR_USER]:" MAPR_PASS1
    echo -e ""
    read -rs -p "[PROMPT] Re-Enter a password for user [$MAPR_USER]:" MAPR_PASS2
    echo -e ""
    if [ "$MAPR_PASS1" != "$MAPR_PASS2" ]; then warn "Does not match, try again."; fi
done
info "Encrypted [$MAPR_USER] password and included it in config.final"
MAPR_PASS_ENCRYPT=`echo ${MAPR_PASS1} | openssl rsautl -encrypt -pubin -inkey ${DIR}/encrypt.pub | base64`

while [ "$ZETAADM_PASS1" != "$ZETAADM_PASS2" ]
do
    read -rs -p "[PROMPT] Enter a password for user [$ZETAADM_USER]:" ZETAADM_PASS1
    echo -e ""
    read -rs -p "[PROMPT] Re-Enter a password for user [$ZETAADM_USER]:" ZETAADM_PASS2
    echo -e ""
    if [ "$ZETAADM_PASS" != "$ZETAADM_PASS2" ]; then warn "Does not match, try again."; fi
done

info "Encrypted [$ZETAADM_USER] password and included it in config.final"
ZETAADM_PASS_ENCRYPT=`echo ${ZETAADM_PASS1} | openssl rsautl -encrypt -pubin -inkey ${DIR}/encrypt.pub | base64`

info "Packing everything up and uploading to /home/${IUSER}/."
if [[ -f /tmp/uploader.tar.gz ]]; then rm -f /tmp/uploader.tar.gz; fi
tar -czf /tmp/uploader.tar.gz --exclude .git -C $DIR ../zeta
$SCPCMD /tmp/uploader.tar.gz $SSHHOST:/home/${IUSER}/.

if [[ $? -ne 0 ]]; then
    err "Error uploading data to the server"
    exit 1
fi


$