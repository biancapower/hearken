# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Guard: Claude hook", "script/test-hooks.sh"

  step "Tests: no focused or skipped examples",
    "! grep -rnE '^[[:space:]]*(fit|fdescribe|fcontext|fspecify|fexample|xit|xdescribe|xcontext|xspecify|xexample|skip)\\b|focus: true' spec"
  step "Tests: prepare database and assets", "env RAILS_ENV=test bin/rails db:prepare tailwindcss:build"
  step "Tests: RSpec", "bundle exec rspec"


  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
