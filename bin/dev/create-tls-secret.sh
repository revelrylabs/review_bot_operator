#!/bin/bash

# Create a self-signed wildcard TLS certificate and install it
# in the minikube cluster. Also emit a ca.crt file that can be
# added to your browser's trust store to view review apps over TLS

# The cert will be created for the *.local domain, so your
# app_domain setting should use that value

SECRET_NAME=star-dot-local-tls
NAMESPACE=default

# PWD should be the tls folder
cd $(dirname "$0")/../../dev-resources/tls

kubectl config use-context minikube

EXISTING=$(kubectl -n $NAMESPACE get secret $SECRET_NAME -o name --ignore-not-found)
if [ -n $EXISTING ]
then
  echo "The secret $NAMESPACE/$SECRET_NAME already exists"
  read -p "Delete it and create a new one? [y/N]" YN
  if [[ $YN == "y" || $YN == "Y" ]]
  then
    kubectl delete secret -n $NAMESPACE $SECRET_NAME
  else
    exit 0
  fi
fi

echo "Generating private key for CA"
openssl genrsa -out ca.key 2048

echo "Generating public key for CA"
openssl req -new -x509 -sha256 -nodes -key ca.key \
  -out ca.crt -days 3650 -config openssl.cnf

echo "Generating key and CSR for ingress TLS"
openssl req -new -sha256 -nodes -out tls.csr \
  -newkey rsa:2048 -keyout tls.key -config openssl.cnf

echo "Signing CSR to produce TLS cert"
openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out tls.crt -days 3650 -sha256 \
  -extfile ./v3.ext

echo "Creating the TLS secret in your cluster"
kubectl create secret -n $NAMESPACE \
  --key=tls.key --cert=tls.crt \
  tls $SECRET_NAME


echo ""
echo ""
echo "DONE"
echo ""
echo ""
echo "Your ca.crt file is in dev-resources/tls"
echo "You can add that cert to your browser's trust store for testing if desired"

rm tls.* ca.key ca.srl
