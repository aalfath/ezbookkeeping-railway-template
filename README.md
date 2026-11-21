[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/ezbookkeeping-1?utm_medium=integration&utm_source=button&utm_campaign=ezbookkeeping)

# ezBookkeeping on Railway

One-click Railway template for [ezBookkeeping](https://github.com/mayswind/ezbookkeeping), an open-source, self-hosted personal finance app (MIT).

## What it deploys

- **ezBookkeeping 2.1.1**, built from this repo's `Dockerfile`, which pins the official image
  `mayswind/ezbookkeeping:2.1.1@sha256:584e4d7f6fc1642773e840b56296f8782912e3bb17abfe3c49097508b198cdb7`.
- One service with a public HTTPS domain and one volume at `/ezbookkeeping/data`, which holds the SQLite
  database (`ezbookkeeping.db`) and uploaded files (`storage/`: avatars, custom icons, transaction pictures).
- Health check: `GET /` (Railway doesn't accept a dot in the path, so the app's own `/healthz.json` can't be used there; `/` is served by the same Go server, without login).

`railway-start.sh` (the container entrypoint) sets the listen port from `PORT`, derives the public URL from
`RAILWAY_PUBLIC_DOMAIN`, keeps the database and uploads on the volume, turns public sign-up off by default,
creates the first account on first boot, and then starts the server as the image's non-root user.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_EMAIL` | *(you enter it)* | Email of the first account. |
| `ADMIN_USERNAME` | `admin` | Username of the first account, created on first boot only. |
| `ADMIN_PASSWORD` | generated (`secret(24)`) | Password of the first account. Read it in the service's Variables tab, then change it in the app. Changing the variable later doesn't change the password. |
| `ADMIN_DEFAULT_CURRENCY` | `USD` | Default currency of the first account (ISO 4217 code). |
| `EBK_SECURITY_SECRET_KEY` | generated (`secret(64)`) | Signs login tokens. Changing it logs everyone out. |
| `EBK_USER_ENABLE_REGISTER` | `false` | Set to `true` to let anyone with the URL create an account. |
| `PORT` | `8080` | Port the app listens on. |

Any other setting from ezBookkeeping's [configuration](https://ezbookkeeping.mayswind.net/configuration)
can be added as an `EBK_<SECTION>_<KEY>` variable, for example SMTP (`EBK_MAIL_ENABLE_SMTP`,
`EBK_MAIL_SMTP_HOST`, …), OAuth 2.0 / OIDC login (`EBK_AUTH_ENABLE_OAUTH2_AUTH`, …), AI receipt recognition
(`EBK_LLM_…`) or the MCP server (`EBK_MCP_ENABLE_MCP`).

## Updates

Deployers of the Railway template get an "update available" notice when a change is merged to this repo's
`main` branch. Read `CHANGELOG.md` before applying an update: breaking changes are listed first.
ezBookkeeping upgrades its database tables on start. Back up the volume before a major version upgrade.
