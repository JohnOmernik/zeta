# zeta
---
Scripts for Running Zeta Architecture

This Repo includes scripts for running Zeta Architecure. The design goals will be such that certain script steps will have multiple files based on which route you want to go. For example 1_aws_prep_zeta.sh is only run if you are using an AWS based setup of MapR from the AWS Marketplace using MapR's Cloud formation.

## Steps to install using reference AWS installation
1. Copy cluster.conf.template to cluster.conf
2. Edit settings in cluster.conf based on the settings you used in your AWS cluster. (Update the IP address to connect to, the key to connect to a node, the cluster name, passwords for Mesos Roles etc)
3. 



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

At this point the automatation stops and waits for you the operation the next steps. 



Basic steps:

1. Prep the built cluster. At this point MapR should be running and ready to go with the nodes having /mapr/$CLUSTERNAME mounted on every node.  
2.Run commands that need to be run on every node in the cluster. 

3. Run Cluster wide scripts. 

At this point we hope to install Mesos, however, the logic isn't set yet. We may do certain tasks in 2 to prep for Mesos, we may even install Mesos/Docker in step two (more to come)

3. The cluster wide scripts setup a basic Zeta Layout, this isn't set in stone, but acts as a nice base to build and customize to your environment.  More documentation to come here. 


So, for a AWS Cluster at this point

1. Create and build using the MapR Marketplace CFT
2. Update cluster.conf with the setting for your cluster (clustername etc)
2. From a box that has access to the private key specified in the CFT in step one: Run 1_aws_prep_zeta.sh
3. Then login to the IHOST node (specified in cluster.conf) and run 2_zeta_base.sh
4. If $ZETA is specified in cluster.conf to be 3_zeta_layout.sh, this script will automatically run 

The cluster is now ready for next steps.  (More to come)
