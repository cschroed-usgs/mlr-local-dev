#!/bin/bash

# Useful for environments where the Docker engine is not running on the host
# (like Docker Machine)
DOCKER_ENGINE_IP="${DOCKER_ENGINE_IP:-127.0.0.1}"

launch_services () {
  docker-compose -f docker-compose.yml up --no-color --detach --renew-anon-volumes water-auth mock-s3 smtp-server
}

create_s3_bucket () {
  curl --request PUT "http://${DOCKER_ENGINE_IP}:80/mock-bucket-test"
}

echo "Launching MLR Backing Services..."

EXIT_CODE=$(launch_services)
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Could not launch backing services"
  exit $EXIT_CODE
fi

echo "Waiting for S3 Mock to come up..."
until nc -vzw 2 localhost 80; do sleep 2; done

echo "Creating test s3 bucket..."
EXIT_CODE=$(create_s3_bucket)

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Could not create S3 bucket"
  exit $EXIT_CODE
fi

echo "Bucket created successfully"
echo "Backing services launched successfully."
exit 0

