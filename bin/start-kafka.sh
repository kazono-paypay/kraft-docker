#!/bin/bash -e

KAFKA_HOME=/opt/kafka
KRAFT_CONFIG_PATH=$KAFKA_HOME/config/kraft
EXCLUSIONS="|KAFKA_VERSION|KAFKA_HOME|KAFKA_DEBUG|KAFKA_GC_LOG_OPTS|KAFKA_HEAP_OPTS|KAFKA_JMX_OPTS|KAFKA_LOG4J_OPTS|KAFKA_JVM_PERFORMANCE_OPTS|KAFKA_LOG|KAFKA_OPTS|"

# if you want to generate another cluster uuid, please run `(/opt/kafka/bin/kafka-storage.sh random-uuid`
CLUSTER_UUID=wKOmCkwzTx2Th6Ymu_S8wQ

config_updater() {
  echo "==> Applying environment variables..."
  for VAR in $(env)
  do
    env_var=$(echo "$VAR" | cut -d= -f1)
    if [[ "$EXCLUSIONS" = *"|$env_var|"* ]]; then
      echo "Excluding $env_var from broker config"
      continue
    fi

    if [[ $env_var =~ ^KAFKA_ ]]; then
      kafka_name=$(echo "$env_var" | cut -d_ -f2- | tr '[:upper:]' '[:lower:]' | tr _ .)
      config_updater_handler "$kafka_name" "${!env_var}" $CONFIG
    fi
  done
  echo "==> ✅ Enivronment variables applied."
}

config_updater_handler() {
  key=$1
  value=$2
  file=$3

  if grep -E -q "^#?$key=" "$file"; then
    echo "[Configuring] '$key' in '$file'"
    sed -r -i "s@^#?$key=.*@$key=$value@g" "$file"
  else
    echo "[Configuring] '$key' not in '$file'"
    echo "$key=$value" >> $file
  fi
}

setup_kafka_storage() {
  echo ""
  echo "==> Kafka storage setup."
  # Initialize kafka storage and create scram user same time.
  $KAFKA_HOME/bin/kafka-storage.sh format --cluster-id $CLUSTER_UUID --config $CONFIG --ignore-formatted --add-scram 'SCRAM-SHA-256=[name=admin,password=admin-secret]'
  echo "==> ✅ Kafka storage setup completed."
}

start_kafka() {
  echo ""
  echo "==> Start kafka process (process.roles=$KAFKA_PROCESS_ROLES)."
  exec "$KAFKA_HOME/bin/kafka-server-start.sh" $CONFIG
  echo "==> Completed"
}
if [ -n "$KAFKA_PROCESS_ROLES" ]; then
  if [ "$KAFKA_PROCESS_ROLES" == "broker,controller" ]; then
    echo "==> This container's role is $KAFKA_PROCESS_ROLES"
    CONFIG=$KRAFT_CONFIG_PATH/server.properties
  elif [ "$KAFKA_PROCESS_ROLES" == "controller" ]; then
    echo "==> This container's role is $KAFKA_PROCESS_ROLES"
    CONFIG=$KRAFT_CONFIG_PATH/controller.properties
  elif [ "$KAFKA_PROCESS_ROLES" == "broker" ]; then
    echo "==> This container's role is $KAFKA_PROCESS_ROLES"
    CONFIG=$KRAFT_CONFIG_PATH/broker.properties
  fi

  config_updater
  setup_kafka_storage
  start_kafka

else
  echo "This container does not set KAFKA_PROCESS_ROLES to env."
  echo "So, skip start-up phase."
  /bin/bash
fi
