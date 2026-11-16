---
description: "Use when creating or editing Dockerfiles in this workspace. Follow the project's Dockerfile stage, Python setup, virtualenv, and runtime directive conventions."
applyTo: "**/Dockerfile"
---

# Dockerfile Conventions

## Stage and section layout

- Keep stages purpose-specific and separate stages with a blank line.
- Separate logical sections within a stage with blank lines. Keep related instructions together without blank lines inside a section.
- Put stage-specific `ENV` instructions near the top of the stage, after its `ARG` declarations and before `RUN`, `COPY`, or `WORKDIR` instructions.
- Declare defaults for runtime environment variables with `ENV` and reference those variables directly in `CMD` instead of repeating fallback values there.
- Use the declared `PORT` environment variable in `EXPOSE` rather than repeating the port literal.
- Keep each `WORKDIR` in its own section with blank lines before and after it; place it before the first instruction that relies on that directory.
- Group Python-related instructions together, including `pip`/Poetry installation, Python venv creation, project metadata and lockfile copies, and Poetry dependency installation. Keep these `RUN` and `COPY` instructions contiguous without unrelated instructions between them.
- Separate Python setup from runtime directives with a blank line.
- Keep runtime directives such as `USER`, `EXPOSE`, and `CMD` together at the end of the stage, without blank lines between them.
- Combine related environment variables in one multiline `ENV` instruction.

## Poetry and virtual environments

- Pin the Poetry version through one shared build argument rather than repeating the version in stages.
- Copy both `pyproject.toml` and `poetry.lock` before running `poetry install`.
- Use the same explicit virtual-environment approach in development and production: create the venv with `python -m venv`, set `POETRY_VIRTUALENVS_CREATE=false`, and install dependencies into it.
- Keep the venv outside the project directory (currently `/opt/venv`) so it does not enter project mounts.
- Define the venv path once and reuse it across stages. Copy that venv into the production runtime image rather than rebuilding it there.
- Install dependencies during image builds as root; switch to an unprivileged user for container runtime. Do not make the venv writable by the runtime user unless necessary.
- Keep files and directories root-owned by default; change ownership only when the runtime user needs write access.
- Avoid changing ownership of `/app` solely for Poetry; the venv and Poetry caches belong outside the project directory.

## Runtime image

- Keep development and test stages separate from the production runtime image.
- Keep the production runtime image focused on the application and its installed runtime environment; do not include Poetry or test-only dependencies.
- Run the application as an unprivileged user.
