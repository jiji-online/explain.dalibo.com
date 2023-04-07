FROM docker.io/python:3.11-bullseye AS poetry
ARG VENV=/opt/venv

RUN \
        apt update && \
        useradd -m user && \
        chown user /opt

WORKDIR /opt/src
USER user

ENV POETRY_VENV=/opt/poetry
ENV POETRY_VIRTUALENVS_CREATE=False

RUN \
	python3 -m venv "$POETRY_VENV" && \
    "$POETRY_VENV/bin/pip" install --upgrade pip && \
    "$POETRY_VENV/bin/pip" install 'poetry' && \
    python3 -m venv "$VENV" && \
    "$VENV/bin/pip" install --upgrade pip

ENV PATH="$VENV/bin:$PATH"
ENV VIRTUAL_ENV="$VENV"

ENTRYPOINT ["/opt/poetry/bin/poetry"]

FROM poetry AS build

COPY poetry.lock pyproject.toml ./

RUN "$POETRY_VENV/bin/poetry" install

FROM docker.io/python:3.11-bullseye
ARG VENV=/opt/venv

ENV PATH="$VENV/bin:$PATH"
ENV PORT=8000
EXPOSE 8000

RUN \
        useradd -ms /bin/bash user && \
        mkdir -p /opt/src && \
        chown -R user /opt

WORKDIR /opt/src

COPY --chown=user --from=build /opt/venv /opt/venv/
COPY --chown=user . .

CMD ["gunicorn", "app:app"]
