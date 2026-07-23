# Tender Prompt Skills Repo

This repository is the source of truth for public Tender Prompt agent skills.
Keep skills under `skills/<skill-name>/`.
Keep each skill provider-neutral and canonical. Claude Code, Codex, and other
hosts should adapt the root `skills/` tree through manifests or install
surfaces, not duplicated skill bodies.

## Skill Layout

Each skill should follow the agent skill shape:

```text
skills/
  <skill-name>/
    SKILL.md
    agents/
      openai.yaml
    references/
      ...
```

Provider manifests live at:

```text
.claude-plugin/plugin.json
.codex-plugin/plugin.json
```

Both manifests must reference `./skills/`. Keep their package versions aligned
with the canonical Tender Prompt skill version when a change affects its
distribution or compatibility.

- `SKILL.md` is required and must include YAML frontmatter with `name` and
  `description`.
- Keep `SKILL.md` concise. Move long CLI workflows and detailed protocol notes
  into `references/`.
- Do not add raw Tender API references to the skill. Agent workflows should go
  through the Tender CLI.
- Do not add README, install guide, changelog, or other human-facing docs inside
  individual skill folders. Put repo-level documentation in the root README.
- Use `agents/openai.yaml` for UI-facing metadata when a skill should be visible
  in OpenAI/Codex skill lists.

## Tender Prompt Naming

- Use `Tender Prompt` for the product.
- Use `Tender App` for app projects.
- Do not use `Tender Generated App` or shorten the concept to `Generated`.

## Local Installation

For local testing, symlink skills from this repository into the agent skill
directory instead of copying files. That keeps local testing pointed at the
current source of truth.

```bash
mkdir -p "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.agents/skills"
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.claude/skills/tender-prompt"
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.codex/skills/tender-prompt"
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.agents/skills/tender-prompt"
```

When adding a new skill, add it under `skills/`, update the root `README.md`,
and validate the frontmatter, `agents/openai.yaml`, and both provider manifests
before publishing. Run:

```bash
ruby scripts/validate-repository.rb
```

When Claude Code is installed, also run `claude plugin validate .`. Do not add
marketplace entries or public install commands until the corresponding plugin
is actually published and the command has been verified.
