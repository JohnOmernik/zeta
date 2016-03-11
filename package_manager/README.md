# Zeta Package Manager
---
The goal of the package manager is to make some packages easy to install on the reference Zeta setup.  This includes cluster components, administration, frameworks that all form a nice base

---
## Currently included
* marathon_native - An install that pulls from Mesosphere a native instance of Marathon. This is used for the main "prod" role of Marathon running on the cluster
* zetaadmin - A collection of scripts used for administrating the Zeta cluster. More details inside

## Conventions for packages
* Each package name, such as zetaadmin or marathon_native should be a directory under package_manager. This will include the scripts to install on the reference Zeta cluster
* Within the root of each package under package_manager there MUST be a script named zeta_install.sh Without this, the installer won't work. 
* The package_tgzs.sh will walk the package_manager directory and create individual package tgzs for each package in the formant zeta_inst_package.tgz (zeta_inst_marathon_native.tgz or zeta_inst_zetaadmin.tgz for example)
* The tgz are not actually included in the repo. You must run the package_tgzs.sh after pulling the repo. 
* tgzs that are included in the actual packages will be included, however we advise not to if possible. Try to only pull from know locations as part of the install. You can create your own branch of the package_manager if you need to include tgz.

