#!/bin/bash

# build and publish images of the stub app.
# Pass your docker.io user as the first parameter

# PWD should be the app-stub folder
cd $(dirname "$0")/../../dev-resources/app-stub

DOCKER_USER=$1

if [ -z "$DOCKER_USER" ]
then
  echo "USAGE: build-stub-app.sh my-docker-user"
  echo "please supply your dockerhub username"
  exit 1
fi

SHA1=c8c9aa334a
SHA2=5ce6e4a15e
docker build -t $DOCKER_USER/test-review-app-678:$SHA1 --build-arg VERSION=$SHA1 .
docker build -t $DOCKER_USER/test-review-app-678:$SHA2 --build-arg VERSION=$SHA2 .

docker push $DOCKER_USER/test-review-app-678:$SHA1
docker push $DOCKER_USER/test-review-app-678:$SHA2
