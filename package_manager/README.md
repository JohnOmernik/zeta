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
* hbaserest
* kafka
* kafkamanager 
* kafkarest
* marathonlb - Load balancing and service discovery on Zeta
* marathonnative - An install that pulls from Mesosphere a native instance of Marathon. This is used for the main "prod" role of Marathon running on the cluster
* mesosdns - Service discovery on Zeta
* mesosui
* package_template
* schemaregistry
* zeppelin
* zetaadmin - A collection of scripts used for administrating the Zeta cluster. More details inside
* zetaincludes
---
## Package Templates
---
There is a package call "package_template" this package is not installable, but instead contains the 4 scripts that make up almost every package. This is designed for new package creation, and uses by default the packages stored in zetaincludes

Zetaincludes are files that are installed to your cluster in order to help facilitate a unified error checking of installs into zeta.  There are two files:
* inc_zeta_install.sh - This is only used by the zeta_install.sh script in each package.
* inc_general.sh - This is used by other packages. 

The includes provide package developers with a basic system of error checking (to ensure application ids etc don't bad characters) and some standard information gathering for installation of applications, after the includes are sourced, there are certain variables available to the package automatically, they are:
### Variables available to both inc_zeta_install.sh and inc_general.sh 
Note: many of these variables can and will  be inferered by the script based on where the file is run from. If it is not clear, then the scripts prompt. 
* $CLUSTERNAME - This is actually sourced in the individual scripts at the top, but is available. This is the cluster name. 
* $APP - This is the application name. Not the instance, but the actual name of the app. This is non-negotiable, and is based on the package being installed. Examples: kafka, drill, mesosui, etc. 
* $MESOS_ROLE - this is the role that package is installed in.  It will often provide a default value of prod, but this can be changed. If the role doesn't exist on your cluster, it will error out. 
* $APP_ROOT - This is the install location for the application. Not the individual instances.  So, this is where the scripts to install instances, or get new packages will exist
* $APP_DIR - This is install location within zeta (i.e. etl, data, mesos, apps) Most packages are mesos, but if you change this, you can specify in the install process. Trust the defaults in most cases
* $APP_PACKAGES - This is where you can store packages for use in specific instances, it is actuall ${APP_ROOT}/${APP}_packages and you will see it used that way in a bunch of scripts. This was added recently as it was obvious it was used the same way in many installs. $APP_PACKAGES is an alias for ${APP_ROOT}/${APP}_packages and can be used interchangeably. 
* All $MESOS_ROLE - once $MESOS_ROLE is determined in the script, this automatically sources the cluster role based env scripts for use in your installs.  

### Variables included with the inc_general.sh
In addition to the above variables, the inc_general.sh is for those cases where you are installing an instance, getting a package, or starting an instance. And these levels also determine what variables are available. 

#### get_package.sh
This level is not instance specific, instead, it is used to download files, build sources, create docker images that the instances can use. It has the following variables available, (in addition to the above variables).
* $APP_UP - An upper case representation of the ${APP}. This is useful for ENV variables, or other cases where you don't want to upper case things yourself. 

#### install_instance.sh
This is for installing specific instances. This level takes a package (in ${APP_PACKAGES}) and sets it up via config scripts, marathon files, and other methods to install a new instance.  Some packages allow multiple instances per role, others do not. 

For packages that don't allow multiple instances per role, then, if the ${APP_ID} (defined below) is specified in the install_instance.sh script, it will be used without prompting the user to specify. 

Other variables that will be used to install the instance should be gathered. If the variables are not in the list (of automatically collected variables below), then the install_instance.sh should work to collect them. 

Here are the automatically collected variables (In addition to the above variables):
* $APP_ID - This is the ID for the instance of $APP you are installing. 
* $APP_HOME - This is the path to the instance configurations. This is an alias for ${APP_ROOT}/${APP_ID}
* $MARATHON_SUBMIT - This is the path to file to allow submission to Marathon in the role you are working in. While normally called from start_instance.sh, it is available at this level if needed. 

Other variables that are not automatically collected that install_instance may require you to collect in your install_instance.sh script. 
* ${APP_VER} - The Version of the app that is running.  This is to help understand which version of the app to grab from $APP_PACKAGES. 
* ${APP_TGZ} - For neatness, often times this is just ${APP_VER}.tgz and referes to a specifc tgz file that is in ${APP_PACKAGES}. For cleanliness, it may make sense to have tgz have a single directory named ${APP_VER} for references
* ${APP_PORT} - This is the main port the application will use. It's often wise to update environment scripts with this information so other applications can easily reference. (There is an example in the the template)
* ${APP_*_PORT} - Sometimes an app has other ports other than the main port. Replace the star with what you think a good name for that port will be. 
* ${APP_CPU} - FLoat value that Marathon uses to allocate CPU shares. Sometimes this is set in the install_instance (hard coded) other times it's requested of the user
* ${APP_MEM} - This is the value that Marathon uses to limit memory. It's in MB so 1024 = 1 GB of ram.  No other chracters need, it should be an int. 
* ${APP_*_MEM} - This is where you need to specify other memory settings (Java Heap, or Spark executors) It's custom and used for your own app submission, so it can be any type of valur (1024M or 1G) whatever your app needs. 
* ${APP_*} - Other Application specific items, if you allow users to spefic number of instances, or a specific instance of another application, this is where to store that. Precede all your variables with APP. 

#### start_instance.sh
This file is copied to the ${APP_HOME} by the install_instance.sh script and made executable at that time. There is a copy in each ${APP_HOME} that is executable, and a copy in ${APP_ROOT} that is not executable. 

After an instance is installed, this file actually starts the instance.  There are no extra variables available. 


## Conventions for packages
* package names, like app and instance names should not have any characters except [a-z0-9] - This is enforced via includes/templates
* Each package name, such as zetaadmin or marathonnative should be a directory under package_manager. This will include the scripts to install on the reference Zeta cluster
* Within the root of each package under package_manager there MUST be a script named zeta_install.sh.  Without this, the installer won't work. 
  * Other scripts, get_package.sh, install_instance.sh, and start_instance.sh are all HIGHLY recommended and templates are provided with examples. 
* The package_tgzs.sh will walk the package_manager directory and create individual package tgzs for each package in the formant zeta_inst_package.tgz (zeta_inst_marathon_native.tgz or zeta_inst_zetaadmin.tgz for example)
* In the root of zeta, there is a script named 0_update_package_file.sh. This script runs the package_tgz.sh and uploads the current package file to the cluster defined in cluster.conf. This is a helper script only. 
* The tgz are not actually included in the repo. You must run the package_tgzs.sh after pulling the repo. (This is done in the 1_aws_m7_prepzeta.sh automagically, and also in 0_update_package_file.sh)
* tgzs that are included in the actual package directories will be included, however we advise not to if possible. Try to only pull from know locations as part of the install. You can create your own branch of the package_manager if you need to include tgz. Or, if you must you must. 
* Each package is responsible for ensuring it's depandancies are installed. 
* Try to follow a four step process for installing. This may change in the future but this is a good basic approach. (We will be working to ensure all packages follow this, or document in a README.md why it doesn't work that way (exceptions etc))
  * First: zeta_install.sh - In the zeta_install.sh script, move scripts to good location for your framework and instruct the user what's next
  * Second: get_package.sh - Get the binaries you need for your framework and create runable packages for your framework.. Create the "install directories". Build projects, docker containers etc. This work should be "role" independent, just creating docker containers or tgz executors. 
  * Third: install_instance.sh  - Install instances. In a multi-tenant envirinment, you may have multiple instances of your application running in a given role. Step two should be to install that role.
  * Fourth: start_instance.sh - Configure the a given instance's initial startup/setting.  Installing and instance (step 2) is different from configuring and instance (step 3). 
* Please create new packages and share back!
