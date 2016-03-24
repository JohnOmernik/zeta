# Zeta Package Manager
---
The goal of the package manager is to make some packages easy to install on the reference Zeta setup.  This includes cluster components, administration, frameworks that all form a nice base

---
## Currently included
* chronos
* confluentbase
* dockerimages
* dockerregv2 - A Docker registry running on Zeta
* drill
* kafka
* kafkamanager (not ready)
* kafkarest
* marathonlb - Load balancing and service discovery on Zeta
* marathonnative - An install that pulls from Mesosphere a native instance of Marathon. This is used for the main "prod" role of Marathon running on the cluster
* mesosdns - Service discovery on Zeta
* schemaregistry
* zetaadmin - A collection of scripts used for administrating the Zeta cluster. More details inside

## Conventions for packages
* package names, like app and instance names should not have any characters except [a-z0-9]
* Each package name, such as zetaadmin or marathonnative should be a directory under package_manager. This will include the scripts to install on the reference Zeta cluster
* Within the root of each package under package_manager there MUST be a script named zeta_install.sh Without this, the installer won't work. 
* The package_tgzs.sh will walk the package_manager directory and create individual package tgzs for each package in the formant zeta_inst_package.tgz (zeta_inst_marathon_native.tgz or zeta_inst_zetaadmin.tgz for example)
* In the root of zeta, there is a script named 0_update_package_file.sh. This script runs the package_tgz.sh and uploads the current package file to the cluster defined in cluster.conf. This is a helper script only. 
* The tgz are not actually included in the repo. You must run the package_tgzs.sh after pulling the repo. (This is done in the 1_aws_m7_prepzeta.sh automagically, and also in 0_update_package_file.sh)
* tgzs that are included in the actual package directories will be included, however we advise not to if possible. Try to only pull from know locations as part of the install. You can create your own branch of the package_manager if you need to include tgz. Or, if you must you must. 
* Some packages are not ready. They exit and tell you so if you try to install them.
* Each package is responsible for ensuring it's depandancies are installed. 
* Try to follow a four step process for installing. This may change in the future but this is a good basic approach. (We will be working to ensure all packages follow this, or document in a README.md why it doesn't work that way (exceptions etc))
  * First: In the zeta_install.sh script, move scripts to good location for your framework and instruct the user what's next
  * Second: Get the binaries you need for your framework and create runable packages for your framework.. Create the "install directories". Build projects, docker containers etc. This work should be "role" independent, just creating docker containers or tgz executors. 
  * Third: Install instances. In a multi-tenant envirinment, you may have multiple instances of your application running in a given role. Step two should be to install that role.
  * Fourth: Configure the a given instance's initial startup/setting.  Installing and instance (step 2) is different from configuring and instance (step 3). 
* Please create new packages and share back!
