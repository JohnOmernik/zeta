# Zeta Package Manager
---
The goal of the package manager is to make some packages easy to install on the reference Zeta setup.  This includes cluster components, administration, frameworks that all form a nice base

---
## Currently included
* chronos
* confluent_base
* docker_images
* dockerregv2 - A Docker registry running on Zeta
* drill
* kafka
* kafka-manager (not ready)
* kafka-rest
* marathon-lb - Load balancing and service discovery on Zeta
* marathon_native - An install that pulls from Mesosphere a native instance of Marathon. This is used for the main "prod" role of Marathon running on the cluster
* mesos-dns - Service discovery on Zeta
* schema-registry
* zetaadmin - A collection of scripts used for administrating the Zeta cluster. More details inside

## Conventions for packages
* Each package name, such as zetaadmin or marathon_native should be a directory under package_manager. This will include the scripts to install on the reference Zeta cluster
* Within the root of each package under package_manager there MUST be a script named zeta_install.sh Without this, the installer won't work. 
* The package_tgzs.sh will walk the package_manager directory and create individual package tgzs for each package in the formant zeta_inst_package.tgz (zeta_inst_marathon_native.tgz or zeta_inst_zetaadmin.tgz for example)
* The tgz are not actually included in the repo. You must run the package_tgzs.sh after pulling the repo. (This is done in the 1_aws_m7_prepzeta.sh automagically)
* tgzs that are included in the actual packages will be included, however we advise not to if possible. Try to only pull from know locations as part of the install. You can create your own branch of the package_manager if you need to include tgz.
* Some packages are not ready. They exit and tell you so if you try to install them
* Each package is responsible for ensuring it's depandancies are installed. 
* Please create new packages and share back!
