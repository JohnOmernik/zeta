# Zeta To do 
---
There will always be to many things to do in this project, and not enough time. This list will be "my" to-do list. What I mean by that is I will use it to put my thoughts down. Issues that get raised, read, and processed by me may make it here too. 

* Change operations order in scripts
  * First Check for /mapr/$CLUSTERNAME/user/zetaadm
    * As ec2-user we need to run through the nodes.list and create zetaadm user on all nodes.
    * Then we need to create home directory in MapRFS
    * Then we need to check/create groups on nodes.list
  * If it does exist, then we are running this on a single node and we should create users, sync groups etc
    * We need a master file of record for groups in /mesos/kstore/
  * Once zetadm is setup (ssh, sudoers etc on all nodes)
  * Then we go to other node prereqs (Removing YARN/DRILL, we should check first) updating env.sh, updating warden.conf. This should be a common script located in /mapr/users/zetaadm/nodeinstall or something like this so it works the same on initial install or add nodes
  * If new cluster - Setup further directories
  * Then more "per node stuff" for docker, mesos, etc. 
  * The idea here is we need to make one path for initial install and another path for individual node add. 
* Create a CA Store for Zeta user that is trusted by all nodes
* Find a way to parallelize the package installs for Docker and Mesos. Right now it's a serial process adding lots of time to an install. 
* Handle Roles/Permissions better in Zeta (take advantage of Mesos/MapR roles, weights, reservations etc)
* Update Package Installer to be a bit more robust
  * When invoked without a package, list the packages available and installed
  * All for easy declaration of dependancies in install scripts. (i.e. list of packages that it checks are installed before allowing installation of the current package)
  * Package Removal? This is dangerous, especially if there are custom settings/data
  * Package wishlist:
    * Apache Drill
    * Apache Kafka
    * Confluent Platform (Kafka REST API, Schema Registry etc)
    * Apache Myriad/YARN
    * Apache Hive
    * Chronos
    * Basic Docker Image Install
