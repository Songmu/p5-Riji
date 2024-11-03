#!/bin/sh
set -e

# to avoid the error: "fatal: detected dubious ownership in repository"
git config --global --add safe.directory /riji
exec riji "$@"
