#!/usr/bin/env bash

openssl req -new -x509 -keyout ca.key -out ca.crt -days 365 \
   -subj '/CN=ca.dev.local.co.jp/OU=/O=/L=Tokyo/C=JP' \
   -passin pass:changeit -passout pass:changeit
