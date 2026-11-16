# Project Guidelines

## Convention conflicts

- Before applying a requested change that conflicts with any convention in these instructions or the Dockerfile instructions, warn the developer and explain the conflict and likely impact. Do not silently proceed; ask whether to make the exception and wait for confirmation.
- Treat conventions the developer explicitly agrees to as persistent project guidance and add them to the appropriate instruction file.
- Do not remove, weaken, or otherwise modify an existing convention without the developer's consent.

## Application

- Keep this a small FastAPI application served by Uvicorn; avoid introducing extra frameworks or unnecessary abstractions.
- Choose names that are clear in context: avoid redundant specificity and avoid names so generic that their meaning is unclear.
- Preserve the existing endpoints and response behavior: `GET /`, `GET /health`, and JSON 404 responses.
- Use `HOST` and `PORT` for Uvicorn host and port settings; avoid Uvicorn-prefixed environment variable names.
- In the dev Compose service, use `PORT` for the published host port and keep the container port fixed at `8080`.
- Load `env.dev` with `docker compose --env-file env.dev` for development commands so its port values are available for Compose interpolation.
- Keep application code under `src/` and tests under `tests/`.
- Use Poetry for dependency management. Commit `poetry.lock` and keep runtime and test dependencies in their appropriate groups.

## Docker and Compose

- Use Docker Compose for local development and testing. Invoke the intended service explicitly; do not add Compose profiles.
- Keep separate `dev`, `test`, and `poetry-lock` services/targets. The dev service runs Uvicorn with reload; the test service runs the test watcher by default, while CI overrides it for one-shot pytest.
- List the `poetry-lock` service before `dev` and `test` in `compose.yaml`.
- Keep Python bytecode and pytest caches in named volumes under `/tmp`, outside bind-mounted source.
- Keep service-specific environment files for actual runtime settings. Put fixed container configuration in the Dockerfile when it is shared by the image rather than duplicating it across env files.
- Generate or update `poetry.lock` through `./scripts/gen-poetry-lock`, which runs Poetry in Docker and preserves host file ownership. Do not replace it with a local Poetry command.
- Follow the detailed stage, environment-variable, virtualenv, and instruction-grouping rules in [dockerfile.instructions.md](./instructions/dockerfile.instructions.md).

## Production and CI

- Deploy the production Docker image to container hosting providers; do not restore the wheel-export or external `pip install` workflow.
- The production image must run as an unprivileged user, listen on `0.0.0.0`, and use the provider-supplied `PORT` environment variable (default `8080`).
- CI runs tests and builds the production image for validation. It does not publish images, push to a registry, or create wheel-based releases unless that policy is explicitly changed.
- Keep deployment credentials and real production environment files out of source control; `env.prod.example` is only a template.

## Scope and documentation

- Do not add IDE-specific environment or Dev Container configuration; IDE setup is managed separately.
- Prefer straightforward, readable configuration and avoid adding options, profiles, services, or files without a project need.
- Add concise comments to Compose and other configuration files when useful, explaining why non-obvious settings exist and what problem they prevent; avoid comments that only restate the setting.
- Keep each configuration comment specific to one setting or line; do not combine explanations for multiple lines in a single comment.
- Update the README when changing project workflows, commands, or deployment behavior.
