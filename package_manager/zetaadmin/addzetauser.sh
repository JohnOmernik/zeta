#!/bin/bash

CLUSTERNAME=$(ls /mapr)

ZETA_SYNC="/mapr/$CLUSTERNAME/mesos/kstore/zetasync"

ZETA_ADM="/mapr/${CLUSTERNAME}/user/zetaadm/zetaadmin"

USER_LIST="zetausers.list"

GROUP_LIST="zetagroups.list"

USER_NAME=$1


DIST_CHK=$(lsb_release -a)
UB_CHK=$(echo $DIST_CHK|grep Ubuntu)
RH_CHK=$(echo $DIST_CHK|grep RedHat)
CO_CHK=$(echo $DIST_CHK|grep CentOS)

if [ "$UB_CHK" != "" ]; then
    INST_TYPE="ubuntu"
    echo "Ubuntu"
elif [ "$RH_CHK" != "" ] || [ "$CO_CHK" != "" ]; then
    INST_TYPE="rh_centos"
    echo "Redhat"
else
    echo "Unknown lsb_release -a version at this time only ubuntu, centos, and redhat is supported"
    echo $DIST_CHK
    exit 1
fi




if [ "$USER_NAME" == "" ]; then
    echo "User cannot be blank"
    echo "./addzetauser.sh %USERNAME%"
    exit 1
fi


UTEST=$(grep $USER_NAME $ZETA_SYNC/$USER_LIST)


if [ "$UTEST" != "" ]; then
    echo "User $USER_NAME already exists in $ZETA_SYNC/$USER_LIST... exiting"
    exit 1
fi


if [ -d "/mapr/$CLUSTERNAME/user/$USER_NAME" ]; then
    echo "User home directory for $USER_NAME already exists at /mapr/$CLUSTERNAME/user"
    echo "User Creation will not continue"
    exit 1
fi



# 2500 = zetaadm:zetaadm
# 2501 + zetausers group
# 2600 = zeta users and their groups (for individuals) and service accounts
# 3500 zeta role based groups

USRLIST="$ZETA_SYNC/$USER_LIST"

echo "Getting Next User UID"
Y=$(cat $USRLIST|grep -E "26[0-9][0-9]")
if [ "$Y" != "" ];then
    echo "Zeta Users already exist"
    TU=$(cat $USRLIST |grep -E "26[0-9][0-9]"|cut -d":" -f2|sort -r|head -1)
    ZETA_UID=$(($TU + 1))
else
    ZETA_UID="2600"
fi



echo "Adding User $USER_NAME with UID $ZETA_UID to all nodes"
echo ""

stty -echo
echo "Please enter the password for $USER_NAME: "
read USER_PASS
echo ""
printf "Please renter password for $USER_NAME: "
read USER_PASS2
echo ""
stty echo

while [ "$USER_PASS" != "$USER_PASS2" ]
do
    echo "Passwords do not match - Please try again"
    stty -echo
    echo "Please enter the password for $USER_NAME: "
    read USER_PASS
    echo ""
    printf "Please renter password for $USER_NAME: "
    read USER_PASS2
    echo ""
    stty echo
done


if [ "$INST_TYPE" == "ubuntu" ]; then
   ADD="adduser --disabled-login --gecos '' --uid=$ZETA_UID $USER_NAME"
   PASS="echo \"$USER_NAME:$USER_PASS\"|chpasswd"
elif [ "$INST_TYPE" == "rh_centos" ]; then
   ADD="adduser --uid $ZETA_UID $USER_NAME"
   PASS="echo \"$USER_PASS\"|passwd --stdin $USER_NAME"
else
    echo "Relase not found, not sure why we are here, exiting"
    exit 1
fi

USCRIPT="/mapr/${CLUSTERNAME}/user/zetaadm/create_${USER_NAME}.sh"
cat > $USCRIPT << EOF99
#!/bin/bash
$ADD
$PASS
EOF99

echo "Creating User"
chmod +x $USCRIPT
${ZETA_ADM}/run_cmd.sh "sudo $USCRIPT"
rm $USCRIPT
echo "${USER_NAME}:${ZETA_UID}" >> $USRLIST

echo "Adding user to zetausers"
${ZETA_ADM}/addtozetagroup.sh $USER_NAME zetausers

echo "Creating MapR-FS Home Directory"
sudo maprcli volume create -name ${USER_NAME} -path /user/${USER_NAME} -rootdirperms 775 -user ${USER_NAME}:fc,a,dump,restore,m,d zetaadm:fc,a,d,m,restore,dump
while [ ! -d "/mapr/${CLUSTERNAME}/user/${USER_NAME}" ]
do
    echo "Listing of user directory, waiting for volume creation:"
    ls -ls /mapr/${CLUSTERNAME}/user/
    sleep 1

done
echo "Home Directory Exists, updating perms"
sudo chown $USER_NAME /mapr/$CLUSTERNAME/user/$USER_NAME
sudo chmod 755 /mapr/$CLUSTERNAME/user/$USER_NAME

echo "User $USER_NAME Created!"
