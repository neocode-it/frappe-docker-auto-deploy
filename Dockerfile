# Use an official base image
from alpine:3.21

# Install Docker & Git
RUN apk add --no-cache coreutils tzdata docker-cli docker-compose bash git 

# Create a non-root user
ARG USER=updater UID=1000 GID=1000

RUN addgroup -g $GID $USER && \
    adduser -D -u $UID -G $USER $USER

WORKDIR /home/$USER

# Copy config folder and scripts content
COPY --chown=$UID:$GID config ./config
COPY --chown=$UID:$GID scripts/* ./

# Set ENV
ENV DB_PASSWORD=""
ENV PROJECT_NAME=""
ENV TZ="UTC"
ENV SCHEDULED_TIME=""
ENV APP_NAME=""
ENV HTTP_PUBLISH_PORT="8080"

# Experimantal, not documented yet
ENV FRAPPE_DOCKER_REPO="https://github.com/frappe/frappe_docker"

# IMPORTANT: Specify all variables which will should be preserved 
# after switching to user updater (done within entrypoint.sh)
ENV PRESERVE_VARS="DB_PASSWORD PROJECT_NAME TZ SCHEDULED_TIME APP_NAME HTTP_PUBLISH_PORT FRAPPE_DOCKER_REPO"

# Entry point
ENTRYPOINT ["/bin/sh", "entrypoint.sh"]