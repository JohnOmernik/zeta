# Zeta To do 
---
There will always be to many things to do in this project, and not enough time. This list will be "my" to-do list. What I mean by that is I will use it to put my thoughts down. Issues that get raised, read, and processed by me may make it here too. 

* Create a CA Store for Zeta user that is trusted by all nodes
* Update mapr user password on all nodes
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
