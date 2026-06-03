---
name: collaborator-consumer
description: "Consumes task files from the .ai/inbox directory left by a collaborator agent. Reads inbox files, presents choices when multiple exist, and triggers brainstorming for complex tasks. Activate when the user mentions inbox, collaborator, tasks, picking up work, or checking for new tasks. Only applies to yulo projects (yulo and yulo-web)."
---

# Collaborator Consumer

Process task files dropped into `.ai/inbox/` by a collaborator agent, or found in the sibling project's `.ai/outbox/` when the remote agent was sandboxed.

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

- **Own inbox:** `.ai/inbox/` (relative to current project root) — primary source for incoming tasks.
- **Sibling outbox (fallback):** `<sibling-project>/.ai/outbox/` — check here when the sibling agent couldn't write to our inbox directly (sandboxed).

## Workflow

### 0. Housekeeping

Before doing anything else, check for stale files in both `.ai/inbox/` and `.ai/outbox/`. If either directory contains files, list them and ask the user:

> "I found existing files before starting. Want me to clean these up first?"
>
> **Inbox:** `file-a.md`, `file-b.md`
> **Outbox:** `file-c.md`

Only delete files the user confirms. If both directories are empty, proceed silently.

### 1. Scan for Tasks

List all `.md` files in `.ai/inbox/`. Also check the sibling outbox (`<sibling-project>/.ai/outbox/`) for any files. Merge both lists, noting the source of each. If both directories are empty (or don't exist), inform the user there is nothing to pick up.

### 2. Select a File

- **One file:** Read it immediately.
- **Multiple files:** Present the filenames to the user with `AskUserQuestion` and let them choose which one to work on.

### 3. Read and Understand

Read the selected file in full. Summarize what it asks for so the user can confirm understanding before any work begins.

### 4. Assess Complexity

After reading, decide whether the task is potentially complex (multi-step, architectural decisions, multiple valid approaches, or unclear scope). If it is, invoke the `brainstorming` skill before proceeding to implementation.

For straightforward tasks (single clear action, no ambiguity), skip brainstorming and proceed directly.

### 5. Write to Own Outbox

After completing the task, write a summary of what was done to `.ai/outbox/` using the same filename. This lets the sibling project's consumer pick up the completion status even if this server is sandboxed. The summary should include:

- What was implemented
- Any decisions or deviations from the original request
- Files changed (paths only)

### 6. Clean Up

Once the task described in the inbox file is **fully complete**, ask the user for explicit confirmation before deleting the file:

> "The task from `{filename}` is complete. Should I delete the inbox file?"

If the file came from the sibling outbox, ask about deleting it there too.

Only delete after the user confirms. Never delete silently or preemptively.

## Rules

- Never modify inbox files — they are read-only inputs.
- Never delete an inbox file (or sibling outbox file) without explicit user confirmation.
- Always summarize the file contents before acting on them.
- When in doubt about complexity, lean toward triggering brainstorming.
- Always write a completion summary to `.ai/outbox/` after finishing a task, even if the inbox file came from the local inbox.
