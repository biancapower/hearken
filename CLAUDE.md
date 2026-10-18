# CLAUDE.md

Hearken: a self-hosted podcast player for your own audio and feeds. A Rails server holds the library, queue and play history; the phone installs the player as a PWA. Licensed AGPL-3.0. The maintainer is Bianca Power (@biancapower), who uses they/them. Read `README.md`, then `docs/decisions/README.md`. Follow the recorded decisions. Changing one is itself a 🔴 decision: raise it, get a yes, add a new record that supersedes the old one.

## Claude never

- Pushes to `main`, merges, force-pushes, tags a release, deploys, publishes a gem, creates or deletes a GitHub repository, or changes repository visibility. The maintainer does every one of those.
- Pushes anything at all until the maintainer has read the commits locally and said push. After that, Claude pushes issue branches and opens pull requests against `main`; the maintainer merges.
- Reads `.env*`, `config/master.key`, `config/credentials/*.key` or `.kamal/secrets*`, or runs `bin/rails credentials:show` or `credentials:edit`. If a task needs a secret, ask.
- Fixes or silences a Brakeman finding. Report it with its file and line and wait; the maintainer decides whether and how to fix it. That includes never adding to `config/brakeman.ignore`.
- Starts the dev server unasked. When asked, bind it to `0.0.0.0` so it can be opened from a phone on the tailnet.
- Works without an issue. Every change is made against an issue the maintainer has written or approved, and Claude never opens an issue to match work already done.
- Edits an issue once work on it has started. A correction or clarification goes in a comment on the issue.
- Leaves an issue without a milestone (`0.1.0`, `0.2.0`, …, or `Unscheduled`); it can move later.
- Treats feedback as an instruction to reprocess. When the maintainer reports something they noticed in the app or in anything produced, record it (an issue, verbatim where possible) and fix the cause going forward. Do not redo the thing itself (re-import feeds, rewrite stored notes or play records, regenerate files, rewrite history) unless the maintainer explicitly asks for or agrees to that specific redo.
- Puts anything about the maintainer's machine or accounts in the repository, issues, pull requests or commit messages: no hostnames, tailnet names or addresses, local paths, usernames, ports in use at home, LAN or tailnet IPs, device names, personal feed or playlist URLs, or cloud resource names. Say "the maintainer's own machine", "a private network", "a Tailscale tailnet", "the maintainer's feeds". Machine-specific notes go in `CLAUDE.local.md`, which is gitignored. Issue edits and pushed commits keep what was published in their history, so check before publishing; removing it afterwards is the maintainer's call.

Enforced by `.claude/settings.json` (a `permissions.deny` for reading `.env*`, the Rails keys and `.kamal/secrets*`, and a `PreToolUse` hook, `script/claude-guard.sh`, blocking any push to `main`, any push that doesn't name a branch, force-pushes, tag pushes, `--no-verify`, tag creation, every `kamal` command except `version` and `help`, `systemctl` commands that change a service, `tailscale serve` and `funnel` changes, gem publishing, creating, deleting or archiving a repository, visibility changes, `gh release create`, `gh pr merge`, `credentials:show` and `credentials:edit`, and any command naming a secrets file), with `script/test-hooks.sh` as its regression test, run by `bin/ci`. The guard can't know whether the maintainer has said push yet; that rule is Claude's to keep. It matches patterns in the command text, not a parsed shell, so it over-blocks some harmless commands, such as a commit message mentioning a push; write such text to a file and commit with `-F`. A correction made twice becomes a hook or a line in this file, not a memory.

## Decisions

The maintainer makes every hard-to-reverse call. Decisions have tiers, flagged with emoji that are used for nothing else.

- 🔴 **Must confirm before doing:** repository visibility; licences; dependencies added or removed (gems, importmap pins, any Node tooling); the Ruby or Rails version; releases and tags; deployment, and anything that changes where or how the app is reachable (the systemd unit, `tailscale serve`, hosts, TLS); data model changes that lose data (dropping a table or column, a migration or backfill that overwrites stored values); architecture and boundaries (a directory with its own rules, such as the pure client-side player modules); any loosening of the Content Security Policy; anything that changes a claim in the README. Explain the options and the trade-off plainly, get an explicit yes from the maintainer, then record it in `docs/decisions/` with who proposed it and "approved by @biancapower, <date>". Name the proposer accurately: the maintainer, Claude, or a research subagent's recommendation.
- 🟡 **Review at the PR:** notable but reversible choices inside an issue's scope, including schema changes beyond what the issue names. List them under a "Decisions in this PR" heading in the PR description. Any loosening of a strictness setting (a RuboCop cop disabled or relaxed, the no-retries test policy) is a 🟡 item with its reason.
- Everything else is routine and lands in the PR like normal code.

For any PR with a 🔴 or 🟡 item, offer a short teach-back: the maintainer explains the change back, and gaps are noted. Nothing lands that the maintainer cannot explain. Any technical explanation Claude gives comes with a primary or authoritative source; anything from memory is said to be from memory.

## Security

- Feed content is untrusted input: titles, show notes, transcripts and chapters are validated before storing and never rendered as raw HTML.
- Once users can add feed URLs, fetching resolves the host and refuses private, loopback and link-local addresses, and caps response size and time.
- Every controller action that reads or changes a user's data is scoped through the signed-in user, never looked up by id alone.
- The Content Security Policy is turned on in the authentication issue, before any page sits behind a login, and stays on.

## Testing

- Every behaviour change comes with a test that would catch its regression. Config, comments, formatting and pure refactors with existing coverage don't need new tests.
- RSpec with FactoryBot; system specs on Playwright.
- Models, feed ingestion and the pure player logic (queue advance, stop-after, sleep counts, palate cleansers, transcript cue lookup) are **test-first**: write the spec, run it and see it fail, then write the implementation. Red is a working-tree state, never a commit: every commit is green.
- Pages are test-alongside: build the page, check it live, then write the request and system specs from the issue's acceptance criteria, not from what happened to work. Check live strategically, because screenshots are token-heavy.
- Live checks and screenshots use a short throwaway script with the project's own Playwright, driving headless Chromium against the dev server, not the Playwright MCP server or the Claude in Chrome extension.
- No spec makes a real network request. Feeds are stubbed at the HTTP layer or served from fixtures.
- Flake policy: RSpec runs in random order; no retries; no `sleep` in specs; system specs use Playwright's auto-waiting assertions. Flakiness is fixed before merge, not retried.
- Stubs are fine, skips are not. A planned case may be committed as an example with no block, so the acceptance criteria are in the suite before the code is. `skip`, `xit` and focused examples (`fit`, `focus: true`) never reach `main`.
- **User testing is a human step.** Before any release, the maintainer uses the installed app on their phone, working through each sentence in the release. Claude drafts the test script from the issues' acceptance criteria beforehand and turns every finding into an issue afterwards; nothing from the test is fixed without an issue. Background playback, lock-screen controls and offline behaviour on Android can only be verified this way.

## Subagents

Hand self-contained work to a subagent, with an explicit model, a length cap and the shape of answer wanted; keep tightly coupled building in the main session. Run independent agents in parallel.

- **Haiku** for mechanical, fully specified actions, such as opening an issue from given text.
- **Sonnet** for reviews (including `/pre-pr`) and for writing specs against a clear specification.
- **Opus** for research that needs judgement, such as comparing gems.

## Commands

One check entrypoint: `bin/ci` (RuboCop, bundler-audit, importmap audit, Brakeman, the guard hook test, a check for focused or skipped examples, and the full RSpec suite). The GitHub Actions workflow runs `bin/ci` and nothing else. Never call `rspec`, `rubocop` or `brakeman` directly in CI or docs; running a single spec file while working is fine. Verification means running it; "it loads" is not verification.

## Pull requests

- Branch names start with the number of the issue they address, a slash, then a few words: `4/feed-refresh`.
- Every pull request adds a line to `CHANGELOG.md` under Unreleased, in plain words, under Keep a Changelog's headings.
- CI is green before a pull request is reported ready. Before every PR, run `/pre-pr` and triage its findings.
- A pull request that changes how the app looks carries before-and-after screenshots in its description.

## Commits

- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `type: summary`, with `feat`, `fix`, `docs`, `test`, `refactor`, `build`, `ci` or `chore`. Summary under 50 characters, present tense; the body carries the reasoning.
- Small: one logical change per commit, in dependency order. If this commit were reverted, would the codebase still be coherent? No WIP commits.
- Every commit is green: commit only when the check itself succeeded.
- A migration and the model code that needs it go in the same commit; generated schema files are committed as generated, never edited by hand.
- Never amend after pushing. Stage files by name. Never `--no-verify`.
- Commits Claude wrote or co-wrote end with `Co-Authored-By: Claude <model> <noreply@anthropic.com>`. That trailer is the audit trail. No session links: commits carry no `Claude-Session:` trailer, and pull request descriptions carry no claude.ai session URL, even when tooling suggests one.

## Docs

- Docs describe the current state. No roadmap narration outside the decision records, no "to be written", no issue numbers in code comments.
- `README.md` holds the docs index. `docs/decisions/` holds one record per decision: context, decision, alternatives, reasons, consequences, status, with the index in its README.
- Machine-specific gotchas (version-manager quirks, the local database port) live in `CLAUDE.local.md`, which is gitignored.
- Emoji appear only as the two decision flags. Nowhere else in code, docs or commits.
