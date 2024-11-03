#!/bin/sh
set -e

git config --global --add safe.directory /riji
exec riji "$@"
