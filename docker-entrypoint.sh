#!/bin/bash
mkdir -p ${DOC_DIR}/.kakomon-manager-legacy \
    && cp -r /app/* ${DOC_DIR}/.kakomon-manager-legacy \
    && cd ${DOC_DIR}/.kakomon-manager-legacy \
    && eval "$@"
EXIT_CODE=$?

rm -rf ${DOC_DIR}/.kakomon-manager-legacy/*
exit $EXIT_CODE