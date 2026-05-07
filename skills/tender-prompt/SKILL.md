---
name: tender-prompt
description: "Work with Tender Prompt from a local coding-agent checkout: create or edit Tender App projects, bootstrap project context, validate locally, send workspace heartbeat updates, push source through artifact Git, watch preview builds, publish after explicit user approval, or inspect artifact-scoped analytics through the Tender CLI."
license: MIT
compatibility: Requires the tender CLI, git, npm, and network access to a Tender Prompt instance.
metadata:
  author: Tender Prompt
  version: "0.1.3"
  hermes_tags: "Tender Prompt, Tender App, Git, Preview, Publish, Coding Agent"
---

# Tender Prompt

Work from a local Tender App checkout, or create one before editing. Edit files
locally, run checks, commit to Git, push to the artifact remote, watch preview
builds, inspect analytics, and publish only after explicit user intent.
For brand-new or empty Tender Apps, use the CLI's API-derived scaffold path; do
not copy, fork, or borrow another local Tender App as a starting scaffold.

The CLI does not run or message Tender's hosted agent. Treat the CLI as the
source, lifecycle, and analytics control surface. Do not call Tender HTTP APIs
directly.

## Workflow

```text
local checkout
  -> edit Tender App files
  -> npm run check
  -> git commit
  -> git push tender main
  -> Tender builds preview from that Git commit
  -> publish only when the user explicitly asks
```

Use Git as the source transport. Do not invent another source sync mechanism.
The `tender` remote should point at Tender's Git facade, for example
`https://app.tenderprompt.com/git/artifacts/<artifact-id>.git`.

## Setup

Use the latest published CLI. Prefer the npm package runner for agent work so a
stale global `tender` binary does not hide newer commands:

```bash
npm exec --yes @tenderprompt/cli@latest -- capabilities --json
```

If you use the global `tender` binary, update it first with
`npm install -g @tenderprompt/cli@latest`, then run `tender capabilities --json`.
Treat later `tender ...` examples as shorthand for the latest CLI runner unless
you have just refreshed the global binary.

When remote access is needed, authenticate with the device login flow. Use an
account-scoped token for normal multi-app work. Use `--artifact <artifact-id>`
only when the user explicitly wants to restrict the token to one app.

Never write Tender tokens into the project checkout. Prefer CLI profiles over
environment variables.

To download or start work on an existing app, use `tender app init`. When
artifact Git source exists it fetches that source and configures the `tender`
remote. Use `tender app context fetch` only when a checkout already exists and
needs fresh agent context.

For a brand-new Tender App, prefer one command that creates source and starts a
preview immediately:

```bash
npm exec --yes @tenderprompt/cli@latest -- app create "<name>" --init --dir <dir> --preview --json
```

For an existing app with no source yet, initialize it from the API-provided
scaffold and request a preview:

```bash
npm exec --yes @tenderprompt/cli@latest -- app init <artifact-id> --dir <dir> --scaffold server-backed --preview --json
```

The server-owned scaffold is the source of truth for empty apps. Do not copy,
fork, or borrow another local Tender App checkout as a scaffold.

## Inside A Tender App Checkout

Inside a checkout, usually after `tender app create --init --dir <dir> --preview --json`
or `tender app init <artifact-id> --dir <dir> --scaffold server-backed --preview --json`:

- Read `AGENTS.md` first when it exists.
- Read relevant `.agents/skills/*/SKILL.md` files before changing runtime,
  analytics, storage, bindings, preview, or publish behavior.
- Keep deployable Tender App source in `app.json`, `src/`, `assets/`, and
  `bindings/`.
- Keep repo-only context in `AGENTS.md`, `.agents/`, `.tenderprompt/`, docs,
  and tests. These files can be committed but must not become runtime assets.
- Run `npm run check` or `tender app doctor --dir .` before pushing.

## Workspace Heartbeats

Use the CLI heartbeat command as a lightweight feedback channel back to the
Tender Prompt workspace. Send one after loading the Tender Prompt context, then
at meaningful milestones such as exploring, editing, validating, pushing,
waiting for a preview build, or needing human input.

Keep heartbeats concise and best-effort. They should help the user understand
what you are doing without blocking the task or sending rapid polling updates.

```bash
tender app agent heartbeat <artifact-id> --source codex --status connected --summary "Loaded Tender Prompt context" --json
tender app agent heartbeat <artifact-id> --source codex --status working --phase exploring --summary "Reading the app structure" --json
tender app agent heartbeat <artifact-id> --source codex --status working --phase editing --summary "Updating app files" --json
tender app agent heartbeat <artifact-id> --source codex --status needs_attention --summary "Waiting for a decision" --requested-action answer_question --json
```

Use `--source claude-code` when running from Claude Code. Use `--source other`
with `--source-label <name>` only when neither Codex nor Claude Code is the
right identity.

For structured activity details, pass JSON through stdin:

```bash
tender app agent heartbeat <artifact-id> --input - --json < heartbeat.json
```

## Outbound Internet

Tender App backend code in `src/server.ts` cannot call third-party internet URLs
directly. Do not add `fetch("https://...")`, provider SDK clients, OAuth token
exchanges, or webhook calls in the app server.

Outbound calls from the app server are blocked. If the app needs external
network access, put that code behind a binding.

For outbound HTTP, provider APIs, OAuth/token use, webhooks, or secrets:

```bash
tender app bindings outbound --id <id> --host <host> --dry-run --json
```

Use the returned file shape and `appJsonBinding`, then regenerate env types and
run `tender app doctor --dir . --json`.

Treat changes to `bindings/*/binding.json` `allowedHosts` as security-sensitive.
Before publishing a change that adds or changes an allowed host, show the user
the host, binding id, and file path, then get explicit approval for that
destination.

## Preview And Publish

After `git push tender main`, inspect or watch the preview lifecycle job.
Streamed preview/publish output may be JSON lines; read until the final event
contains the preview or published URL.
If the push output does not include a job ID, use the pushed commit SHA:
`tender app preview watch <artifact-id> --commit $(git rev-parse HEAD) --stream --json`.

Publish is production-facing. Never publish from an inferred request. Require
clear user intent and prefer a dry run or explicit confirmation flag.

## Analytics

Use only the Tender CLI for analytics. Do not call analytics HTTP routes
directly and do not ask for direct query credentials or raw SQL access.

Start with capabilities to read the supported command surface, chart-spec shape,
retention/security limits, saved dashboards, and bounded observed analytics
catalog for the artifact:

```bash
tender app analytics capabilities <artifact-id> --include-catalog --range 30d --json
```

Then inspect local source code for analytics calls such as
`__TP_ANALYTICS.invoke(...)`, propose a chart spec, validate it with
`tender app analytics query`, and only save it after a successful query.
When adding or changing analytics events, register intended dashboard dimensions
and metrics early so meaningful traffic is queryable from the start.

Read [Analytics CLI workflow](references/analytics-cli.md) before creating,
exporting, or saving analytics dashboards for a customer.

## Troubleshooting

- `missing_typecheck_script`: add `check` or `typecheck` to `package.json`.
- `empty_or_new_app`: use `tender app create --init ...` or
  `tender app init ... --scaffold server-backed`; do not copy another local
  Tender App.
- `outbound_not_allowed_in_app_server`: move internet access into a binding.
- `invalid_allowed_host`: use a host like `api.example.com`, not a wildcard,
  URL, port, path, or query string.
- `repo_only_context_file`: safe warning; keep the file in Git but out of
  runtime bundles.
- `forbidden_secret_path`: remove `.env*`, private keys, or token files from
  the Git commit and use Tender secrets or binding configuration instead.
- `forbidden_repo_path`: remove dependency caches and generated output such as
  `node_modules`, `.git`, `dist`, `.next`, `.wrangler`, or build caches.
