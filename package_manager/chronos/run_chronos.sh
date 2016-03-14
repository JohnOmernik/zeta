#!/bin/bash
set -o errexit -o nounset -o pipefail
set -x

echo "Chronos home set to $CHRONOS_HOME"

JAR_FILES=( "$CHRONOS_HOME"/target/chronos*.jar )
echo "Using jar file: $JAR_FILES[0]"


export JAVA_LIBRARY_PATH="/usr/local/lib:/lib:/usr/lib"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-/lib}"
export LD_LIBRARY_PATH="$JAVA_LIBRARY_PATH:$LD_LIBRARY_PATH"


CHRONOS_ARGS=()

CHRONOS_ARGS+=( --hostname $HOST )

CHRONOS_ARGS+=( --master $CHRONOS_MASTER )
CHRONOS_ARGS+=( --zk_hosts $CHRONOS_ZK_HOSTS )
CHRONOS_ARGS+=( --zk_path $CHRONOS_ZK_PATH )
CHRONOS_ARGS+=( --http_port $CHRONOS_HTTP_PORT )
CHRONOS_ARGS+=( --mesos_role "$CHRONOS_MESOS_ROLE" )
CHRONOS_ARGS+=( --mesos_framework_name $CHRONOS_MESOS_FRAMEWORK_NAME )
CHRONOS_ARGS+=( --cluster_name $CHRONOS_CLUSTER_NAME )
CHRONOS_ARGS+=( --mesos_authentication_principal $CHRONOS_MESOS_AUTHENTICATION_PRINCIPAL )
CHRONOS_ARGS+=( --mesos_authentication_secret_file $CHRONOS_MESOS_AUTHENTICATION_SECRET_FILE )

if [ "$CHRONOS_DEBUG" == "1" ]; then
   echo "CHRONOS_HOME: $CHRONOS_HOME"
   echo "JAR_FILES: $JAR_FILES"
   echo "CHRONOS_ARGS: $CHRONOS_ARGS"
   env
fi


java -Xmx"$CHRONOS_HEAP" -Xms"$CHRONOS_HEAP" -cp "${JAR_FILES[0]}" org.apache.mesos.chronos.scheduler.Main "${CHRONOS_ARGS[@]}"

