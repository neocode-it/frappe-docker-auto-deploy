
## Which steps will this container do?

1. Pull latest app versions and Frappe
2. Generate new custom docker image based on the apps specified in `/config/apps.json` and additional docker build commands specified in `/config/Dockerfile.extra`
3. Generate docker compose file, which includes all required services except the proxy (Frontend will be available on `port 8080`)
4. Stop the current project (specified using ENV-variables)
5. Launch/Recreate project based on the new image
6. Run bench migrate

