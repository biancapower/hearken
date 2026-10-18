# 0003. Dependencies for login and tests: bcrypt, WebMock, Capybara with Playwright

**Context.** The first two 0.1.0 issues need gems that 0002 named only in general terms or not at all. The single-user login uses Rails 8's authentication generator, which hashes passwords with `bcrypt`. Feed ingestion specs must never fetch a real feed. 0002 chose Playwright for system specs but left open whether to drive it through Capybara or with `playwright-ruby-client` directly, to be decided at the first system spec, which the login issue brings.

**Decision.**

1. **`bcrypt`** for password hashing, as the authentication generator adds it.
2. **WebMock** to stub HTTP in specs, so no spec makes a real network request. Added with the feed ingestion work.
3. **Capybara with `capybara-playwright-driver`** for system specs, which brings `playwright-ruby-client`. The Ruby client drives Playwright's Node package, so the development and CI toolchain gains Node (the version in `.node-version`) and a pinned npm development dependency on `playwright`, whose version matches the Ruby client's. The app itself does not use Node.

**Alternatives.** For hashing, Argon2 through its own gem: stronger against GPU attacks, but off the generator's path for one account on a private network. For stubbing, VCR on top of WebMock: recorded cassettes suit an external API, while feeds are better served from small fixture files the specs control. For system specs, `playwright-ruby-client` alone (Playwright's own API and assertions, but none of Rails' system-spec helpers); a Chrome driver without Node such as Cuprite (simpler toolchain, but not Playwright, which 0002 chose); or no system specs yet.

**Reasons.** Each is the conventional choice for its job in a Rails app. Capybara keeps system specs in the usual Rails style, its matchers wait for the page, which suits the no-retries policy, and Playwright gives the same browser engine the spike's checks used.

**Consequences.** CI installs Node and Playwright's Chromium before running `bin/ci`. The Ruby client and the npm package are upgraded together. The open question in 0002 about unit tests for the pure JavaScript modules is unchanged, though Node is now in the toolchain.

**Status.** Proposed by Claude; approved by @biancapower, 2026-10-18.
