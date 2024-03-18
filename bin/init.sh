#!/usr/bin/env bash

KAFKA_HOME=/opt/kafka
KAFKA_BIN_HOME=${KAFKA_HOME}/bin
KAFKA_CONF_HOME=${KAFKA_HOME}/config

TARGET_CONTAINER=$(docker ps --format "{{.Names}}" | grep broker | sort | head -1)
BROKER_PORT=9092
BOOTSTRAP_SERVERS=${TARGET_CONTAINER}:${BROKER_PORT}

NUM_BROKERS=$(docker ps --format "{{.Names}}" | grep broker | wc -l)

TOPIC=test-topic-001
PARTITIONS=${NUM_BROKERS}
REPLICATION_FACTOR=${NUM_BROKERS}
ADMIN_CONFIG=${KAFKA_CONF_HOME}/admin.properties

echo "==> Create Kafka topic for test."
docker exec -it $TARGET_CONTAINER \
  bash -c \
  "$KAFKA_BIN_HOME/kafka-topics.sh --create --topic ${TOPIC} --partitions ${PARTITIONS} --replication-factor ${REPLICATION_FACTOR} --bootstrap-server ${BOOTSTRAP_SERVERS} --command-config ${ADMIN_CONFIG}"
echo "==> ✅ Created topic"
