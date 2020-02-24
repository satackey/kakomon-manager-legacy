FROM satackey/skicka AS skicka

FROM python:3.7-alpine

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN set -ex \
    && apk update \
    && pip install --upgrade pip \
    # Install dependencies
    && apk --no-cache add make openssh-client git jpeg-dev \
    # Install poetry, curl (to fetch poetry installation script), and pillow building dependencies
    && apk --no-cache --virtual .build-dep add curl zlib-dev gcc linux-headers libc-dev libffi-dev openssl-dev \
    # && curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python \
    # ↑より↓の方が容量が小さい
    && pip install poetry \
    && export PATH=$PATH:/root/.poetry/bin \
    && export LIBRARY_PATH=/lib:/usr/lib \
    # Don't use virtualenv, install packages directly on the container
    && poetry config virtualenvs.create false \
    && poetry install \
    && rm -rf ~/.cache \
    && apk del .build-dep

ENV PATH "$PATH:/root/.poetry/bin"
ENV DOC_DIR "/doc"

COPY --from=skicka /usr/local/bin/skicka /usr/local/bin/skicka
RUN skicka init

COPY app.py Makefile docker-entrypoint.sh ./

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["ash"]
