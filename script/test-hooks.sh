#!/usr/bin/env bash
set -euo pipefail

# Regression test for script/claude-guard.sh. Sources the guard's
# guard_check() function (does not copy its patterns) and runs it against
# three lists:
#   must_block  - commands the guard must refuse
#   must_allow  - commands the guard must let through
#   known_gaps  - commands that should be blocked but the current regex
#                 does not catch; asserted as "currently allowed" so a
#                 future fix shows up here as a test change, not a silent
#                 behaviour change.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/claude-guard.sh"

fail=0

must_block=(
  'git push origin main'
  'git push -u origin main'
  'git push origin HEAD:main'
  'git push origin 4/feed-refresh:refs/heads/main'
  'git push origin master'
  'git push'
  'git push origin'
  'git push -u origin'
  'git push origin HEAD'
  'git push --all origin'
  'git push --force origin 4/feed-refresh'
  'git push --force-with-lease origin 4/feed-refresh'
  'git push -f origin 4/feed-refresh'
  'git push origin +4/feed-refresh'
  'git push --tags'
  'git push origin v0.1.0 --follow-tags'
  'GIT_SSH_COMMAND=ssh git push origin main'
  'sudo git push origin main'
  '/usr/bin/git push origin main'
  'git -C /tmp/repo push origin main'
  'bash -c "git push origin main"'
  '(git push origin main)'
  'echo done && git push origin main'
  'echo done; git push'
  'git commit --no-verify -m wip'
  'git tag v0.1.0'
  'git tag -a v0.1.0 -m "release"'
  'kamal deploy'
  'bin/kamal setup'
  'bundle exec kamal app exec "bin/rails console"'
  'sudo systemctl restart hearken'
  'systemctl --user enable --now hearken.service'
  'systemctl daemon-reload'
  'tailscale serve --bg --https=8451 http://localhost:3018'
  'sudo tailscale funnel 443 on'
  'gem push hearken-0.1.0.gem'
  'bundle exec rake release'
  'gh repo create biancapower/other --public'
  'gh repo delete biancapower/hearken --yes'
  'gh repo edit biancapower/hearken --visibility private'
  'gh release create v0.1.0'
  'gh pr merge 12 --merge'
  'bin/rails credentials:show'
  'EDITOR=vim bin/rails credentials:edit'
  'cat config/master.key'
  'cat config/credentials/production.key'
  'cat .kamal/secrets'
  'cat .env'
  'grep TOKEN ./.env.production'
  # Documented over-block: a commit message that mentions pushing.
  "git commit -m 'Explain why we push later'"
  # Documented over-block: any force-style short flag elsewhere in a chain.
  'rm -rf tmp/cache && git push origin 4/feed-refresh'
  # Documented over-block: any mention of a secrets file, even a search.
  'grep -rn master.key config'
)

must_allow=(
  'git status'
  'git commit -m "Add the episode model"'
  'git log --oneline -5'
  'git diff origin/main...HEAD'
  'git fetch origin main'
  'git push -u origin 4/feed-refresh'
  'git push origin 4/feed-refresh'
  'git push origin HEAD:4/feed-refresh'
  'git push origin 12/main-menu'
  'git tag --list'
  'git tag -l'
  'bin/ci'
  'bin/rails db:prepare'
  'bin/rails generate model Episode guid:string'
  'bundle exec rspec spec/models/episode_spec.rb'
  'bin/kamal version'
  'kamal help'
  'systemctl status hearken'
  'journalctl -u hearken -n 50'
  'tailscale status'
  'tailscale serve status'
  'gem install rails -v 8.1.4'
  'gh repo view biancapower/hearken'
  'gh pr create --title x --body y'
  'gh pr checks --watch'
  'gh issue create --title x --body y'
  'cat config/environment.rb'
  'ls config/credentials'
)

known_gaps=(
  # Quote-splitting: the shell removes the empty quotes and runs a real
  # push, but the raw string never contains the word "push".
  "git pu''sh origin main"
  # Base64 and eval: the command never appears as plaintext.
  'eval "$(base64 -d <<< Z2l0IHB1c2ggb3JpZ2luIG1haW4=)"'
  # A branch name held in a variable hides that it is main.
  'b=main; git push origin $b'
  # Moving a branch through the GitHub API is not a git push.
  'gh api -X PATCH repos/o/r/git/refs/heads/main -f sha=abc'
  # Reading a secrets file through a variable hides its name.
  'f=config/mas; cat ${f}ter.key'
)

check_list() {
  local label="$1" expect="$2"
  shift 2
  local cmd result
  for cmd in "$@"; do
    if guard_check "$cmd" >/dev/null; then
      result=allow
    else
      result=block
    fi
    if [ "$result" != "$expect" ]; then
      echo "FAIL [$label] expected $expect, got $result: $cmd"
      fail=$((fail + 1))
    fi
  done
}

check_list "must_block" block "${must_block[@]}"
check_list "must_allow" allow "${must_allow[@]}"
check_list "known_gaps" allow "${known_gaps[@]}"

# The hook entrypoint, end to end, with the JSON payload Claude Code sends.
run_hook() {
  local cmd="$1" path="$2" status=0
  jq -cn --arg c "$cmd" '{tool_name: "Bash", tool_input: {command: $c}}' \
    | PATH="$path" "$SCRIPT_DIR/claude-guard.sh" >/dev/null 2>&1 || status=$?
  echo "$status"
}

check_hook() {
  local label="$1" expect="$2" cmd="$3" path="$4" got
  got="$(run_hook "$cmd" "$path")"
  if [ "$got" != "$expect" ]; then
    echo "FAIL [hook:$label] expected exit $expect, got $got: $cmd"
    fail=$((fail + 1))
  fi
}

# A PATH holding the tools the guard needs, except jq.
no_jq_bin="$(mktemp -d)"
trap 'rm -rf "$no_jq_bin"' EXIT
for tool in bash cat grep head tr tail wc; do
  ln -s "$(command -v "$tool")" "$no_jq_bin/$tool"
done

check_hook "escaped quotes" 2 'bash -c "git push origin main"' "$PATH"
check_hook "routine" 0 'git status' "$PATH"
check_hook "no jq fails closed" 2 'git status' "$no_jq_bin"
hook_cases=3

total=$(( ${#must_block[@]} + ${#must_allow[@]} + ${#known_gaps[@]} + hook_cases ))

if [ "$fail" -eq 0 ]; then
  echo "test-hooks: PASS - ${total} cases (${#must_block[@]} block, ${#must_allow[@]} allow, ${#known_gaps[@]} known-gap, ${hook_cases} hook)"
  exit 0
else
  echo "test-hooks: FAIL - ${fail}/${total} cases wrong"
  exit 1
fi
