#!/bin/sh

# Turn on the nginx ingress controller in the local minikube cluster
# This will automatically connect Ingress resources in the cluster to
# Minikube's IP on the host, accessible via $(minikube ip)

echo "Enabling the NGINX ingress controller in the minikube cluster"
minikube addons enable ingress
