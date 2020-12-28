#!/usr/bin/env bash
set -euo pipefail
set -x
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# user-specific
SECRET_NAME="Internet/sr.ht/cole_h/notes"
SECRET_ATTR="token"

# less user-specific
BUILD_HOST="https://builds.sr.ht"
if which passrs >/dev/null 2>&1; then
	set +x
	TOKEN="$(passrs show "${SECRET_NAME}" | grep ${SECRET_ATTR} | cut -d'=' -f2)"
	set -x
else
	echo "passrs not on path. Exiting."
	exit 1
fi

DATA="$(mktemp)"
MANIFEST="$(jq -aRs . < "${DIR}/srht-job.yaml")"
echo "{ \"tags\": [ \"flake-alacritty\" ], \"manifest\": ${MANIFEST} }" > "${DATA}"

set +x
curl \
	-H "Authorization:token ${TOKEN}" \
	-H "Content-Type: application/json" \
	-d "@${DATA}" \
	"${BUILD_HOST}/api/jobs"
set -x
