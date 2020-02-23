FROM python:3.7-alpine

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN set -ex \
    && apk update \
    && pip install --upgrade pip \
    # Install dependencies
    && apk --no-cache add make openssh git jpeg-dev \
    # Install poetry, curl (to fetch poetry installation script), and pillow dependencies
    && apk --no-cache --virtual .build-dep add curl zlib-dev gcc linux-headers libc-dev \
    && curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python \
    && source $HOME/.poetry/env \
    && export LIBRARY_PATH=/lib:/usr/lib \
    # Don't use virtualenv, install packages directly on the container
    && poetry config virtualenvs.create false \
    && poetry install \
    && apk del .build-dep

ENV PATH "$PATH:/root/.poetry/bin"
ENV DOC_DIR "/doc"

COPY app.py Makefile ./

CMD make check
