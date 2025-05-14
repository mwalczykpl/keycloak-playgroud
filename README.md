# Keycloak Playground

This project is a playground for testing Keycloak with Docker and Terraform.

## Prerequisites

- [Docker](https://www.docker.com/)
- [pwgen](https://linux.die.net/man/1/pwgen) (for generating secrets)

## Scripts

### `update_env_passwords.sh`

This script updates or deletes secrets in the `.env` file.

- To update all `PASSWORD` or `SECRET` variables with new random values:
  ```bash
  ./update_env_passwords.sh
  ```

- To delete all `PASSWORD` or `SECRET` variables (set them to an empty string):
  ```bash
  ./update_env_passwords.sh --delete
  ```

The script creates a backup of the `.env` file as `.env.bak` before making changes.

## Docker Compose

The `docker-compose.yaml` file defines the following services:

### MySQL (commented out)
- MySQL database for Keycloak and other services.
- Ports: `${MYSQL_PORT}`
- Volumes: `mysql_data` and `./mysql-init:/docker-entrypoint-initdb.d`

### Keycloak
- Image: `quay.io/keycloak/keycloak:26.1.2`
- Ports: `8070:8070`
- Environment variables:
  - `KC_BOOTSTRAP_ADMIN_USERNAME`
  - `KC_BOOTSTRAP_ADMIN_PASSWORD`
- Healthcheck: Ensures Keycloak is ready before proceeding.

### Terraform
- Image: `hashicorp/terraform:latest`
- Volumes: `./terraform:/terraform`
- Environment variables:
  - `TF_VAR_keycloak_url`
  - `TF_VAR_keycloak_realm`

## NPM Scripts

The `package.json` file includes the following scripts:

- `docker:build`: Build Docker images.
- `docker:up`: Start Docker containers in detached mode.
- `docker:down`: Stop and remove Docker containers.
- `docker:logs`: Tail logs from Docker containers.
- `docker:restart`: Restart the Keycloak container.
- `docker:exec-giacom`: Open a shell in the Keycloak container.
- `docker:clean`: Remove all containers, volumes, and images.
- `docker:fresh`: Clean, build, and start containers from scratch.

Run these scripts using:
```bash
npm run <script-name>
```