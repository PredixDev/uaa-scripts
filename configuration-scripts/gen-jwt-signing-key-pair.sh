#!/bin/bash
set -e

keylen=2048

#openssl genrsa -aes256 -out saml.key -passout pass:$keypass $keylen
openssl genrsa -out jwt-key-private.pem $keylen
echo "Generated key pair"

openssl rsa -in jwt-key-private.pem -pubout -out jwt-key-public.pem
echo "Extracted public key"

echo
echo ======================= UAA CONFIG BEGINS HERE =====================
echo

#echo "    verification-key: |"
#awk '{print "      " $0}' jwt-key-public.pem
awk 'BEGIN {NF; printf "%s","    verification-key: | \n" } {sub(/\r/, ""); printf "      %s\n",$0;}' jwt-key-public.pem
#echo "    signing-key: |"
#awk '{print "      " $0}' jwt-key-private.pem
echo ""
awk 'BEGIN {NF; printf "%s","    signing-key: | \n" } {sub(/\r/, ""); printf "      %s\n",$0;}' jwt-key-private.pem

echo
echo ======================= UAA CONFIG ENDS HERE =======================
echo