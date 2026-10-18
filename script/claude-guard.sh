#!/usr/bin/env bash
set -euo pipefail

# Claude Code PreToolUse hook for the Bash tool.
#
# Reads the hook payload Claude Code sends on stdin
# (https://code.claude.com/docs/en/hooks), pulls out tool_input.command,
# and exits 2 with a one-line reason on stderr to block the commands
# CLAUDE.md says the maintainer must run instead. Exit 0 allows the
# command through to the normal permission flow.
#
# Detection is regex matching on the raw command string, not a shell
# parser. It still matches inside env-var prefixes, sudo, absolute paths,
# git -C, bash -c wrappers, subshells and &&/; chains, because those forms
# still contain the words looked for. Real obfuscation (quote-splitting,
# base64 and eval) defeats it; script/test-hooks.sh lists those as known
# gaps. It over-blocks some commands that merely mention a blocked phrase,
# such as a commit message naming a secrets file; write such text with the
# file tools instead.
#
# Patterns live in guard_check() so script/test-hooks.sh can source this
# file and exercise the same logic the hook runs.

GUARD_GIT_PUSH='\bgit\b.*\bpush\b'
GUARD_FORCE_FLAG='--force|(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$)'
GUARD_PLUS_REFSPEC='(^|[[:space:]])\+[^[:space:]]'
GUARD_TAG_PUSH='--tags|--follow-tags|refs/tags/'
GUARD_ALL_BRANCHES='--all|--mirror'
GUARD_MAIN_REF="(^|[[:space:]:\"'])(refs/heads/)?(main|master)([[:space:]\"';&|)]|$)"
GUARD_GIT_TAG='\bgit\b.*\btag\b'
GUARD_LIST_FLAG='(^|[[:space:]])(-l|--list)([[:space:]]|$)'
GUARD_NO_VERIFY='--no-verify'
GUARD_KAMAL='\bkamal\b'
GUARD_KAMAL_READ_ONLY='\bkamal\b[[:space:]]+(version|help|--version|--help)([[:space:]]|$)'
GUARD_SYSTEMCTL='\bsystemctl\b.*\b(start|stop|restart|reload|try-restart|reload-or-restart|enable|disable|mask|unmask|daemon-reload|edit|link|kill)\b'
GUARD_TAILSCALE='\btailscale\b[[:space:]]+(serve|funnel)\b'
GUARD_TAILSCALE_STATUS='\btailscale\b[[:space:]]+(serve|funnel)[[:space:]]+status\b'
GUARD_GEM_PUSH='\bgem\b[[:space:]]+push\b|\brake\b.*\brelease\b'
GUARD_GH_REPO='\bgh\b[[:space:]]+repo[[:space:]]+(create|delete|archive)\b'
GUARD_GH_VISIBILITY='\bgh\b[[:space:]]+repo[[:space:]]+edit\b.*--visibility\b'
GUARD_GH_RELEASE='\bgh\b[[:space:]]+release[[:space:]]+create\b'
GUARD_GH_MERGE='\bgh\b[[:space:]]+pr[[:space:]]+merge\b'
GUARD_CREDENTIALS='\bcredentials:(show|edit)\b'
GUARD_SECRET_FILES='master\.key|credentials/[^[:space:]]*\.key|\.kamal/secrets|(^|[[:space:]/"'"'"'])\.env'

# push_args CMD
# Prints the positional arguments (remote, refspecs) of the first git push
# in CMD, one per line, stopping at the end of that command.
push_args() {
  grep -oE -- '\bpush\b[^;&|)]*' <<<"$1" | head -n 1 | tr -d "\"'" \
    | tr -s '[:space:]' '\n' | tail -n +2 | grep -vE '^(-|$)' || true
}

# guard_check CMD
# Prints a one-line reason and returns 1 if CMD should be blocked;
# returns 0 (silent) if it is allowed.
guard_check() {
  local cmd="$1"

  if grep -qE -- "$GUARD_GIT_PUSH" <<<"$cmd"; then
    # A force flag or a "+" refspec rewrites remote history.
    if grep -qE -- "$GUARD_FORCE_FLAG" <<<"$cmd" || grep -qE -- "$GUARD_PLUS_REFSPEC" <<<"$cmd"; then
      echo "blocked: force-push; the maintainer does this"
      return 1
    fi

    if grep -qE -- "$GUARD_TAG_PUSH" <<<"$cmd"; then
      echo "blocked: pushing tags publishes a release; the maintainer does this"
      return 1
    fi

    if grep -qE -- "$GUARD_ALL_BRANCHES|$GUARD_MAIN_REF" <<<"$cmd"; then
      echo "blocked: pushing to main; the maintainer merges"
      return 1
    fi

    # Without a remote and a branch named, or with HEAD as the branch, git
    # pushes the current branch, which may be main.
    if [ "$(push_args "$cmd" | wc -l)" -lt 2 ] || push_args "$cmd" | grep -qxE 'HEAD|@'; then
      echo "blocked: git push without a named branch; name the issue branch"
      return 1
    fi
  fi

  if grep -qF -- "$GUARD_NO_VERIFY" <<<"$cmd"; then
    echo "blocked: --no-verify bypasses hooks"
    return 1
  fi

  # git tag, unless it is a listing (-l / --list).
  if grep -qE -- "$GUARD_GIT_TAG" <<<"$cmd" && ! grep -qE -- "$GUARD_LIST_FLAG" <<<"$cmd"; then
    echo "blocked: git tag creates a release tag; the maintainer does this"
    return 1
  fi

  # Most Kamal commands touch a server or read secrets, so every one is
  # blocked except printing the version or help.
  if grep -qE -- "$GUARD_KAMAL" <<<"$cmd" && ! grep -qE -- "$GUARD_KAMAL_READ_ONLY" <<<"$cmd"; then
    echo "blocked: kamal; the maintainer deploys"
    return 1
  fi

  # The app is deployed as a systemd unit behind tailscale serve, so
  # changing either is deploying or changing who can reach it.
  if grep -qE -- "$GUARD_SYSTEMCTL" <<<"$cmd"; then
    echo "blocked: systemctl changes a running service; the maintainer deploys"
    return 1
  fi

  if grep -qE -- "$GUARD_TAILSCALE" <<<"$cmd" && ! grep -qE -- "$GUARD_TAILSCALE_STATUS" <<<"$cmd"; then
    echo "blocked: tailscale serve and funnel change who can reach the app; the maintainer does this"
    return 1
  fi

  if grep -qE -- "$GUARD_GEM_PUSH" <<<"$cmd"; then
    echo "blocked: gem publishing; the maintainer publishes"
    return 1
  fi

  if grep -qE -- "$GUARD_GH_REPO" <<<"$cmd"; then
    echo "blocked: creating, deleting or archiving a repository; the maintainer does this"
    return 1
  fi

  if grep -qE -- "$GUARD_GH_VISIBILITY" <<<"$cmd"; then
    echo "blocked: gh repo edit --visibility changes visibility; the maintainer does this"
    return 1
  fi

  if grep -qE -- "$GUARD_GH_RELEASE" <<<"$cmd"; then
    echo "blocked: gh release create tags a release; the maintainer does this"
    return 1
  fi

  if grep -qE -- "$GUARD_GH_MERGE" <<<"$cmd"; then
    echo "blocked: gh pr merge; the maintainer merges"
    return 1
  fi

  if grep -qE -- "$GUARD_CREDENTIALS" <<<"$cmd"; then
    echo "blocked: credentials:show and credentials:edit expose secrets"
    return 1
  fi

  if grep -qE -- "$GUARD_SECRET_FILES" <<<"$cmd"; then
    echo "blocked: the command names a secrets file; ask the maintainer"
    return 1
  fi

  return 0
}

# Only run as a hook when executed directly, not when sourced by the test.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  payload="$(cat)"

  # Without jq the command cannot be read reliably, so fail closed.
  if ! command -v jq >/dev/null 2>&1; then
    echo "blocked: the guard needs jq to read the command; install jq" >&2
    exit 2
  fi
  command_str="$(jq -r '.tool_input.command // ""' <<<"$payload")"

  if [ -z "$command_str" ]; then
    exit 0
  fi

  if ! reason="$(guard_check "$command_str")"; then
    echo "$reason" >&2
    exit 2
  fi

  exit 0
fi
