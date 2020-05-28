#!/bin/bash

# PWD should be repo root
cd $(dirname "$0")/../..

echo "Installing local dev dependencies in minikube cluster"

# regenerate the manifest for the CRD and operator permissions
mix bonny.gen.manifest

# install things in the minikube cluster
kubectl config use-context minikube
kubectl apply -f dev-resources/build-secrets.yaml
kubectl apply -f dev-resources/db-copy-source.yaml
kubectl apply -f dev-resources/app-config.yaml
kubectl apply -f manifest.yaml
