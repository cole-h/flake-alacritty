#!/usr/bin/env bash
set -euo pipefail
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# user-specific
SECRET_NAME="Internet/sr.ht/cole_h/notes"
SECRET_ATTR="token"

# less user-specific
BUILD_HOST="https://builds.sr.ht"
if which passrs ; then
  TOKEN="$(passrs show "${SECRET_NAME}" | grep token | cut -d'=' -f2)"
else
  echo "passrs not on path. Exiting."
  exit 1
fi

DATA="$(mktemp)"
MANIFEST="$(jq -aRs . < "${DIR}/srht-job.yaml")"
echo "{ \"tags\": [ \"flake-alacritty\" ], \"manifest\": ${MANIFEST} }" > "${DATA}"

curl \
  -H "Authorization:token ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "@${DATA}" \
  "${BUILD_HOST}/api/jobs"
