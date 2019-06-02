#!/bin/bash

FAMILY_NAME=$1

CLUSTER=$2

SERVICE=$3

VERSION=$(git log --pretty=format:'%h' -n 1)

OLD_TASK_DEF=$(aws ecs describe-task-definition --task-definition ${FAMILY_NAME} --output json)

NEW_TASK_DEF=$(echo "$OLD_TASK_DEF" | sed -e "s|\(\"image\": *\".*:\)\(.*\)\"|\1${VERSION}\"|g")

FINAL_TASK=$(echo $NEW_TASK_DEF | jq '.taskDefinition|{family: .family, volumes: .volumes, containerDefinitions: .containerDefinitions, taskRoleArn: .taskRoleArn, executionRoleArn: .executionRoleArn, networkMode: .networkMode, placementConstraints: .placementConstraints, requiresCompatibilities: .requiresCompatibilities, cpu: .cpu, memory: .memory}')

UPDATED_TASK=$(aws ecs register-task-definition --family ${FAMILY_NAME} --cli-input-json "${FINAL_TASK}")

echo "Created a new Task Definition for Version: ${VERSION}"

REVISION=$(echo $UPDATED_TASK | jq '.taskDefinition.revision')

aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$FAMILY_NAME":"$REVISION" > /dev/null

echo "Updated the Service to use latest Task Definition $FAMILY_NAME:$REVISION"
