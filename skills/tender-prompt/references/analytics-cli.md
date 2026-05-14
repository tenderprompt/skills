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

If the CLI capabilities response advertises an analytics authoring command, run
it before adding or changing event instrumentation:

```bash
tender app analytics authoring --json
```

If the remote playbook catalog includes `analytics-event-authoring`, fetch it
for the current source-of-truth examples:

```bash
tender playbooks get analytics-event-authoring --json
```

Treat the CLI authoring response and remote playbook as authoritative when they
exist. This reference should only carry stable guardrails.

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

## Event Authoring Guardrails

Existing custom events are still useful for activity totals, milestone tables,
and property breakdowns. Conversion funnels need extra top-level metadata so
Tender can dedupe one journey through ordered steps.

When instrumenting a conversion path:

- Keep the business event name, such as `quiz_started`, `bundle_review_viewed`,
  or `checkout_redirected`.
- Add top-level `unit` metadata with a stable id for the whole journey.
- Add top-level `flow` metadata for ordered conversion steps.
- Put business dimensions and metrics in `properties`.
- Do not put `unit` or `flow` inside `properties`.
- Do not emit `event_type`, `unit_step`, or any `platform.*` event from app
  code. Tender derives `unit_step` rows itself.
- When also publishing Shopify Customer Events, still send Tender analytics for
  the events needed in Tender dashboards.

Minimal shape:

```ts
await this.env.__TP_ANALYTICS.invoke({
  method: "track",
  payload: {
    event: "quiz_completed",
    unit: { type: "quiz_attempt", id: quizAttemptId },
    flow: {
      id: "recommendation_quiz",
      step: "quiz_completed",
      order: 3,
      role: "outcome",
    },
    properties: {
      experiment_id: "quiz_copy_v1",
      experiment_variant: "guided",
      score: 84,
    },
  },
});
```

Use `tender app doctor --dir . --json` after changing analytics code. Newer CLI
versions should report malformed analytics payloads and missing unit/flow
metadata as machine-readable diagnostics.

## Dashboard-Queryable Properties

Event payload properties move through three states:

- Tracked: the app sent the property in an analytics event payload.
- Observed: the bounded catalog saw the property in sampled analytics data.
- Queryable: dashboards can group or aggregate by that property.

When adding analytics events, identify properties that should be used in charts
and make them queryable before meaningful traffic starts. This avoids gaps in
fast dashboard-query coverage for early traffic.

Use dimensions for low-cardinality grouping values such as variant, plan, step,
source, or outcome:

```bash
tender app analytics properties activate <artifact-id> \
  --event <event-name> \
  --property <property-key> \
  --type dimension \
  --dry-run \
  --json
```

Use metrics for numeric values used in sums or averages such as score, amount,
duration, or quantity:

```bash
tender app analytics properties activate <artifact-id> \
  --event <event-name> \
  --property <property-key> \
  --type metric \
  --dry-run \
  --json
```

After the dry run looks correct, run the same command without `--dry-run`.

Do not make every property queryable. Avoid PII, secrets, free text, ids, URLs,
or high-cardinality values unless the user explicitly wants that analysis and
the chart has a clear purpose.

Making a property queryable does not require an app redeploy. Properties that
were tracked before activation may appear in catalog samples, but older fast
dashboard-query rows may not fully populate grouped charts until new traffic
arrives.

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
