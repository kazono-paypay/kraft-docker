#!/usr/bin/env bash

# Create a private key
keytool \
  -genkey \
  -alias dev \
  -dname "CN=$(hostname), OU=, O=, L=Tokyo, S=, C=JP" \
  -keystore server.keystore.jks \
  -keyalg RSA \
  -storepass changeit \
  -keypass changeit

# Create CSR
keytool \
  -keystore server.keystore.jks \
  -alias dev \
  -certreq \
  -file localhost.csr \
  -storepass changeit \
  -keypass changeit

# Create cert signed by CA
openssl x509 \
  -req \
  -CA ca.crt \
  -CAkey ca.key \
  -in localhost.csr \
  -out localhost-signed.crt \
  -days 9999 \
  -CAcreateserial \
  -passin pass:changeit

# Import CA cert into keystore
keytool \
  -keystore server.keystore.jks \
  -alias CARoot \
  -import \
  -noprompt \
  -file ca.crt \
  -storepass changeit \
  -keypass changeit

# Import signed cert into keystore
keytool \
  -keystore server.keystore.jks \
  -alias dev \
  -import \
  -noprompt \
  -file localhost-signed.crt \
  -storepass changeit \
  -keypass changeit

# import CA cert into truststore
keytool \
  -keystore server.truststore.jks \
  -alias CARoot \
  -import \
  -noprompt \
  -file ca.crt \
  -storepass changeit \
  -keypass changeit

# Inspect keystore contents
keytool \
  -list \
  -v \
  -keystore server.keystore.jks \
  -storepass changeit
