#!/bin/bash

CLUSTER=$1

SERVICE=$2

LAUNCH_TYPE=$3

## Using the same version as the build plan
VERSION=$(git log --pretty=format:'%h' -n 1)

## If the build.yml file doesn't exist then the ECR hasn't been updated & we should stop the deployment
if [[ ! -f 'docker-compose.build.yml' ]]
then
    echo "Please run the build.sh command before trying to deploy the container";
    exit 1;
fi;

TASK_DEFINITION=$(ecs-cli compose --file docker-compose.build.yml --ecs-params ecs-params.yml create --launch-type ${LAUNCH_TYPE})

## Get the family and version id for the newly created Task Definition
TASK_DEFINITION=$(echo ${TASK_DEFINITION} | grep -P 'TaskDefinition=("?)(.+)(")$' -o | sed -e 's\"\\g' | sed -e 's\TaskDefinition=\\g' )

echo "Created a new Task Definition for Version: ${VERSION}"

## Update the service to use the new task definition - If containers are running then this will start up another task
## and kill the older tasks
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "${TASK_DEFINITION}" > /dev/null

echo "Updated the Service to use latest Task Definition ${TASK_DEFINITION}"
