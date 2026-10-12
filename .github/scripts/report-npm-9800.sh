#!/usr/bin/env bash
# Usage: report-npm-9800.sh <probe exit status>
# Needs GH_TOKEN, GITHUB_REPOSITORY, GITHUB_EVENT_NAME, GITHUB_SERVER_URL, GITHUB_RUN_ID; PR_NUMBER on pull_request.
set -euo pipefail

status=$1
issue=8
marker="<!-- npm-cli-9800-probe -->"
run_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
mentions=$(grep -m1 '^\*' .github/CODEOWNERS | cut -d' ' -f2-)

case "$status" in
  0) headline="npm/cli#9800 still reproduces, so the \`allow-remote=all\` workaround is still needed." ;;
  1) headline="**npm/cli#9800 no longer reproduces on npm 12.** The \`npmrc\`/\`npmrcMerge\` workaround in \`default.json\` may be removable. If Renovate's hosted runner uses an npm release with the fix, remove both keys and the README note (#$issue). If not, replace this check or the workaround with one that matches what Renovate runs." ;;
  *) headline="**The npm/cli#9800 probe failed for a reason other than the bug** (exit $status), so it can't tell whether the workaround is still needed. Check the run log and fix the probe." ;;
esac

echo "$headline" >> "$GITHUB_STEP_SUMMARY"
[ "$status" -ne 0 ] && echo "::warning::$headline"

if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  existing=$(gh api "repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" --paginate \
    --jq ".[] | select(.body | contains(\"$marker\")) | .id" | head -n1)
  if [ "$status" -eq 0 ]; then
    # Only touch the PR if an earlier run left a warning that is now stale.
    [ -n "$existing" ] && gh api -X PATCH "repos/$GITHUB_REPOSITORY/issues/comments/$existing" \
      -f body="$marker"$'\n'"Resolved: $headline ([run]($run_url))" >/dev/null
    exit 0
  fi
  body="$marker"$'\n'"$mentions $headline"$'\n\n'"This check fails, and blocks every PR in this repo, until the workaround is removed or replaced. [Run log]($run_url)"
  if [ -n "$existing" ]; then
    gh api -X PATCH "repos/$GITHUB_REPOSITORY/issues/comments/$existing" -f body="$body" >/dev/null
  else
    gh api "repos/$GITHUB_REPOSITORY/issues/$PR_NUMBER/comments" -f body="$body" >/dev/null
  fi
elif [ "$status" -ne 0 ]; then
  gh api "repos/$GITHUB_REPOSITORY/issues/$issue/comments" \
    -f body="$mentions $headline"$'\n\n'"[Run log]($run_url)" >/dev/null
fi
