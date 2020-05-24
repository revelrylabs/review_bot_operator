#!/bin/bash

echo "Installing KubeDB operator and CRDs in minikube cluster"

kubectl config use-context minikube
curl -fsSL https://raw.githubusercontent.com/kubedb/installer/89fab34cf2f5d9e0bcc3c2d5b0f0599f94ff0dca/deploy/kubedb.sh | bash
