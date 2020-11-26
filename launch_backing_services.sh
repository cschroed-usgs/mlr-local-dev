#!/bin/bash

# Useful for environments where the Docker engine is not running on the host
# (like Docker Machine)
DOCKER_ENGINE_IP="${DOCKER_ENGINE_IP:-127.0.0.1}"
LOCALSTACK_ENDPOINT="http://localhost:4566"

#import AWS_REGION and other env vars
set -o allexport
source docker/configuration/common/config.env
set +o allexport

launch_services () {
  echo "Launching MLR Backing Services..."
  docker-compose -f docker-compose.yml up --no-color --detach --renew-anon-volumes mlr-keycloak smtp-server localstack
  exit_with_message_on_failure $? "Failed to start backing containers"
}

create_s3_bucket () {
  echo "Creating test S3 bucket..."
  aws --endpoint-url="${LOCALSTACK_ENDPOINT}" s3 mb s3://mock-bucket-test
  exit_with_message_on_failure $? "Could not create S3 bucket"
}

create_sns_topic () {
  echo "Creating mock SNS topic..."
  aws --endpoint-url="${LOCALSTACK_ENDPOINT}" sns create-topic --name mock-topic-test
  exit_with_message_on_failure $? "Could not create SNS topic"
}

localstack_health_check () {
  aws --endpoint-url="${LOCALSTACK_ENDPOINT}" s3 ls > /dev/null 2>&1 && \
  aws --endpoint-url="${LOCALSTACK_ENDPOINT}" sns list-topics > /dev/null 2>&1
}

keycloak_health_check () {
  $(curl -k --output /dev/null --silent --head --fail https://$DOCKER_ENGINE_IP:9443/auth/realms/mlr)
}

exit_with_message_on_failure () {
  local EXIT_CODE=${1}
  local MESSAGE=${2}
  if [[ $EXIT_CODE -ne 0 ]]; then
   echo "${MESSAGE}"
   exit $EXIT_CODE
  fi
}

launch_services

echo "Waiting for MLR KeyCloak to come up..."
until keycloak_health_check ; do echo -ne . && sleep 2; done
echo

echo "Waiting for localstack to come up..."
until localstack_health_check ; do echo -ne . && sleep 2; done
echo

create_s3_bucket

create_sns_topic


echo "Backing services launched successfully."
exit 0
