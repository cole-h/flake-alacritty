#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

set -euo pipefail
set -x

cache="alacritty"

oldversion="$(cat .rev)"
rm -rf ./.ci/commit-message

nix --experimental-features 'nix-command flakes' \
	flake update \
	--update-input nixpkgs \
	--update-input alacritty \
	--update-input naersk

newversion="$(nix --experimental-features 'nix-command flakes' \
	eval '.#inputs.alacritty.rev' --json \
	| jq -r)"
echo "$newversion" > .rev

# remember existing paths
nix --experimental-features 'nix-command' \
	path-info --all | grep -v '\.drv$' > /tmp/store-path-pre-build

outdir="$(mktemp -d)"
nix build \
	--experimental-features 'nix-command flakes' \
	--option "extra-binary-caches" "https://cache.nixos.org https://alacritty.cachix.org" \
	--option "trusted-public-keys" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= alacritty.cachix.org-1:/qirsw0af1Mf5vshRf3mWVuE/kCB6vZn6tYOkd4nWsU=" \
	--option "build-cores" "0" \
	--option "narinfo-cache-negative-ttl" "0" \
	--out-link "${outdir}/result"

nix --experimental-features 'nix-command' path-info -r "${outdir}/result" \
	| cachix push "${cache}"

comm -13 <(sort /tmp/store-path-pre-build) <(nix --experimental-features 'nix-command' path-info --all | grep -v '\.drv$' | sort) \
	| cachix push "${cache}"

if [[ "${newversion}" != "${oldversion}" ]]; then
  commitmsg="alacritty: ${oldversion} -> ${newversion}"
  echo -e "${commitmsg}" > .ci/commit-message
else
  echo "nothing to do, there was no version bump"
fi
