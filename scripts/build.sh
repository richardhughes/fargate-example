#!/bin/bash

PROJECT_NAME=$1

REPO_URL=$2

## Grab the commit hash from the latest commit so we can version the ECR image with this
VERSION=$(git log --pretty=format:'%h' -n 1)

## Login to the Amazon AWS ECR registry
$(aws ecr get-login --no-include-email)

## We need to change this because of the way fargate works. Fargate uses localhost to communicate with each container
## whereas docker-compose needs the container name as the hostname
sed -i -e 's/fastcgi_pass php:9000;/fastcgi_pass 127.0.0.1:9000;/g' docker/nginx/config.conf

## Build a custom docker-compose file that we can use to generate the Task Definition (TD) in the deploy.sh command
## We need to specify the ECR image to use so we can get the right details in the TD
 cat > ./docker-compose.build.yml <<EOL
version: '2'
services:
EOL

## Build the docker containers using our docker-compose.yml file - We need to build the containers to get the image ID
## from Docker
docker-compose build > /dev/null

## Get a list of all the image IDs associated with these so we can tag this specific image with the ECR Repository
IMAGE_IDS=$(docker images | grep -i ${PROJECT_NAME} | awk '{print $3}')

for imageId in ${IMAGE_IDS}; do

    IMAGE_NAME=$(docker images | grep -i ${imageId} | awk '{print $1}')

    ## Need to build up the docker-compose.build file so we can use it in the deploy to link the correct images in the TD
    cat >> ./docker-compose.build.yml <<EOL
    ${IMAGE_NAME}:
        image: ${REPO_URL}/${IMAGE_NAME}:${VERSION}
EOL

    ## Tag the docker Image ID as the ECR URL & Version
    docker tag ${imageId} ${REPO_URL}/${IMAGE_NAME}:${VERSION}

    ## Push the image to the AWS ECR registry with the specific version id from the commit hash
    docker push ${REPO_URL}/${IMAGE_NAME}:${VERSION}

    ## Clean up the image so we don't have any images dangling
    docker rmi --force ${imageId}
done

## Revert back the changes because we wont be able to use this locally (even though this script shouldn't be used locally)
sed -i -e 's/fastcgi_pass 127.0.0.1:9000;/fastcgi_pass php:9000;/g' docker/nginx/config.conf