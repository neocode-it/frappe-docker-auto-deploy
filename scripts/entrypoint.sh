#!/bin/bash
# Entrypoint.sh will run with root privileges!! 
# This will be required to set GID of updater user dynamically for docker.sock
# 
# It's Important to switch back to updater user at the end

# Check if docker.sock is mounted

DOCKER_SOCKET=/run/docker.sock  # Actual location of docker.sock, /var/run is a symlink.
UPDATER_USER=updater
# List of environment variables to preserve
PRESERVE_VARS="CUSTOM_TAG CUSTOM_IMAGE DB_PASSWORD PROJECT_NAME TZ SCHEDULED_TIME"

##
##  INPUT CHECKS
##

if [ ! -n "${CUSTOM_IMAGE}" ]; then
    echo "Error: image is unset. ENV CUSTOM_IMAGE needs to be specified"
    exit 1
elif [ ! -n "${DB_PASSWORD}" ]; then
    echo "Error: DB password is unset. ENV DB_PASSWORD needs to be specified"
    exit 1
elif [ ! -n "${PROJECT_NAME}" ]; then
    echo "Error: Project name is unset. ENV PROJECT_NAME needs to be specified"
    exit 1
  exit 1
fi

# Check if APP_NAME is set. If not, set default
if [ -z "${APP_NAME}" ]; then
    echo "APP_NAME unset.. using PROJECT_NAME as APP_NAME."
    APP_NAME="${PROJECT_NAME}"
fi
# Check if app name is valid 
if [[ ! "${APP_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: APP_NAME contains invalid characters. Please check APP_NAME or PROJECT_NAME"
    exit 1
fi

# Check if the docker socket does not exists within mount list
if [ -z "$(mount | grep $DOCKER_SOCKET)" ]; then
  echo "ERROR: Docker socket is not mounted. Please refer to the documentation on how to spin-up the container"
  exit 1
fi

# Check if docker.sock exists and is indeed a socket
if [ -S ${DOCKER_SOCKET} ]; then

    # Get the GID of docker.sock
    DOCKER_GID=$(stat -c '%g' ${DOCKER_SOCKET})
    echo "The GID of ${DOCKER_SOCKET} is ${DOCKER_GID}"

    # Add the updater user to the group with the GID of docker.sock
    groupadd -g ${DOCKER_GID} docker_group  # Will create user group with id DOCKER_GID if it doesn't already exist
    usermod -aG ${DOCKER_GID} ${UPDATER_USER}   # Will add the updater user into this group
    echo "Added ${UPDATER_USER} to group with GID ${DOCKER_GID}"
else
    echo "ERROR: Docker socket does not exists or is invalid."
    echo 1
fi

echo "Switching to user ${UPDATER_USER}"

# Preserve specific environment variables and switch to the specified user
su -w "$PRESERVE_VARS" ${UPDATER_USER} -c "/bin/bash scheduler.sh"