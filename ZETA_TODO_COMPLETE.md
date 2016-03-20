# To Do Items that have been completed
---


* Develop easy way to add more to ENV script.
  * Original bullets:
    * Perhaps a subdirectory that is sourced and every installed app can add a script
    * We'd need to figure out which things should be in main (probably up to Marathon/Mesos/Chronos/DockerRegistryv2 as those are part of main install) and which should be added with install (Drill Kafka etc)
  * Results: Implemented March 14, 2016 - JRO
    * Used a source directory for each role under /mesos/kstore/env/ (added directory called env_prod, if we do more roles do env_%rolename%)
    * Main Script only has Zookeeper, Mesos, Marathon and Chronos. All other install packages should put script in the env_%rolename% directory
    * Updated all installers to take advantage of this.
    * Some installers will require you add the files and then source them right away
* Update mapr user password on all nodes


