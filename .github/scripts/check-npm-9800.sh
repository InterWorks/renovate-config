#!/usr/bin/env bash
# Exit 0 while npm/cli#9800 reproduces; non-zero once it doesn't (or the probe breaks).
set -uo pipefail

# Renovate regenerates lockfiles with --package-lock-only; installing the wasm
# package directly fails the platform check (EBADPLATFORM) before the bug shows.
SPEC="@tailwindcss/oxide@4.1.12"
ISSUE="https://github.com/InterWorks/renovate-config/issues/8"

echo "npm $(npm --version)"
dir=$(mktemp -d)
cd "$dir"
npm init -y >/dev/null
echo "allow-remote=none" > .npmrc

output=$(npm install --package-lock-only --no-audit --no-fund "$SPEC" 2>&1)
status=$?
echo "$output"

if [ "$status" -ne 0 ] && grep -q "EALLOWREMOTE" <<<"$output"; then
  echo "npm/cli#9800 still reproduces; the allow-remote=all workaround is still needed."
  exit 0
elif [ "$status" -eq 0 ]; then
  echo "::error::npm/cli#9800 no longer reproduces on npm $(npm --version)."
  echo "::error::Before removing the workaround, confirm Renovate's hosted runner uses an npm with the fix. See $ISSUE"
  exit 1
else
  echo "::error::Probe failed for a reason other than EALLOWREMOTE (exit $status); this says nothing about the bug. See output above."
  exit 2
fi
