# Analytics CLI Workflow

Understand or create analytics dashboards for a Tender App through the Tender
CLI. Do not call Tender HTTP APIs directly, request direct query credentials, or
write raw SQL.

## Outcome

Help the customer understand their app's observed data and create useful saved
charts without exposing cross-app data or implementation details.

Combine:

- artifact-scoped analytics capabilities from the CLI
- bounded observed event, path, and property metadata from the analytics catalog
- local source-code inspection, especially `__TP_ANALYTICS.invoke(...)` calls
- existing saved dashboards and charts
- customer intent from the prompt or app context

## Start Here

Read the general Tender App command surface:

```bash
npm exec --yes @tenderprompt/cli@latest -- capabilities --json
```

Use the returned `cli.version` and `recommendedSkill.version` to detect stale
global CLI installs or stale local Tender Prompt skill copies.

Inspect the artifact-specific analytics surface:

```bash
tender app analytics capabilities <artifact-id> --include-catalog --range 30d --json
```

Use the response fields for:

- supported analytics commands
- chart spec shape
- retention, range, quota, and security limits
- existing saved dashboards and charts
- observed event names, request paths, property keys, rough types, and counts

## Source Inspection

After reading capabilities, inspect the app source locally.

Search for analytics usage:

```bash
rg -n "__TP_ANALYTICS|analytics\\.invoke|invoke\\(" src app.json bindings
```

Use the code to understand what the app is doing, but keep suggestions grounded
in observed data from `capabilities --include-catalog`. A source call that has
never produced observed events is a weak suggestion unless the user explicitly
wants to prepare for future traffic.

## Read-Only Commands

```bash
tender app analytics summary <artifact-id> --range 30d --json

tender app analytics query <artifact-id> --spec chart.json --json

tender app analytics query <artifact-id> --spec - --json < chart.json

tender app analytics export catalog <artifact-id> --range 30d --json

tender app analytics export query <artifact-id> --spec chart.json --format csv

tender app analytics suggestions <artifact-id> --range 30d --json
```

Use `export query` when building a local dashboard or doing deeper analysis.
It returns validated aggregate rows, not raw event rows.

## Safe Writes

Preview writes first:

```bash
tender app analytics dashboards <artifact-id> \
  --create "Agent dashboard" \
  --dry-run \
  --json

tender app analytics charts create <artifact-id> \
  --dashboard <dashboard-id> \
  --title "Signup funnel" \
  --spec funnel.json \
  --dry-run \
  --json
```

Only remove `--dry-run` after the chart spec has been validated with
`tender app analytics query` and the user wants the chart saved.

## Suggested Agent Loop

1. Run `capabilities --include-catalog`.
2. Inspect source for analytics calls and app flow.
3. List existing saved charts to avoid duplicates.
4. Draft one or more chart specs.
5. Validate every spec with `tender app analytics query`.
6. Export aggregate rows if local analysis or a local dashboard needs data.
7. Use `--dry-run` for dashboard/chart creation.
8. Save only the validated charts the user asked for.

## Security Rules

- Artifact-scoped tokens can only access their app's analytics.
- Do not request direct query credentials.
- Do not request raw SQL access.
- Do not export unbounded raw event data.
- Do not infer cross-customer or cross-app benchmarks from artifact-scoped data.
- Keep chart suggestions explainable with observed event/path/property evidence.
