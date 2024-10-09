#!/bin/sh
# update.sh - Automatic Updater for ERPNext
#
# Generates the docker image and composer file and redeploys the docker Setup
#


# Input checks are done within entrypoint.sh


##
##  PREPARATION
##

# Prepare
cd /home/updater/
rm -rf ./app/
git clone "https://github.com/frappe/frappe_docker" "./app/${APP_NAME}/"
cd "./app/${APP_NAME}/"

# Set default frappe env variables
cp example.env .env
export PULL_POLICY=never
export CUSTOM_IMAGE="frappeupdater/${APP_NAME}"
export CUSTOM_TAG="1.0.0"
# Set apps ENV variable
export APPS_JSON_BASE64=$(base64 -w 0 /home/updater/config/apps.json)


# Manipulate dockerfile for more efficient deployment
echo USER root >> ./images/custom/Containerfile

# Apply custom Dockerfile.extra content
cat /home/updater/config/Dockerfile.extra >> ./images/custom/Containerfile

# Switch back to frappe
echo " " >> ./images/custom/Containerfile   # Add newline in case there is none in Docker.extra
echo "USER frappe" >> ./images/custom/Containerfile

##
##  BUILD PROCESS
##

# Build docker image
# Cache needs to be disabled, since docker doesn't know about possible app updates
docker build \
  --build-arg=APPS_JSON_BASE64="${APPS_JSON_BASE64}" \
  --tag="${CUSTOM_IMAGE}:${CUSTOM_TAG}" \
  --file=images/custom/Containerfile --no-cache .

# Create Docker compose file
docker compose -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.noproxy.yaml \
  config > ./docker-compose.yaml

##
##  DEPLOYMENT
##

# Shutdown and delete current project
docker compose -p "${PROJECT_NAME}" down

# Clear anonymous volues (without prompt)
docker volume prune -f

# Create new docker container
docker compose -p "${PROJECT_NAME}" -f docker-compose.yaml up -d --force-recreate

# After update maintenance
bench="docker compose -f docker-compose.yaml -p "${PROJECT_NAME}" exec backend bench "

$bench --site all migrate
$bench --site all clear-cache
$bench --site all clear-website-cache

# Clear builder layer cache in order to prevent excessive storage use
docker builder prune -f

exit 0