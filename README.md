# Simple HTTP Server

A minimal FastAPI application served by Uvicorn.

## Run locally

Requires Python 3.10+ and Poetry 2.x.

```sh
poetry install
poetry run uvicorn main:app --host "${HOST:-0.0.0.0}" --port "${PORT:-8080}"
```

The server listens on `0.0.0.0:8080` by default. Configure it with `HOST` and
`PORT` environment variables. Available endpoints:

- `GET /` — `{"message":"Hello, world!"}`
- `GET /health` — `{"status":"ok"}`
- Other paths return a JSON 404 response.

Run the test suite locally with:

```sh
poetry run pytest
```

## Develop and test with Docker Compose

The development server uses its Dockerfile defaults, runs on Uvicorn with
reload enabled, and restarts when Python files in `src/` change. Load `env.dev`
for Compose port mapping. The existing image is used by default; pass `--build`
to remove the dev container and image, then rebuild without cached layers:

```sh
./scripts/run-dev
./scripts/run-dev --build
```

Run the test watcher in its dedicated container. It runs pytest immediately,
watches Python files under `src/` and `tests/`, and reruns tests when they
change. Compose reuses the service container between runs. By default, the
existing image is used; pass `--build` to remove the test container and image,
then rebuild without using cached build layers:

```sh
./scripts/run-tests
./scripts/run-tests --build
```

The dev, test, and production containers run as the unprivileged `app` user.
Python bytecode and pytest caches are stored in separate named volumes under
`/tmp`, outside the mounted project directory. Stop the test watcher with
`Ctrl+C`.

The dev service listens on container port `8080`. Set `PORT` in `env.dev` to
choose the published host port; shell values override it:

```sh
PORT=9000 ./scripts/run-dev
```

### Environment variables

Use `--env-file env.dev` for development port interpolation. Test settings are
defined in the Dockerfile. The `poetry-lock` stage keeps its `HOME` separate
from the project bind mount so Poetry's home-scoped files do not appear in the
host project. The production image uses `PORT` at runtime; `env.prod.example`
is a template for running it locally. The variables used by Compose and
production are:

| Variable | File(s) | Use |
| --- | --- | --- |
| `PORT` | `env.dev`, `env.prod.example` | Published host port in development; Uvicorn listen port in production. Defaults to `8080`. |

Generate or update `poetry.lock` in Docker, preserving your local file
ownership:

```sh
./scripts/gen-poetry-lock
```

The script supplies your host user and group IDs to Compose so the generated
lockfile is owned by your local user.

## Build and run the production image

Build the production image:

```sh
docker build --tag simple-http-server:local .
```

Run it locally:

```sh
docker run --rm -p 8080:8080 --env-file env.prod.example simple-http-server:local
```

The image listens on `0.0.0.0` and uses the `PORT` environment variable
(default `8080`), as expected by many container hosting providers. To deploy,
push the image to a container registry accessible to your provider and configure
the provider to run it. CI builds the production image but does not publish it.

## CI/CD

GitHub Actions runs the Compose test service and builds the production Docker
image on pushes and pull requests to `main` or `master`, and on version tags.
The image is built for validation but is not published to a registry.
