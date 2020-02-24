#!/bin/sh
mkdir -p ${DOC_DIR}/.kakomon-manager-legacy \
    && cp -r /app/* ${DOC_DIR}/.kakomon-manager-legacy \
    && cd ${DOC_DIR}/.kakomon-manager-legacy \
    && eval "$@"

rm -rf ${DOC_DIR}/.kakomon-manager-legacy/*