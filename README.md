# zeta
---
Scripts for Running Zeta Architecture

This Repo includes scripts for running Zeta Architecure. The design goals will be such that certain script steps will have multiple files based on which route you want to go.

## Steps to install using reference AWS installation

First you need to have a running MapR cluster based on the Marketplace AMIs. This needs to be M5 or M7.  Once you have a running cluster proceed to Zeta Steps:

1. Copy cluster.conf.default to cluster.conf
2. Edit settings in cluster.conf based on the settings you used in your AWS cluster. (Update the IP address to connect to, the key to connect to a node, the cluster name, passwords for Mesos Roles etc)
3. Run 1_remote_zetaprep.sh - It will give you instructions for the next step which will be... 
4. Log on to node and run 2_zeta_user_prep.sh as your user specified in cluster.conf
5. Once this step is complete, now we change to zetaadm, and cd the zetaadm home directory on the IHOST node
6. Now run all scripts in order starting with 3_



## Scripts included for admin/install
---
* 0_update_package_file.sh - This script does NOT get run as part of the zeta install. (Hence 0_ as a prefix). It is a helper script to reupload the packages (if they change) based on your cluster.conf
  * Helpful for package dev. Change the package, run this, and it's ready to be run by zetaadm.  
  * Just a helper, nothing else.  Don't run run this as part of Install!
---
## Actual Install Scripts
* 1_remote_zetaprep.sh - This script sends all scripts for Zeta install to a remote cluster. 
  * This script is a general script assuming some basic premises. If more work needs to be done here, you can replace it with a custom script, as long it follows all of these rules
  * The Script assumes:
    * The MapR Installation has finished and a working MapR Installation, with nfs self mounted on every node exists on the remote cluster
    * You have updated cluster.conf with a user, host, and private key location of a user with access to the remote cluster
    * The user has sudo access to all nodes on the remote cluster
    * The key provides access to all nodes via SSH on the remote cluster. 
  * The script then runs:    
    * The Package Manager tar scripts for a clean copy of packages
    * Get a node list from the connecting node, save it to nodes.list
    * An upload of 
        * Tthe private key to the node
         * runcmd.sh, nodes.list, and cluster.conf files to the cluster
         * Upload the numbered scripts to the cluster
         * Upload zeta_packages.tgz to the cluster
  * The script then provides instructions on the next steps
  * This steps assumes you are running at least a M5 cluster, as it requires each node to self mount NFS (and to be mounted prior to next steps
* 2_zeta_user_prep.sh - Preps some basic user stuff on the cluster
  * Gets the password for zetaadm and installed zetaadm on all nodes
  * Gets a new password for mapr and sets it on all nodes
  * Creates a keypair for zetaadm and sets up the public key on all nodes
  * Only script to not run as zetaadm. When this is complete, next steps are to switch to zetaadm (2500) and run all remaining scripts as zetaadm
* 3_zeta_layout.sh - Create the basic layout in MapR FS and create zetausers group on all nooes. Also unpack the packager 
* 4_zeta_install_rols.sh - Creates the prod and dev roles as well as create a script to add more roles later
  * Create a script in /mapr/$CLUSTERNAME/user/zetaadm/cluster_inst/ that allows for role creation including users, groups, directories, credentials etc. 
  * Run that script for prod and dev
* 5_zeta_node_prep.sh - Create a script to prepare basic items on nodes. Then run the script on all nodes
  * Update configuration for env
  * Update warden.conf
  * Install nano - don't judge
  * Remove non-FS roles
  * Run on all nodes and create a script to run on future nodes
* 6_zeta_install_docker.sh
  * Install Docker on all nodes and create a script to do so on future nodes 
* 7_zeta_install_mesos_dep.sh
  * Install Mesos dependancies on all nodes and create a script to do so on future nodes
* 8_zeta_install_mesos.sh
  * Install Mesos on all nodes and create a script to do so on future nodes
* 9_zeta_start_mesos.sh
  * Start Mesos on all nodes
* 10_zeta_install_examples.sh
  * Provide some next steps. This script doesn't do anything but provide instructions so it can be run over and over again
* 11_zeta_describe_env.sh
  * Just a handy help to descrube the Zeta Env



