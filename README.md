# GO + DOCKER + DOCKER COMPOSE + MULTI STAGE + MULTI PLATFORM BUILD

This is just a simple ramp-up for Go lang + how to handle multiple builds in go, using docker and exposing the binaries

## Concepts tested here

- Multi Stage Build
- Multi Platform Build
- Docker Compose to run the dev environment
- Exposing/Copying all the binaries to external folder (`./bin`).
- - Note: the `--output=bin` is necessary to do it, because I haven't found a way to do it via `Dockerfile` yet

## How to build

- Run: `docker build . --output=bin --tag 'go-docker'`

## How to Test/Lint

- Run: `docker build --target=lint .`

## How to Run for Dev

- Run: `docker compose up --build -d` (`--build` is optional)
- It will be exposed at port 8080 (defined in `docker-compose.yaml`)

