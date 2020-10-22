#!/usr/bin/env bash
set -euo pipefail
set -x

ssh-keyscan github.com >> ${HOME}/.ssh/known_hosts

git config --global user.name \
 "Cole Botling"

git config --global user.email \
 "cole.e.helbling+bot@outlook.com"
