# MLR Development Pack

A set of scripts, configuration, and other utilities to aid in setting up the MLR development environment.

## Local Development Users

MLR Local Dev comes with a pre-configured KeyCloak instance for running locally. This instance has a pre-defined "mlr" realm that has the proper client, user, and role configurations to allow logging into and interacting with MLR locally. The KeyCloak instance comes with 3 users:

1. `admin` (password: `admin`) - This admin user is the only user that can make changes to the KeyCloak configuration itself. However, this user does not have write access to MLR.

2. `mlruser` (password: `password`) - This user is meant to serve as a standard user who has no special roles assigned at all. This user cannot make changes to KeyCloak configuration and does not have write access to MLR.

3. `mlradmin` (password: `password`) - This user is meant to serve as an admin user for MLR. This user cannot make changes to KeyCloak configuration but does have write access to MLR (assigned `mlr_allowed` role).

When developing locally it is recommended that you use the `mlr-admin` user so that you can fully access your running MLR instance, unless you are testing authorization related changes and want to use the `mlruser` user. You should only use the `admin` user if you are making change to the KeyCloak configuration itself through the admin console.

## Making changes and GitIgnore

In order to help prevent accidental committing of secrets and other non-public configuration this project provides reference configuration files for tomcat and docker that should be copied (as explained in the setup steps below) and then modified for local use from the copies. The .gitignore for this project is setup to ignore the following directories created during the setup steps below:

- mlr-local-dev/docker/*

If you want to make changes to the configuration that is persisted and can be used by future users of this project you should make those changes to the equivalent file(s) in one of these directories. **Please be sure to not commit any secret values or other non-public configuration (passwords, usernames, internal URLs, etc.).**

- mlr-local-dev/docker-reference/* (Docker configuration and secrets)

## Setup

### Prerequisites

* bash
* docker, docker-compose
* aws cli, [saml2aws](https://github.com/Versent/saml2aws) (or equivalent means of authenticating with WMA AWS accounts)

### Copy Reference Docker Configuration

The docker configuration is currently located in `mlr-local-dev/docker-reference/`. This represents the reference configuration and is what users of this project should start from. You should make a copy of this directory called `docker` in the same root directory of this project (so you'd end up with `mlr-local-dev/docker-reference/configuration/...` and `mlr-local-dev/docker/configuration...`). Any local configuration changes you want to make should be done to your files in `mlr-local-dev/docker` as these are the ones that will be read by the docker-compose file and these are ignored by the gitignore.

### Generate Development Certificates

In order to run the services you will need to generate a unique, local wildcard development certificate to be served by each service. In most cases you can simply run the script (as regular user, **NOT SUDO**) in the `./ssl/` directory with no additional arguments to create these certs, however in some cases you may need to generate them with additional hostname aliases. Open the script file in the `./ssl/` directory and see the comments at the top for more information.

### Changing Configuration

If you need to make changes to any configuration due to your local system (I.E: Ports already in use) you may need to make those changes in multiple locations:

1. `docker-compose.yml` - Ports that are exposed by the services are set here. If you need to change the port that a service is running on you can simply re-map the port exposed by the container to a different port on your host system (`Format: port: host-port:service port within container`). Additionally, other configuration settings such as what configuration files to load from and what cert files to use are set here, but it's unlikely you will need to make any changes to that.

2. `./docker/configuration/* & ./docker/secrets/*` - Specific configuration for each application is configured here. The `/common` directory is loaded by each `mlr-*` service, so if you need to set or change configuration applying to _all_ services you should change it there. If you need specific configuration for each service that must be set in each service's specific `{config/secrets}.env` file.

## Running

Because there are inter-dependencies between services the startup order is very important. It is recommended to wait for one terminal command to fully startup before executing the next command.

### Terminal 1

#### Download remote reference lists from S3

```bash
saml2aws login #(or similar)
```

```bash
./retrieve-remote-reference-lists-awscli.sh
```

#### Launch Core Services

```bash
./launch_backing_services.sh
```

- Starts MLR KeyCloak, S3 Mock, and a Fake SMTP Server
- This script also handles creating the export bucket in the mock s3 server

```bash
docker-compose up mlr-legacy-db
```

- Starts the MLR Legacy PostgreSQL Database

### Terminal 2

```bash
docker-compose up mlr-legacy mlr-notification mlr-ddot-ingester mlr-wsc-file-exporter mlr-validator mlr-legacy-transformer mlr-gateway
```

- This should not be run until MLR KeyCloak is running and accessible via <https://localhost:9443/> or it will fail as all of these services require that MLR KeyCloak is running before they can successfully start.
- Starts mlr-legacy mlr-notification mlr-ddot-ingester mlr-wsc-file-exporter mlr-validator mlr-legacy-transformer and mlr-gateway

After completing these steps you should be able to access the MLR UI by visiting: <https://localhost:6026/>

Additionally, any of the above `docker-compose` commands can be run with the `-d` switch to execute them in daemonized (or detached) mode, which allows you to retain control of the console window in which you run the command. To see the logs for a specific service you can then run `docker-compose logs <service>`.

## Running non-containerized services

If you are looking to work on an MLR service and run it from outside of a docker container you can use the services brought up by this system in conjunction with it.

### Import Certs

You must import the cert from `./ssl/wildcard.crt` into the Java cacerts (for locally running Java services) and the Proper python cert store (for locally running Python services) for the locally running, non-dockerized services to be able to connect to the local dev docker containers.

#### Example commands (may not be entirely accurate for your specific system as file paths can vary)

Java:

```bash
sudo keytool -import -trustcacerts -file ./ssl/wildcard.crt -alias mlr-local-wildcard -keystore $JAVA_HOME/lib/security/cacerts
```

Python:

```bash
sudo cp ./ssl/wildcard.crt /usr/local/share/ca-certificates/mlr-local-wildcard.crt
sudo update-ca-certificates
```

### Configuring

It is recommended that you configure your locally running service as similar to the dockerized version as possible, so that few, if any, other changes are needed to the configuration of other dockerized services. I.E: If possible you should run your service on the same port and context path as the dockerized equivalent.

In order to configure your locally running service like the dockerized one open the `config.env` and `secrets.env` files associated with the service you are running (located in `./docker/{configuration/secrets}/{service name}` if you follow the setup steps above and copied the reference configuration). These files contain the list of environment variables that are being set in the container, and then propagated into the service in question. If you are not running your service from within a docker container you can either set these environment variables in the context in which you're running your application, or open the application configuration file (Python: `/config.py` | Java: `/src/main/resources/application.yml`) and look for where these environment variables are being mapped into application configuration (Python: Look for `os.getenv()` calls | Java: Look for `${ENVIRONMENT_VARIABLE_NAME}`). You can then set the appropriate application configuration values in your locally running application to the equivalent value mapped from the `config.env` and `secrets.env` files.

If you configure your locally running service using the same credentials (if applicable), KeyCloak configuration (if applicable), port, and context path, then there should be no additional configuration required of the local development dockerized services, unless your changes are introducing new configuration.

### Launching

In order for this to work properly you should exclude the service you wish to run locally from the list of services launched in the commands above, however it is important that the launch order is maintained, to a degree. I.E: If you want to work on the mlr-legacy-db you should ensure that you launch your local version of the database prior to launching the set of services listed under `Terminal 2`. If you want to work on any of the services listed in `Terminal 2` you must ensure you have the backing services and mlr-legacy-db running prior to launching your service locally. Note that the order of the services _within_ each command above is **not** important.

## Working with Individual Service Repos

Generally when working on a ticket for MLR the work will be contained within one or two of the services. In this case you'll have cloned the individual service repo to your machine and will be working on the service code from there, and then want to test it locally against the rest of the MLR Stack. That is the primary use-case of MLR Local Dev and is a feature that is supported by each of the individual service repositories.

The README in the service repository should cover how to setup that service to be built and run locally against the rest of the services running in MLR Local Dev. If you have launched a service in MLR Local Dev and then would like to stop it in order to rebuild and run the service from its own repo you can run the following command to stop the running instance from MLR Local Dev:

`docker-compose stop <service>`

## Service Info

This section lists out each of the services and some of the basic information about each one. Much of this information can be obtained from the `docker-compose.yml` file and if any of this configuration needs to be modified that is the first place to look, followed by the config files.

_Dependencies_: Services that must be running before this service can even start up.

_Services Used_: Services that must be running for this service to be fully functional.

**Note**: Many of the launch commands here will not properly work until you follow the setup steps above.

### mlr-keycloak

- Individual Launch Command: `sudo docker-compose up mlr-keycloak`
- Dependencies: None
- Services Used: None
- Port: 9080,9443
- Context Path: /
- Test URL: <https://localhost:9443/>

### mock-s3

- Individual Launch Command: `sudo docker-compose up mock-s3`
- Dependencies: None
- Services Used: None
- Port: 80
- Context Path: /
- Test URL: <https://localhost:80/>

### smtp-server

- Individual Launch Command: `sudo docker-compose up smtp-server`
- Dependencies: None
- Services Used: None
- Port: 25
- Context Path: /
- Test URL: <https://localhost:25>
- Volume: `./email` Emails sent by this mock SMTP server are delivered to this directory instead of to a real email addresses.

### mlr-legacy-db

- Individual Launch Command: `sudo docker-compose up mlr-legacy-db`
- Dependencies: None
- Services Used: None
- Port: 5432
- Context Path: /
- Test URL: <https://localhost:5432> (in PgAdmin)

### mlr-gateway

- Individual Launch Command: `sudo docker-compose up mlr-gateway`
- Dependencies: mlr-keycloak, mlr-legacy-db
- Services Used: mlr-ddot-ingester, mlr-validator, mlr-legacy-transformer, mlr-legacy, mlr-wsc-file-exporter, mlr-notification
- Port: 6026
- Context Path: /
- Test URL: <https://localhost:6026/>

### mlr-ddot-ingester

- Individual Launch Command: `sudo docker-compose up mlr-ddot-ingester`
- Dependencies: mlr-keycloak
- Services Used: None
- Port: 6028
- Context Path: /
- Test URL: <https://localhost:6028/api>

### mlr-validator

- Individual Launch Command: `sudo docker-compose up mlr-validator`
- Dependencies: mlr-keycloak
- Services Used: None
- Port: 6027
- Context Path: /
- Test URL: <https://localhost:6027/api>

### mlr-legacy-transformer

- Individual Launch Command: `sudo docker-compose up mlr-legacy-transformer`
- Dependencies: mlr-keycloak
- Services Used: None
- Port: 6020
- Context Path: /
- Test URL: <https://localhost:6020/api>

### mlr-legacy

- Individual Launch Command: `sudo docker-compose up mlr-legacy`
- Dependencies: mlr-keycloak, mlr-legacy-db
- Services Used: None
- Port: 6010
- Context Path: /
- Test URL: <https://localhost:6010/swagger-ui.html>

### mlr-wsc-file-exporter

- Individual Launch Command: `sudo docker-compose up mlr-wsc-file-exporter`
- Dependencies: mlr-keycloak
- Services Used: mock-s3 (with s3 bucket created as done in the `launch_backing_services.sh` script)
- Port: 6024
- Context Path: /
- Test URL: <https://localhost:6024/api>

### mlr-notification

- Individual Launch Command: `sudo docker-compose up mlr-notification`
- Dependencies: mlr-keycloak, smtp-server
- Services Used: None
- Port: 6025
- Context Path: /
- Test URL: <https://localhost:6025/swagger-ui.html>
