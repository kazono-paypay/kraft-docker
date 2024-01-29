#!/usr/bin/env bash

INTERVAL=5
CONTROLLERS=$(docker ps --format "{{.Names}}" | grep controller | sort)
BROKERS=$(docker ps --format "{{.Names}}" | grep broker | sort)

echo ""
echo "--------------- Containers ---------------"
echo "[Controllers]"
echo $CONTROLLERS | tr " " "\n"
echo "[Brokers]"
echo $BROKERS | tr " " "\n"
echo "------------------------------------------"

echo ""
echo "==> Generating UUID for setting up Kafka storage."
TARGET=$(echo $CONTROLLERS | cut -d' ' -f1)
CLUSTER_UUID=$(docker exec -it $TARGET bash -c "/opt/kafka/bin/kafka-storage.sh random-uuid")
# 改行文字として\rが入ってしまっているためカーソルが先頭に戻って上書きされてしまう
# sedで事前に改行文字を削除する
# ref: https://mu-777.hatenablog.com/entry/2022/02/05/190536
CLUSTER_UUID=`echo $CLUSTER_UUID | sed 's/\r//g'`
echo "==> ✅ UUID generated (UUID = $CLUSTER_UUID).";
echo ""

for CONTROLLER in $CONTROLLERS; do
  docker exec \
    -it $CONTROLLER \
    bash -c "sh /var/tmp/setup.sh"

  echo "[$CONTROLLER] ==> Formmaing Kafka storage..."
  docker exec \
    -it $CONTROLLER \
    bash -c " \
      /opt/kafka/bin/kafka-storage.sh format \
      --cluster-id $CLUSTER_UUID \
      --config /opt/kafka/config/kraft/controller.properties \
      --add-scram 'SCRAM-SHA-256=[name=admin,password=admin-secret]'"
  echo "[$CONTROLLER] ==> ✅ Kafka storage setup."

  echo "[$CONTROLLER] ==> Start controller process..."
  docker exec \
    $CONTROLLER \
    bash -c "/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/kraft/controller.properties"
  echo "[$CONTROLLER] ==> ✅ Controller process started.";
  echo ""
done

echo "[INFO] Wait $INTERVAL seconds for warm-up."
end=$INTERVAL
for i in $(seq 1 $end); do
  echo "Waiting ... $i [sec]"
  sleep 1
done

echo ""
for BROKER in $BROKERS; do
  docker exec \
    -it $BROKER \
    bash -c "sh /var/tmp/setup.sh"

  echo "[$BROKER] ==> Formmaing Kafka storage..."
  docker exec \
    -it $BROKER \
    bash -c "/opt/kafka/bin/kafka-storage.sh format -t $CLUSTER_UUID -c /opt/kafka/config/kraft/broker.properties"
  echo "[$BROKER] ==> ✅ Kafka storage setup."

  echo "[$BROKER] ==> Start broker process..."
  docker exec \
    $BROKER \
    bash -c "/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/kraft/broker.properties"
  echo "[$BROKER] ==> ✅ Broker process started.";
  echo ""
done

echo "==> Wait $INTERVAL seconds for warm-up."
end=$INTERVAL
for i in $(seq 1 $end); do
  echo "Waiting ... $i [sec]"
  sleep 1
done

echo ""
echo "==> Check the cluster's information."
TARGET=$(echo $BROKERS | cut -d' ' -f1)
docker exec \
  -it $TARGET \
  /bin/bash -c "/opt/kafka/bin/kafka-metadata-quorum.sh --bootstrap-server $TARGET:9091 describe --status"
echo "==> ✅ Finished.";
