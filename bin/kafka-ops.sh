#!/usr/bin/env bash

CONTROLLERS=$(docker ps --format "{{.Names}}" | grep controller | sort)
BROKERS=$(docker ps --format "{{.Names}}" | grep broker | sort)
INTERVAL=5


KAFKA_HOME=/opt/kafka
KAFKA_SERVER_STOP_SH=$KAFKA_HOME/bin/kafka-server-stop.sh
KAFKA_SERVER_START_SH=$KAFKA_HOME/bin/kafka-server-start.sh
KAFKA_METADATA_SH=$KAFKA_HOME/bin/kafka-metadata-quorum.sh
KAFKA_CONTROLLER_CONFIG=$KAFKA_HOME/config/kraft/controller.properties
KAFKA_BROKER_CONFIG=$KAFKA_HOME/config/kraft/broker.properties

usage() {
  echo "Usage: sh kafka-ops.sh [init|restart-controllers|restart-brokers|update-controller-config|check-status]"
}

init() {
  restart_controllers
  restart_brokers
  check_quorum_status
}

restart_controllers() {
  echo "==> Restart all controllers with $INTERVAL seconds interval."
  for controller in $CONTROLLERS; do
    echo "==> Restart kafka process in ${controller}"
    docker exec ${controller} bash -c "${KAFKA_SERVER_STOP_SH}"
    docker exec ${controller} bash -c "${KAFKA_SERVER_START_SH} -daemon ${KAFKA_CONTROLLER_CONFIG}"
    echo "==> ✅ Restarted controller process in ${controller}"
    echo "Wait ${INTERVAL} sec for warm-up..."
    sleep $INTERVAL
  done
}

restart_brokers() {
  echo "==> Restart all brokers with $INTERVAL seconds interval."
  for broker in $BROKERS; do
    echo "==> Restart kafka process in ${broker}"
    docker exec ${broker} bash -c "${KAFKA_SERVER_STOP_SH}"
    docker exec ${broker} bash -c "${KAFKA_SERVER_START_SH} -daemon ${KAFKA_BROKER_CONFIG}"
    echo "==> ✅ Restarted broker process in ${broker}"
    echo "Wait ${INTERVAL} sec for warm-up..."
    sleep $INTERVAL
  done
}

check_quorum_status() {
  echo "==> Descrbe quprum metadata."
  docker exec -it broker001 \
    ${KAFKA_METADATA_SH} \
    --bootstrap-server broker001:9092 describe --status
  echo ""
  echo "==> Describe replication status."
  docker exec -it broker001 \
    ${KAFKA_METADATA_SH} \
    --bootstrap-server broker001:9092 describe --replication --human-readable
}

case "$1" in
  init)
    init
    ;;
  update-controller-config)
    update_controller_config
    ;;
  restart-controllers)
    restart_controllers
    ;;
  restart-brokers)
    restart_brokers
    ;;
  check-status)
    check_quorum_status
    ;;
  *)
    usage
    ;;
esac

