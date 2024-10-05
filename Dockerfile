# Use an official base image
FROM ubuntu:20.04

# Install Docker 
RUN apt-get update && apt-get install -y \
    sudo curl git && \
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh ./get-docker.sh

# Create a non-root user
ARG USER=dockeruser
ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID $USER && \
    useradd -r -m -u $UID -g $GID -s /bin/bash -G sudo $USER && \
    usermod -a -G docker $USER && \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to the non-root user
USER $USER

# Set the working directory
WORKDIR /home/$USER


# Copy config and scripts
COPY ./config /config
COPY ./scripts/* .

# Set ENV
ENV CUSTOM_TAG="1.0.0"
ENV CUSTOM_IMAGE=""
ENV DB_PASSWORD=""
ENV PROJECT_NAME=""

# Entry point
ENTRYPOINT ["/bin/bash", "update.sh"]