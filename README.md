# zeta
Scripts for Running Zeta Architecture

This Repo includes scripts for running Zeta Architecure. The design goals will be such that certain script steps will have multiple files based on which route you want to go. For example 1_aws_prep_zeta.sh is only run if you are using an AWS based setup of MapR from the AWS Marketplace using MapR's Cloud formation. 

In addition, other steps will be based on is this a "node affecting" or "cluster affecting" action.  

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
