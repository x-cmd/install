# Skills — agent assistance for `x-cmd/install`

Skills live here as Markdown files describing tasks the agent is
likely to do against this repo. Each skill is a self-contained
recipe — read the file in full before executing.

| Skill | When to use |
|-------|-------------|
| (more skills added over time) | |

Add new skills under `.x-cmd/skill/<name>.md`. Each skill file
should follow this layout:

```markdown
# <Skill name>

## When to use
<symptom or trigger condition>

## What you can / cannot do
<scope: what the agent can change, what requires a human>

## Steps
1. <concrete step>
2. <concrete step>
...

## Gotchas
<things that bit me, recorded so they don't bite again>
```
