#!/bin/bash

PROJECT_NAME=$1

REPO_URL=$2

VERSION=$(git log --pretty=format:'%h' -n 1)

$(aws ecr get-login --no-include-email)

## We need to change this because of the way fargate works. Fargate uses localhost to communicate with each container
## whereas docker-compose needs the container name as the hostname

sed -i -e 's/fastcgi_pass php:9000;/fastcgi_pass 127.0.0.1:9000;/g' docker/nginx/config.conf

docker-compose build > /dev/null

IMAGE_IDS=$(docker images | grep -i ${PROJECT_NAME} | awk '{print $3}')

for imageId in ${IMAGE_IDS}; do
    IMAGE_NAME=$(docker images | grep -i ${imageId} | awk '{print $1}')

    docker tag ${imageId} ${REPO_URL}/${IMAGE_NAME}:${VERSION}

    docker push ${REPO_URL}/${IMAGE_NAME}:${VERSION}

    docker rmi --force ${imageId}
done

## Revert back the changes because we wont be able to use this locally (even though this script shouldn't be used locally)
sed -i -e 's/fastcgi_pass 127.0.0.1:9000;/fastcgi_pass php:9000;/g' docker/nginx/config.conf