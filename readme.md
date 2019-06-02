# Fargate Example

## Steps to use

- Run `docker-compose up --build -d`
- Run `docker images`
- Get the image names from the previous command
- Create AWS ECR repositories with the image names (Grab the `REPO_URL`)
- Get the project prefix (`PROJECT_NAME`) from the image name (everything before the underscore `_`)
- Create a cluster 
- Create a Task Definition with the ECR images (by default this uses the latest), check out the task-definition.json for an example
- Run `./build.sh PROJECT_NAME REPO_URL`
- Start a new Task in your cluster
- Visit the Public IP and you should see a `Hello World` page
- Navigate to `/phpinfo.php` and you will get the PHP Info

## Gotchas
- Docker-compose & Fargate use different networking so we need to replace the hostname in the nginx config when building
(check the `build.sh` script)
- Source needs to be added to the Docker container as Fargate doesn't have access to the internals