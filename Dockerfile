ARG ROOT_IMAGE=python:3.12-slim

# The following are used to create a non-root user to run the application.
ARG GROUP_ID=10001
ARG USER_ID=10001
ARG GROUP_NAME=app
ARG USER_NAME=app

ARG WORKING_DIR=/app

ARG VENV_PATH=/opt/venv
ARG PYTHON_CACHE_PATH=/tmp/pycache

ARG POETRY_VERSION=2.3.2
# When:
#   .:/app (in compose))
# Reason:
#   Keep Poetry's home-scoped files outside the project bind mount
ARG HOME=/tmp
# When:
#   WORKDIR /app
#   COPY pyproject.toml poetry.lock ./
#   ./src:/app/src (in compose)
# Reason:
#   To have pyproject.toml, poetry.lock and contents of src all available under
#   /app for Poetry to work properly with the source code.
ARG CODE_DIR_NAME=src
ARG TEST_DIR_NAME=tests
ARG PYTHON_PATH=/app/${CODE_DIR_NAME}

ARG PYTEST_CACHE_DIR=/tmp/pytest-cache

ARG MAIN_MODULE=main
ARG APP_MODULE=app
# Using 0.0.0.0 as the default host so that the application is accessible from
# outside the container.
ARG HOST=0.0.0.0
ARG PORT=8080

FROM ${ROOT_IMAGE} AS poetry-lock

ARG WORKING_DIR
ARG POETRY_VERSION
ARG HOME

ENV HOME=${HOME}

WORKDIR ${WORKING_DIR}

RUN pip install --no-cache-dir "poetry==${POETRY_VERSION}"

CMD ["poetry", "lock"]

FROM ${ROOT_IMAGE} AS dev

ARG GROUP_ID
ARG USER_ID
ARG GROUP_NAME
ARG USER_NAME
ARG WORKING_DIR
ARG VENV_PATH
ARG PYTHON_CACHE_PATH
ARG POETRY_VERSION
ARG CODE_DIR_NAME
ARG PYTHON_PATH
ARG MAIN_MODULE
ARG APP_MODULE
ARG HOST
ARG PORT

ENV PYTHONPYCACHEPREFIX=${PYTHON_CACHE_PATH} \
    CODE_DIR_NAME=${CODE_DIR_NAME} \
    MAIN_MODULE=${MAIN_MODULE} \
    APP_MODULE=${APP_MODULE} \
    PYTHONPATH=${PYTHON_PATH} \
    HOST=${HOST} \
    PORT=${PORT} \
    VIRTUAL_ENV=${VENV_PATH} \
    PATH="${VENV_PATH}/bin:${PATH}" \
    POETRY_VIRTUALENVS_CREATE=false

RUN groupadd --gid ${GROUP_ID} ${GROUP_NAME} \
    && useradd --create-home --uid ${USER_ID} --gid ${GROUP_NAME} ${USER_NAME}

RUN mkdir -p "${PYTHON_CACHE_PATH}" \
    && chown ${USER_NAME}:${GROUP_NAME} "${PYTHON_CACHE_PATH}"

WORKDIR ${WORKING_DIR}

RUN pip install --no-cache-dir "poetry==${POETRY_VERSION}"
RUN python -m venv "${VENV_PATH}"
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root

USER ${USER_NAME}
EXPOSE ${PORT}
CMD ["sh", "-c", "exec poetry run uvicorn ${MAIN_MODULE}:${APP_MODULE} --host \"${HOST}\" --port \"${PORT}\" --reload --reload-dir \"${CODE_DIR_NAME}\""]

FROM dev AS test

ARG GROUP_NAME
ARG USER_NAME
ARG CODE_DIR_NAME
ARG TEST_DIR_NAME
ARG PYTEST_CACHE_DIR

ENV TEST_DIR_NAME=${TEST_DIR_NAME} \
    PYTEST_ADDOPTS="-o cache_dir=\"${PYTEST_CACHE_DIR}\""

USER root
RUN mkdir -p "${PYTEST_CACHE_DIR}" \
    && chown "${USER_NAME}:${GROUP_NAME}" "${PYTEST_CACHE_DIR}"

RUN poetry install --only test --no-root

USER ${USER_NAME}
CMD ["sh", "-c", "exec poetry run ptw . --patterns \"${CODE_DIR_NAME}/*.py,${TEST_DIR_NAME}/*.py\" --now -q"]

FROM ${ROOT_IMAGE} AS build

ARG WORKING_DIR
ARG VENV_PATH
ARG POETRY_VERSION

# Source is copied into /app/src; Python must search there to find main.py.
ENV VIRTUAL_ENV=${VENV_PATH} \
    PATH="${VENV_PATH}/bin:${PATH}" \
    POETRY_VIRTUALENVS_CREATE=false

WORKDIR ${WORKING_DIR}

RUN pip install --no-cache-dir "poetry==${POETRY_VERSION}"
RUN python -m venv "${VENV_PATH}"
COPY pyproject.toml poetry.lock ./
RUN poetry install --only main --no-root

FROM ${ROOT_IMAGE} AS production

ARG GROUP_ID
ARG USER_ID
ARG GROUP_NAME
ARG USER_NAME
ARG WORKING_DIR
ARG VENV_PATH
ARG CODE_DIR_NAME
ARG PYTHON_PATH
ARG MAIN_MODULE
ARG APP_MODULE
ARG HOST
ARG PORT

ENV VIRTUAL_ENV=${VENV_PATH} \
    PATH="${VENV_PATH}/bin:${PATH}" \
    PYTHONPATH=${PYTHON_PATH} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MAIN_MODULE=${MAIN_MODULE} \
    APP_MODULE=${APP_MODULE} \
    HOST=${HOST} \
    PORT=${PORT}

RUN groupadd --gid ${GROUP_ID} ${GROUP_NAME} \
    && useradd --create-home --uid ${USER_ID} --gid ${GROUP_NAME} ${USER_NAME}

COPY --from=build ${VENV_PATH} ${VENV_PATH}

WORKDIR ${WORKING_DIR}

COPY ${CODE_DIR_NAME} "./${CODE_DIR_NAME}"

USER ${USER_NAME}
EXPOSE ${PORT}
CMD ["sh", "-c", "exec uvicorn ${MAIN_MODULE}:${APP_MODULE} --host \"${HOST}\" --port \"${PORT}\""]
