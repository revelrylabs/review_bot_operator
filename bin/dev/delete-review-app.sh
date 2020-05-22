#!/bin/bash

# delete the test review app

kubectl config use-context minikube
kubectl delete reviewapp test
