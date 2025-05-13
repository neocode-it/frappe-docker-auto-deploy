#!/bin/sh
# update.sh - Automatic Updater for ERPNext
#
# Generates the Docker image and compose file, then redeploys the setup.
#
# NOTE: Input checks are handled in `entrypoint.sh`
#

##
##  PREPARATION
##

# Navigate to updater home directory
cd /home/updater/ || exit 1
rm -rf ./app/
git clone $FRAPPE_DOCKER_REPO "./app/${APP_NAME}/"
cd "./app/${APP_NAME}/" || exit 1

# Set default Frappe environment variables
cp example.env .env
export PULL_POLICY="never"
export CUSTOM_IMAGE="frappeupdater/${APP_NAME}"
export CUSTOM_TAG="1.0.0"

# Set apps ENV variable
export APPS_JSON_BASE64
APPS_JSON_BASE64=$(base64 /home/updater/config/apps.json | tr -d '\n')

# Modify Dockerfile for efficient deployment
echo "USER root" >> ./images/custom/Containerfile

# Apply custom Dockerfile modifications
cat /home/updater/config/Dockerfile.extra >> ./images/custom/Containerfile

# Switch back to frappe user
echo "" >> ./images/custom/Containerfile  # Ensure newline
echo "USER frappe" >> ./images/custom/Containerfile

##
##  BUILD PROCESS
##

# Build the Docker image (disable cache for fresh updates)
docker build \
  --build-arg APPS_JSON_BASE64="${APPS_JSON_BASE64}" \
  --tag "${CUSTOM_IMAGE}:${CUSTOM_TAG}" \
  --file images/custom/Containerfile --no-cache .

# Generate Docker Compose configuration
docker compose -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.noproxy.yaml \
  config > ./docker-compose.yaml

##
##  DEPLOYMENT
##

# Stop and remove existing containers
docker compose -p "${PROJECT_NAME}" down

# Clean up anonymous volumes (force without prompt)
docker volume prune -f

# Deploy new container setup
docker compose -p "${PROJECT_NAME}" -f docker-compose.yaml up -d --force-recreate

##
##  POST-DEPLOYMENT MAINTENANCE
##

# Define bench alias
bench() {
  docker compose -f docker-compose.yaml -p "${PROJECT_NAME}" exec backend bench "$@"
}

# Run Frappe maintenance tasks
bench --site all migrate
bench --site all clear-cache
bench --site all clear-website-cache

# Clear Docker build cache to prevent excessive storage usage
docker builder prune -f

exit 0
