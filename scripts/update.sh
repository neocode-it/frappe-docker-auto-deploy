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
rm -rf ./frappe_docker
git clone https://github.com/frappe/frappe_docker
cd frappe_docker

# Set default frappe env variables
cp example.env .env
export PULL_POLICY=never
# Set apps ENV variable
export APPS_JSON_BASE64=$(base64 -w 0 /home/updater/config/apps.json)


# Manipulate dockerfile for more efficient deployment
echo USER root >> ./images/custom/Containerfile

# Apply custom Dockerfile.extra content
cat /home/updater/config/Dockerfile.extra >> ./images/custom/Containerfile

# Switch back to frappe
echo " " >> ./images/custom/Containerfile   # Add newline in case there is none in Docker.extra
echo "USER frappe" >> ./images/custom/Containerfile

