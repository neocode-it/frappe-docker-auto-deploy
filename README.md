# Frappe docker auto deploy

Basic Auto-update/ deployment Docker container for custom Frappe docker builds. Will update, build and replace your current Containers or spin up new Project if not existing. It won't create a default bench site or any kind of backup.

## Which steps will this container do?

1. Pull latest app versions and Frappe
2. Generate new custom docker image based on the apps specified in `/config/apps.json` and additional docker build commands specified in `/config/Dockerfile.extra`
3. Generate docker compose file, which includes all required services except the proxy (Frontend will be available on port `HTTP_PUBLISH_PORT` or `8080`)
4. Stop the current project (specified using ENV-variables)
5. Launch/Recreate project based on the new image
6. Run bench migrate

## How to use

Spin up docker container

``` 
docker run -d \
-v /var/run/docker.sock:/var/run/docker.sock \
-v frappe_updater_config:/home/updater/config \
-e DB_PASSWORD="admin" \
-e PROJECT_NAME="frappe" \
--name frappe-updater \
neocodeit/frappe-docker-deploy:1.0.0
```

Optional Parameter:

`-e APP_NAME` App name which will be used to create unique mount and network names. Defaults to `PROJECT_NAME`
`-e TZ` Change default timezone for the scheduler. Defaults to `UTC`
`-e SCHEDULED_TIME` Scheduled time (for updates). Read more about the scheduler below. Defaults to instant run without scheduler beeing set.
`-e HTTP_PUBLISH_PORT`  Change http Port of frappe. Defaults to `8080`

## Scheduler config

You can set `SCHEDULED_TIME` to any valid timestring accepted by bash `date` command. Possible options are: `03:00`, `next monday`. This rule will be applied after every scheduler run. If no timestring is set, this container will run instantly and exit

## Default Frappe config

The docker compose-file will be based on this frappe config:

```
// Please note: In order to enable SSL access, a reverse proxy will be required as it is disabled by default
docker compose -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.noproxy.yaml \
  config > ./docker-compose.yaml
```

## Performance & Downtime

Expected downtime (during redeployment of the container): ~2min

Expected build time (running without downtime): 20min

Due to the fact that cached rebuild can't be used, the build time will take a bit longer at ~20 minutes.
