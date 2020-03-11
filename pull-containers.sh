#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

ssl/create_keys.sh

mv ssl/wildcard* .travis/

docker run -d -p 8444:443 -p 8080:80 -v $DIR/.travis/nginx.conf:/etc/nginx/nginx.conf -v $DIR/.travis/wildcard.crt:/etc/nginx/wildcard.crt -v $DIR/.travis/wildcard.key:/etc/nginx/wildcard.key --name nginx nginx:latest

sleep 5

NGINX_ADDRESS=${NGINX_ADDRESS:-localhost}
export IMAGES="
water_auth_server
mlr/mlr-legacy-db:latest
mlr/mlr-legacy:latest
mlr/mlr-notification:latest
mlr/mlr-legacy-transformer:latest
mlr/mlr-wsc-file-exporter:latest
mlr/mlr-ddot-ingester:latest
mlr/mlr-gateway:latest
mlr/mlr-validator:latest
"
for IMAGE in $IMAGES; do
  docker pull $NGINX_ADDRESS:8444/$IMAGE
  docker tag $NGINX_ADDRESS:8444/$IMAGE cidasdpdasartip.cr.usgs.gov:8447/$IMAGE
done

docker kill nginx
docker rm nginx
