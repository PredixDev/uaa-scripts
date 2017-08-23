#!/bin/bash

set -e

if [ -z $1 ]; then
    echo "You must specify a CN as a parameter."
    exit 1
fi

config=./openssl.cnf
days=3650
keylen=2048
subj="/C=US/ST=CA/L=San Ramon/O=GE/OU=GE Digital/CN=$1"

echo -n "Enter a password to protect the private key: "
read -s keypass
echo 
echo -n "Re-enter the password: "
read -s rekeypass
echo

echo $keypass
echo $rekeypass

if [ "$keypass" != "$rekeypass" ]; then
    echo "The passwords do not match. Exiting..."
    exit 1
fi

#openssl genrsa -aes256 -out saml.key -passout pass:$keypass $keylen
openssl genrsa -des3 -out saml.key -passout pass:$keypass $keylen
echo "Generated key"

openssl req -config $config -new -subj "$subj" -key saml.key -passin pass:$keypass -out saml.csr
echo "Generated request"

openssl x509 -req -sha256 -days $days -in saml.csr -signkey saml.key -passin pass:$keypass -out saml.crt -extensions v3_req -extfile $config
#openssl x509 -req -sha1 -days $days -in saml.csr -signkey saml.key -passin pass:$keypass -out saml.crt -extensions v3_req -extfile $config
echo "Signed request"

openssl x509 -text -noout -in saml.crt

echo
echo ======================= UAA CONFIG BEGINS HERE =====================
echo

#echo "  serviceProviderKey: |"
#awk '{print "    " $0}' saml.key
awk 'BEGIN {NF; printf "%s","  serviceProviderKey: | \n" } {sub(/\r/, ""); printf "    %s\n",$0;}' saml.key
echo "  serviceProviderKeyPassword: "$keypass
#echo "  serviceProviderCertificate: |"
#awk '{print "    " $0}' saml.crt
awk 'BEGIN {NF; printf "%s","  serviceProviderCertificate: | \n" } {sub(/\r/, ""); printf "    %s\n",$0;}' saml.crt

echo
echo ======================= UAA CONFIG ENDS HERE =======================
echo
