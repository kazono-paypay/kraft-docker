FROM amazonlinux:2023

ARG KAFKA_VERSION=3.6.1
ARG SCALA_VERSION=2.13

# install necessary packages
RUN yum -y update \
    && yum -y install \
      git \
      hostname \
      java-17-amazon-corretto-headless \
      java-17-amazon-corretto-devel \
      jq \
      krb5-workstation \
      lsof \
      net-tools \
      nmap-ncat \
      openssl \
      procps-ng \
      sudo \
      systemd \
      tar \
      unzip \
      vim \
      wget

# creating ec2-user with sudoers
RUN useradd "ec2-user" && echo "ec2-user ALL=NOPASSWD: ALL" >> /etc/sudoers

# download Kafka and unpack
RUN wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -O /var/lib/misc/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
    && tar -xvzf /var/lib/misc/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
    && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka \
    && mkdir -p /etc/private/ssl

# copy certs and private key for creating JKS
COPY ./files/certs/root-ca/ca.crt /etc/private/ssl/
COPY ./files/certs/root-ca/ca.key /etc/private/ssl/
COPY ./bin/create-certs.sh /etc/private/ssl/
COPY ./bin/start-kafka.sh /usr/bin/start-kafka.sh

# generate JKS for enabling SSL/TLS
RUN cd /etc/private/ssl \
    && sh create-certs.sh

CMD ["start-kafka.sh"]
