# zeta
---
Scripts for Running Zeta Architecture

This Repo includes scripts for running Zeta Architecure. The design goals will be such that certain script steps will have multiple files based on which route you want to go. For example 1_aws_prep_zeta.sh is only run if you are using an AWS based setup of MapR from the AWS Marketplace using MapR's Cloud formation.

## Steps to install using reference AWS installation

First you need to have a running MapR cluster based on the Marketplace AMIs. This needs to be M5 or M7.  Once you have a running cluster proceed to Zeta Steps:

1. Copy cluster.conf.default to cluster.conf
2. Edit settings in cluster.conf based on the settings you used in your AWS cluster. (Update the IP address to connect to, the key to connect to a node, the cluster name, passwords for Mesos Roles etc)
3. Run 1_aws_prep_zeta.sh - It will give you instructions for the next step which will be... 
4. Log on to node and run 2_zeta_base.sh as ec2-user When this is finished, it will instruct you to
5. sudo up to root, the change user to zetaadm, go to the zetaadm home directory. 
6. Now run 3_zeta_layout.sh - This puts things right for zeta!
7. Now run scripts in order, number 4 through 8 If all goes well you should have a running Zeta install
8. You can now run 9 to see how to install some zeta specific packages. The order is recommended. 



## Scripts included for install
---
* 1_aws_prep_zeta.sh - This script is only to push the zeta package to a already built AWS cluster built using the MapR Marketplace Cloud Formation template. This what it does. (if you make a different 1_ script it will have to do these too)
  * Run the Package Manager for a clean copy of packages
  * Get a node list from the connecting node, save it to nodes.list
  * Upload the private key to the node
  * Upload the runcmd.sh, nodes.list, and cluster.conf files to the cluster
  * Upload the numbered scripts to the cluster
  * Upload zeta_packages.tgz to the cluster
  * Provide instructions on the next step
  * This steps assumes you are running at least a M5 cluster, as it requires each node to self mount NFS (and to be mounted prior to next steps
* 2_zeta_base.sh - This script performs the following actions. It should be run as a user that has SSH access with sudo privs on all nodes. (In AWS the main user should suffice given the 1_aws_prep_zeta.sh) It can be run any node. 
  * Install nano ... don't judge
  * Remove All non FS/Admin Roles in MapR (No Yarn, no Drill, no Hive etc)
  * Refresh Roles using configure.sh
  * Update the warden.conf on each node to reflect sane resource usage to play nice with Mesos
  * Update the env.sh to handle docker SUBNETS
  * Restart warden on all nodes
  * Get password for zetaadm user
  * Create zetaadm user on all nodes
  * Create keyless ssh key for zetaadm and distribute the public key
  * Check ZETA variable for next script. If Defined, move it to /home/zetaadm, clean up permissions and run. (i.e. go on to next step automatically)
* 3_zeta_layout.sh - This script orgazinzed the MapR install for a reference Zeta Architecture. This can be changed, but at this time all the packages are based on this architecture, so use it and learn it before changing it. 
  * Check to run the script as 2500
  * cd to the location the script is (should be /home/zetaadm)
  * Clean up default volumes from MapR Marketplace setup
  * Add groups for Zeta to all nodes
  * Add mapr and zetaadm to all those groups on all nodes
  * Setup major directories (apps, data, etl, mesos) in MapR FS Set permissions etc.
  * Setup kstore directories and basic configuration for Mesos
* 4_zeta_packager.sh
* 5_zeta_install_docker.sh
* 6_zeta_install_mesos_dep.sh
* 7_zeta_install_mesos.sh
* 8_zeta_start_mesos.sh
* 9_zeta_install_examples.sh


