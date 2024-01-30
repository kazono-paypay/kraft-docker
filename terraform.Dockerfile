FROM amazonlinux:2023

ARG TF_VERSION=1.5.7
ENV HOME=/root

RUN yum -y update \
    && yum -y install \
      less \
      procps-ng \
      unzip \
      vim \
      wget \
    && wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
    && unzip ./terraform_${TF_VERSION}_linux_amd64.zip -d /usr/local/bin/ \
    && rm ./terraform_${TF_VERSION}_linux_amd64.zip

WORKDIR ${HOME}
CMD ["/bin/bash"]
