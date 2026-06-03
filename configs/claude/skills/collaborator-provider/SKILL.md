---
name: collaborator-provider
description: "Writes task/instruction files to the sibling collaborator's inbox. Activate when implementing new endpoints, features, or adjusting API/component contracts that the sibling project needs to know about. Also activate when the user explicitly asks to write instructions for the other project. Only applies to yulo projects (yulo and yulo-web)."
---

# Collaborator Provider

Write task files to the sibling project's `.ai/inbox/` directory so its collaborator agent can pick them up.

## Scope

This skill only applies when working inside one of these projects:

- `yulo` (backend — Laravel)
- `yulo-web` (frontend — React/TanStack)

If the current working directory is not within either of these projects, do not activate.

## Project Detection

Determine which project you are in by checking the current working directory:

- If the path contains `/yulo-web`, you are in the **frontend** project. The sibling is the **backend** (`yulo`).
- If the path contains `/yulo` (but not `/yulo-web`), you are in the **backend** project. The sibling is the **frontend** (`yulo-web`).

Derive the sibling path by replacing the project directory name in the current path. For example:
- In `/Users/neo/Developer/ck/yulo-web` → sibling is `/Users/neo/Developer/ck/yulo`
- In `/Users/neo/Developer/ck/yulo` → sibling is `/Users/neo/Developer/ck/yulo-web`

## Directories

### Target Inbox (sibling)

- **Path:** `<sibling-project>/.ai/inbox/`

If it does not exist AND the sibling's `.ai` directory does not exist, ask the user for the correct path and remember it for next time but don't update this file. However, if the sibling's `.ai` directory does exist, create the inbox directory.

### Own Outbox (local)

Always write a copy of every task file to this project's own outbox:

- **Path:** `.ai/outbox/`

Create the directory if it does not exist. The outbox serves as a fallback when this server is sandboxed and cannot write to the sibling inbox. The sibling consumer can pick up files from here instead.

## When to Trigger

### Automatic Prompt

After completing any of the following, ask the user whether they want to write instructions for the sibling project:

- New or modified API endpoint (controller, route)
- Changed request/response shape (added/removed fields, changed status codes)
- New or updated authentication/authorization flow
- Changed validation rules that affect what the other project sends/receives
- New or modified error response formats
- Rate limiting changes
- New or modified shared types/contracts
- UI component changes that require backend support (or vice versa)

Prompt with something like:

> "This changes the contract between projects. Want me to write instructions for the sibling collaborator?"

Only write the file if the user confirms.

### Manual

The user explicitly asks to write something for the sibling project (e.g., "send this to the frontend", "write inbox for backend", "tell the other project about this").

## File Format

### Naming

Use a random two-word kebab-case name with `.md` extension. Examples:
- `crimson-paradox.md`
- `marble-drift.md`
- `quiet-thunder.md`

### Content

Write clear, actionable instructions that a collaborator agent can execute without access to this project's codebase. Include:

1. **What changed** — endpoints, methods, request/response shapes, components, contracts
2. **Full contract details** — method, path, headers, request body with types, all response codes and their bodies (for API changes); props, events, expected data shapes (for component changes)
3. **Validation rules** — so the sibling project can mirror them
4. **Behavioral notes** — e.g., "returns 204 regardless of email existence to prevent enumeration"
5. **i18n considerations** — Accept-Language header usage, localized responses
6. **Checklist** — a markdown checkbox list the collaborator agent can verify against

Do NOT include:
- Internal implementation details (model internals, middleware names, service classes, internal component state)
- Database schema or migration details
- Anything the sibling project doesn't need to act on

## Workflow

### 0. Housekeeping

Before writing any new files, check for stale files in both `.ai/outbox/` and the sibling inbox (`<sibling-project>/.ai/inbox/`). If either contains files, list them and ask the user:

> "I found existing files before writing new instructions. Want me to clean these up first?"
>
> **Own outbox:** `file-a.md`
> **Sibling inbox:** `file-b.md`, `file-c.md`

Only delete files the user confirms. If both directories are empty, proceed silently.

1. Gather the relevant contract details from the work just completed.
2. Resolve the sibling inbox path (check primary, then ask if missing).
3. Generate a random filename.
4. Write the file to the sibling inbox (if accessible).
5. Write a copy of the same file (same name) to `.ai/outbox/`.
6. Tell the user the filename and where copies were written. If the sibling inbox was unreachable, note that the file is available in the outbox for the sibling to pick up.

## Rules

- Always write the file by default. Only skip if the user explicitly asks not to.
- Never overwrite existing inbox files — always create new ones.
- Keep instructions self-contained — the collaborator agent has no access to this project's codebase.
- Use concrete examples for request/response bodies, not abstract descriptions.
