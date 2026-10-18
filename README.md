# Hearken

Hearken is a self-hosted podcast player for your own audio and feeds: a small Rails server holds your library, queue and listening history, and your phone installs the player as a web app. It is built for people who learn from what they listen to, with a transcript that follows along beside the controls and notes pinned to the moment they were taken.

## Status

Pre-0.1.0. The app has sign-in and an empty library; nothing plays yet. Release 0.1.0 is a player that can replace a phone podcast app for the maintainer's own feeds, served over a private network.

## Running locally

Needs Ruby (the version in `.ruby-version`), Node (the version in `.node-version`, for the browser tests) and PostgreSQL 16 or later.

```sh
bin/setup   # installs gems, prepares the database, starts the dev server
bin/ci      # style, security scans and the test suite, as CI runs them
```

Create your account with `bin/rails users:create`, which prompts for the email address and password. There is no sign-up page.

If PostgreSQL is not on the default socket and port, set `PGHOST` and `PGPORT`, or `DATABASE_URL` without a database name.

## Production settings

The app expects a TLS-terminating proxy in front of it and redirects plain HTTP to HTTPS. Set `HEARKEN_HOSTS` to the comma-separated host names it is served under; requests for any other host are refused (it defaults to `localhost`).

## Docs

- [Decisions](docs/decisions/README.md): what was decided and why, one record per decision.

## Licence

Copyright Bianca Power. Licensed under the [GNU Affero General Public License v3.0](LICENSE).
