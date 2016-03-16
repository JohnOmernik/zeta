#!/bin/bin

CLUSTERNAME=$(ls /mapr)
MESOS_ROLE="prod"

. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh

echo "Your base Zeta Env is setup"
echo "Here are some notes for your Zeta. Note: you can run this at any time to refresh"


echo "Zeta ENV Variables are the best way to code your apps. you can do this by including the following script:"
echo ""
echo "/mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh"
echo ""
echo "In code you write."  
echo "Example in bash script"
echo ""
echo "#!/bin/bash"
echo "CLUSTERNAME=$(ls /mapr) # Get the clustername by looking at the mapr nfs mount point"
echo "MESOS_ROLE=\"prod\" # You do have to indicate the mesos role, everything is setup for prod for now"
echo "./mapr/\${CLUSTERNAME}/mesos/kstore/env/zeta_\${CLUSTERNAME}_\${MESOS_ROLE}.sh"
echo ""
echo ""
echo "In other langages such as python, you can run the env script and pass 1 as it's only argument. This will echo out all the variables in KEY=VALUE format for easy splitting and use in your script"
echo ""
echo "To add more variables, please use the subdirectory under where the env script is located for your mesos role (env_prod for prod, env_dev for dev etc)"
echo "Create a script (.sh) file where you export your variables.  This entire directory will be sourced by the main the script. "
echo "All Zeta ENV variables MUST be be prefixed with \"ZETA_\" to work correctly."
echo ""
echo ""
echo ""
echo "Web UI Endpoints to be aware of:"
echo ""
echo "Mesos default UI:              http://${ZETA_MESOS_LEADER}:${ZETA_MESOS_LEADER_PORT}"
echo "Marathon UI:                   http://${ZETA_MARATHON_HOST}:${ZETA_MARATHON_PORT}"
echo "Chronos UI (If installed):     http://${ZETA_CHRONOS_HOST}:${ZETA_CHRONOS_PORT}"
echo ""

echo "Current ENV Variables:"
echo ""
. /mapr/${CLUSTERNAME}/mesos/kstore/env/zeta_${CLUSTERNAME}_${MESOS_ROLE}.sh 1
