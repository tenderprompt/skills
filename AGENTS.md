# Tender Prompt Skills Repo

This repository is the source of truth for public Tender Prompt agent skills.
Keep skills under `skills/<skill-name>/`.

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
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.codex/skills/tender-prompt"
ln -sfn "$PWD/skills/tender-prompt" "$HOME/.agents/skills/tender-prompt"
```

When adding a new skill, add it under `skills/`, update the root `README.md`,
and validate the frontmatter and `agents/openai.yaml` before publishing.
