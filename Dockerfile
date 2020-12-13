ARG PYTHON_VERSION=3.8
FROM rclone/rclone:1.53.3 AS rclone

FROM python:$PYTHON_VERSION AS build

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN set -ex && \
    apt-get update && \
    pip install --upgrade pip && \
    # Install poetry, curl (to fetch poetry installation script), and pillow building dependencies
    apt-get install -y --no-install-recommends \
        curl \
        zlib1g-dev \
        gcc \
        libc-dev \
        libxml2-dev \
        libffi-dev \
        libxslt-dev \
        libssl-dev \
    && \
    # && curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python \
    # ↑より↓の方が容量が小さい
    pip install poetry && \
    export PATH=$PATH:/root/.poetry/bin && \
    export LIBRARY_PATH=/lib:/usr/lib \
    && \
    # Don't use virtualenv, install packages directly on the container
    poetry config virtualenvs.create false && \
    poetry install && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ここからは実行用コンテナの準備
FROM python:$PYTHON_VERSION-slim AS runtime

COPY --from=rclone /usr/local/bin/rclone /usr/local/bin/rclone
COPY --from=build /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages

RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        make \
        openssh-client \
        git \
        libjpeg-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH "$PATH:/root/.poetry/bin"
ENV DOC_DIR "/doc"

WORKDIR /app
COPY app.py Makefile docker-entrypoint.sh ./

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["bash"]
