---
name: collab-provider
description: "Writes task/instruction files to a shared inbox for a sibling project's agent. Activate when implementing something the sibling project needs to know about, porting patterns, requesting context, or when the user explicitly asks to write instructions for the other project. Requires an AGENTS.md with an Agent Collaboration section defining the inbox path and sibling project."
---

# Collab Provider

Write task files to a shared inbox so the sibling project's collaborator agent can pick them up.

## Setup

1. Read the project's `AGENTS.md` (or `CLAUDE.md` if no AGENTS.md exists)
2. Find the **Agent Collaboration** section
3. Extract the **inbox path** (relative to project root)
4. Identify this project's name and the sibling project

If no Agent Collaboration section exists, ask the user where the shared inbox should live and suggest adding an Agent Collaboration section to AGENTS.md.

## When to Trigger

### Automatic Prompt

After completing any of the following, ask the user whether they want to write instructions for the sibling project:

- Changing a shared contract (schemas, API shapes, types)
- Porting a feature that requires noting transforms or decisions made
- Identifying a pattern that needs clarification before porting
- Discovering something the sibling agent should know about

Prompt with something like:

> "This might be useful for the sibling project. Want me to drop a note in the inbox?"

Only write the file if the user confirms.

### Manual

The user explicitly asks to write something for the sibling project (e.g., "send this to klar", "write inbox for the other project", "tell the other project about this").

## File Format

### Naming

```
{from}-to-{to}-{slug}.md
```

Derive `{from}` and `{to}` from AGENTS.md project names. Use short identifiers.

### Content

```markdown
---
from: {this project name}
to: {target project name}
type: port-request | context | question | task
priority: low | normal | high
created: {today's date}
---

{self-contained description of what's needed}

## Source Files
- `path/to/relevant/file.ts` — what to look at and why
```

## Workflow

### 0. Housekeeping

Before writing any new files, check for stale files in the inbox. If files exist, list them and ask the user:

> "I found existing files in the inbox. Want me to clean any up first?"

Only delete files the user confirms. If the directory is empty, proceed silently.

1. Gather the relevant context from the work just completed.
2. Generate the filename using the naming convention.
3. Write the file to the inbox.
4. Tell the user the filename and confirm it was written.

## Rules

- Always write the file by default. Only skip if the user explicitly asks not to.
- Never overwrite existing inbox files — always create new ones.
- Keep instructions self-contained — the collaborator agent has no access to this conversation's context.
- Reference source files by absolute path so the receiving agent can read them directly.
- One task per file — don't batch.
