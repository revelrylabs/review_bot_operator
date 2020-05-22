#!/bin/bash

# update the review app as if a new commit was pushed

kubectl config use-context minikube
kubectl patch reviewapp test --type='merge' -p '{"spec": {"commitHash": "5ce6e4a15e2a09fe113aba79263104835bd676c2"}}'
