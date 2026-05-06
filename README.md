# Tender Prompt Skills

Open skills for working with Tender Prompt from local coding agents.

This repository follows the same shape as public skill/toolkit repos: each
skill lives under `skills/<skill-name>/`, and repo-level documentation lives at
the root.

## Skills

- [`tender-prompt`](skills/tender-prompt/SKILL.md): edit, validate, preview,
  and publish Tender App projects from a local checkout using the Tender CLI,
  CLI-managed tokens, artifact-scoped analytics commands, and the artifact Git
  remote. Agents should start with
  `npm exec --yes @tenderprompt/cli@latest -- capabilities --json` so command
  details stay owned by the latest published CLI.

## Repository Layout

```text
skills/
  tender-prompt/
    SKILL.md
    agents/
      openai.yaml
    references/
      analytics-cli.md
```

Add new public skills under `skills/<skill-name>/`. Do not put human-facing
README files inside individual skill folders; keep those folders focused on the
agent-facing skill contract and optional bundled resources.

## Install

Clone this repository, then install or reference the skill folder from your local agent.

```bash
git clone git@github.com:tenderprompt/skills.git
```

### Claude

Copy or symlink `skills/tender-prompt/` into your Claude skills directory, then
start Claude from the Tender App checkout so it can read the project's
`AGENTS.md`.

### Codex

Copy or symlink `skills/tender-prompt/` into your Codex skills directory, or ask
Codex to read `skills/tender-prompt/SKILL.md` before editing a Tender App.

```bash
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.codex/skills/tender-prompt"
```

### Hermes

Add `skills/tender-prompt/` to the Hermes skills directory or registry, then
invoke it when the task mentions Tender Prompt, Tender App projects, artifact
Git, preview, or publish.

## Boundary

The skill does not run or message Tender's hosted agent. It teaches a local coding agent how to use source and lifecycle controls:

```text
local agent edits files
  -> local checks
  -> git push tender main
  -> Tender builds preview
  -> inspect analytics through tender app analytics
  -> explicit publish
```

## License

MIT.
