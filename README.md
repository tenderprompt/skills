# Tender Prompt Skills

Open skills for working with Tender Prompt from local coding agents.

This repository keeps one provider-neutral skill tree under `skills/`.
Provider-specific plugin manifests package that same tree for Claude Code and
Codex without duplicating the skill instructions.

## Skills

- [`tender-prompt`](skills/tender-prompt/SKILL.md): edit, validate, preview,
  and publish Tender App projects from a local checkout using the Tender CLI,
  CLI-managed tokens, artifact-scoped analytics commands, and the artifact Git
  remote. Agents should start with
  `npm exec --yes @tenderprompt/cli@latest -- capabilities --json` so command
  details stay owned by the latest published CLI.

## Repository Layout

```text
.claude-plugin/
  plugin.json
.codex-plugin/
  plugin.json
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

Clone this repository, then install or reference the skill folder from your
local agent.

```bash
git clone git@github.com:tenderprompt/skills.git
cd skills
```

### Claude

Tender Prompt is not currently published in a Claude plugin marketplace, so
there is no public `claude plugin install` command yet.

To test the repository as a local plugin, start Claude Code with the repository
root as its plugin directory:

```bash
claude --plugin-dir "$PWD"
```

As a direct-skill fallback, symlink the canonical skill into Claude's personal
skills directory:

```bash
mkdir -p "$HOME/.claude/skills"
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.claude/skills/tender-prompt"
```

Inside a Tender App repository, Claude Code reads `CLAUDE.md`, not `AGENTS.md`.
Tender App repositories should bridge the shared instructions from a root
`CLAUDE.md`:

```markdown
@AGENTS.md

Relevant reusable skills live under `.agents/skills/`. Read the applicable
`SKILL.md` files when they are not exposed by the current agent host.
```

If an older Tender App does not have this bridge, add it or explicitly ask
Claude to read `AGENTS.md`. `.agents/skills/` remains Tender's canonical
provider-neutral project layout. The Tender runner can expose those skills to
Claude natively; outside that runner, use a `.claude/skills/` adapter or have
Claude read the relevant `.agents/skills/<skill-name>/SKILL.md` files directly.

### Codex

Tender Prompt is not currently published in a Codex plugin marketplace, so
there is no public `codex plugin add` command yet. For local use, symlink the
canonical skill into Codex's personal skills directory:

```bash
mkdir -p "$HOME/.codex/skills"
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.codex/skills/tender-prompt"
```

The `.codex-plugin/plugin.json` manifest packages the same root `skills/` tree
for a future verified plugin distribution surface.

### Hermes

Add `skills/tender-prompt/` to the Hermes skills directory or registry, then
invoke it when the task mentions Tender Prompt, Tender App projects, artifact
Git, preview, or publish.

## Boundary

The skill does not run or message Tender's hosted agent. It teaches a local
coding agent how to use source and lifecycle controls:

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
