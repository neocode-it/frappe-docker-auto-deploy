#!/bin/sh
# Entrypoint.sh will run with root privileges!!
# This is required to set GID of updater user dynamically for docker.sock
#
# It's important to switch back to updater user at the end

# Check if docker.sock is mounted
DOCKER_SOCKET=/run/docker.sock  # Actual location of docker.sock, /var/run is a symlink.
UPDATER_USER=updater
PRESERVE_VARS="DB_PASSWORD PROJECT_NAME TZ SCHEDULED_TIME APP_NAME HTTP_PUBLISH_PORT FRAPPE_DOCKER_REPO"

##
## INPUT CHECKS
##

if [ -z "${DB_PASSWORD}" ]; then
    echo "Error: DB password is unset. ENV DB_PASSWORD needs to be specified"
    exit 1
fi

if [ -z "${PROJECT_NAME}" ]; then
    echo "Error: Project name is unset. ENV PROJECT_NAME needs to be specified"
    exit 1
fi

if [ "${HTTP_PUBLISH_PORT:-0}" -lt 0 ]; then
    echo "ERROR: HTTP_PUBLISH_PORT cannot be less than 0."
    exit 1
fi

# Check if APP_NAME is set. If not, set default
if [ -z "${APP_NAME}" ]; then
    echo "APP_NAME unset.. using PROJECT_NAME as APP_NAME."
    APP_NAME="${PROJECT_NAME}"
fi

# Check if app name is valid
echo "${APP_NAME}" | grep -Eq '^[a-zA-Z0-9_-]+$'
if [ $? -ne 0 ]; then
    echo "ERROR: APP_NAME contains invalid characters. Please check APP_NAME or PROJECT_NAME"
    exit 1
fi

# Check if the docker socket is mounted
if ! mount | grep -q "${DOCKER_SOCKET}"; then
    echo "ERROR: Docker socket is not mounted. Please refer to the documentation on how to spin-up the container"
    exit 1
fi

# Check if docker.sock exists and is indeed a socket
if [ -S "${DOCKER_SOCKET}" ]; then
    # Get the GID of docker.sock
    DOCKER_GID=$(stat -c '%g' "${DOCKER_SOCKET}")
    echo "The GID of ${DOCKER_SOCKET} is ${DOCKER_GID}"

    # Add the updater user to the group with the GID of docker.sock
    addgroup -g "${DOCKER_GID}" docker_group 2>/dev/null  # Create user group with id DOCKER_GID if it doesn't already exist
    adduser "${UPDATER_USER}" docker_group 2>/dev/null   # Add the updater user into this group
    echo "Added ${UPDATER_USER} to group with GID ${DOCKER_GID}"
else
    echo "ERROR: Docker socket does not exist or is invalid."
    exit 1
fi

echo "Switching to user ${UPDATER_USER}"

# Preserve variables dynamically
ENV_EXPORTS=""
for VAR in $PRESERVE_VARS; do
    VALUE=$(printenv "$VAR")
    ENV_EXPORTS="$ENV_EXPORTS $VAR='$VALUE'"
done

# Switch user while preserving all specified environment variables
exec su - updater -c "env $ENV_EXPORTS sh /home/updater/scheduler.sh"
