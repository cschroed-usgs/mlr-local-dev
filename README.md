# MLR Development Pack
A set of scripts, configuration, and other utilities to aid in setting up the MLR development environment.

## Making changes and GitIgnore
In order to help prevent accidental commiting of secrets and other non-public configuration this project provides reference configuration files for tomcat and docker that should be copied (as explained in the setup steps below) and then modified for local use from the copies. The .gitignore for this project is setup to ignore the following directories created during the setup steps below:

- mlr-local-dev/docker/*

If you want to make changes to the configuration that is persisted and can be used by future users of this project you should make those changes to the equivalent file(s) in one of these directories. **Please be sure to not commit any secret values or other non-public configuration (passwords, usernames, internal URLs, etc.).**

- mlr-local-dev/docker-reference/* (Docker configuration and secrets)

## Setup

### Copy Reference Docker Configuration
The docker configuration is currently located in `mlr-local-dev/docker-reference/`. This represents the reference configuration and is what users of this project should start from. You should make a copy of this directory called `docker` in the same root directory of this project (so you'd end up with `mlr-local-dev/docker-reference/configuration/...` and `mlr-local-dev/docker/configuration...`). Any local configuration changes you want to make should be done to your files in `mlr-local-dev/docker` as these are the ones that will be read by the docker-compose file and these are ignored by the gitignore.

### Import Certs

You must import the cert from ./ssl/tomcat-wildcard-dev.crt into the Java cacerts if you want locally running, non-dockerized services to be able to connect to the local dev docker containers.

## Running

Because there are inter-dependencies between services the startup order is very important. It is recommended to wait for one terminal command to fully startup before exectuing the next command.

### Terminal 1: `sudo ./launch_backing_services.sh`
 - Starts Water Auth, S3 Mock, and a Fake SMTP Server
 - This script also handles creating the export bucket in the mock s3 server
### Terminal 2: `sudo docker-compose up mlr-legacy-db`
 - Starts the MLR Legacy PostgreSQL Database
### Terminal 3: `sudo docker-compose up mlr-legacy mlr-notification mlr-ddot-ingester mlr-wsc-file-exporter mlr-validator mlr-legacy-transformer mlr-gateway`
 - Starts mlr-legacy mlr-notification mlr-ddot-ingester mlr-wsc-file-exporter mlr-validator mlr-legacy-transformer and mlr-gateway

After completing these steps you should be able to access the MLR UI by visiting: https://localhost:6026/

## Service Info
**Note**: Many of the launch commands here will not properly work until you follow the setup steps above.

_Dependencies_: Services that must be running before this service can even start up.

_Services Used_: Services that must be running for this service to be fully functional.

#### water-auth
 - Individual Launch Command: `sudo docker-compose up water-auth`
 - Dependencies: None
 - Services Used: None
 - Port: 8443
 - Context Path: /auth
 - Test URL: https://localhost:8443/auth
