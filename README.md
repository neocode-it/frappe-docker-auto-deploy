# Frappe docker auto deploy

Basic Auto-update/ deployment Docker container for custom Frappe docker builds. Will update, build and replace your current Containers or spin up new Project if not existing. It won't create a default bench site or any kind of backup.

## Which steps will this container do?

1. Pull latest app versions and Frappe
2. Generate new custom docker image based on the apps specified in `/config/apps.json` and additional docker build commands specified in `/config/Dockerfile.extra`
3. Generate docker compose file, which includes all required services except the proxy (Frontend will be available on port `HTTP_PUBLISH_PORT` or `8080`)
4. Stop the current project (specified using ENV-variables)
5. Launch/Recreate project based on the new image
6. Run bench migrate

