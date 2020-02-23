#!/bin/sh
set -e

cp -r /app ${DOC_DIR}/.kakomon-manager-legacy

cd ${DOC_DIR}/.kakomon-manager-legacy
"$@"

rm -rf ${DOC_DIR}/.kakomon-manager-legacy