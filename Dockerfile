# Use an official base image
FROM ubuntu:20.04

# Install Docker 
RUN apt-get update && apt-get install -y \
    curl git && \
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh ./get-docker.sh

# Create a non-root user
ARG USER=updater
ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID $USER && \
    useradd -m -u $UID -g $GID -s /bin/bash $USER

WORKDIR /home/$USER

# Copy config folder and scripts content
COPY --chown=$UID:$GID config ./config
COPY --chown=$UID:$GID scripts/* ./

# Set ENV
ENV CUSTOM_TAG="1.0.0"
ENV CUSTOM_IMAGE=""
ENV DB_PASSWORD=""
ENV PROJECT_NAME=""
ENV TZ="UTC"
ENV SCHEDULED_TIME=""

# IMPORTANT: Specify all variables which will should be preserved 
# after switching to user updater (done within entrypoint.sh)
ENV PRESERVE_VARS="CUSTOM_TAG CUSTOM_IMAGE DB_PASSWORD PROJECT_NAME TZ SCHEDULED_TIME"

# Entry point
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]