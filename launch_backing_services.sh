#!/bin/bash

# Useful for environments where the Docker engine is not running on the host
# (like Docker Machine)
DOCKER_ENGINE_IP="${DOCKER_ENGINE_IP:-127.0.0.1}"

launch_services () {
  docker-compose -f docker-compose.yml up --no-color --detach --renew-anon-volumes mlr-keycloak mock-s3 smtp-server
}

create_s3_bucket () {
  curl --silent --request PUT "http://${DOCKER_ENGINE_IP}:8080/mock-bucket-test"
}

echo "Launching MLR Backing Services..."

EXIT_CODE=$(launch_services)
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Could not launch backing services"
  exit $EXIT_CODE
fi

echo "Waiting for S3 Mock to come up..."
until nc -vzw 2 $DOCKER_ENGINE_IP 8080 &>/dev/null ; do echo -ne . && sleep 2; done
echo
echo "Creating test S3 bucket..."
EXIT_CODE=$(create_s3_bucket)

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Could not create S3 bucket"
  exit $EXIT_CODE
fi
echo "S3 bucket created successfully."

echo "Waiting for MLR KeyCloak to come up. This can take up to 2 minutes..."
until nc -vzw 2 $DOCKER_ENGINE_IP 9443 &>/dev/null ; do echo -ne . && sleep 5; done
until $(curl -k --output /dev/null --silent --head --fail https://$DOCKER_ENGINE_IP:9443/auth/realms/mlr); do echo -ne . && sleep 2; done
echo
echo "Backing services launched successfully."
exit 0
