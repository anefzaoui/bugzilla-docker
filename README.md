# Bugzilla Docker Setup

This repository provides a Docker-based setup for running Bugzilla using Ubuntu 22.04, Apache2, and MySQL 5.7.

## Prerequisites

- Docker: Install [Docker](https://docs.docker.com/get-docker/) on your system.
- Docker Compose: Install [Docker Compose](https://docs.docker.com/compose/install/) on your system.

## Files

- `Dockerfile`: Defines the Docker image for the Bugzilla application.
- `docker-compose.yml`: Docker Compose configuration to run Bugzilla and MySQL 5.7 containers.
- `checksetup_answers.txt`: Contains the email, real name, and password for the Bugzilla admin account.

## Setup

1. Clone the repository:

```
git clone https://github.com/yourusername/bugzilla-docker.git
cd bugzilla-docker
```

Replace `yourusername` with your GitHub username and `bugzilla-docker` with your repository name, if different.

2. Update the `checksetup_answers.txt` file with your email, real name, and password for the Bugzilla admin account.

3. Build the Bugzilla Docker image:

`docker build -t bugzilla-image .`

4. Start the Bugzilla and MySQL services:
   `docker-compose up -d`

5. Access the Bugzilla web interface at http://localhost:8099.

6. Log in with the email and password provided in the `checksetup_answers.txt` file to start using Bugzilla.

## Troubleshooting

If you encounter issues, check the logs of the running containers:

`docker-compose logs`

To stop and remove all containers, networks, and volumes defined in `docker-compose.yml`, run:

`docker-compose down -v`

## Security Considerations

For a production setup, ensure the following:

1. Do not include sensitive information like passwords or secret keys in the Dockerfile or `checksetup_answers.txt`. Use environment variables or Docker secrets.

2. Use HTTPS to secure the communication between the client and the Bugzilla server. You can set up a reverse proxy with a web server like Nginx to enable SSL.

3. Regularly update the base image and packages to get the latest security patches.

4. Protect the Docker daemon with TLS and follow the [Docker security best practices](https://docs.docker.com/engine/security/).
