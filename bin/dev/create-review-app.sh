#!/bin/bash

# create a review app from the test fixture

# PWD should be repo root
cd $(dirname "$0")/../..

kubectl config use-context minikube
kubectl apply -f test/fixtures/reviewapp.yaml
