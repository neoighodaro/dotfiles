---
name: collab-consumer
description: "Consumes task files from a shared .ai/inbox directory left by a collaborator agent. Reads inbox files, presents choices when multiple exist, and triggers brainstorming for complex tasks. Activate when the user mentions inbox, collaborator, tasks, picking up work, or checking for new tasks. Requires an AGENTS.md with an Agent Collaboration section defining the inbox path and sibling project."
---

# Collab Consumer

Process task files dropped into a shared inbox by a collaborator agent.

## Setup

1. Read the project's `AGENTS.md` (or `CLAUDE.md` if no AGENTS.md exists)
2. Find the **Agent Collaboration** section
3. Extract the **inbox path** (relative to project root)
4. Identify this project's name and the sibling project

If no Agent Collaboration section exists, inform the user and stop.

## Workflow

### 0. Housekeeping

Before doing anything else, check for stale files in the inbox. If files exist, list them and ask the user:

> "I found existing files in the inbox. Want me to clean any up first?"
>
> **Inbox:** `file-a.md`, `file-b.md`

Only delete files the user confirms. If the directory is empty, proceed silently.

### 1. Scan for Tasks

List all `.md` files in the inbox. Filter to files addressed to this project (check the `to:` frontmatter field). If no files are addressed to this project (or the directory is empty/doesn't exist), inform the user there is nothing to pick up.

### 2. Select a File

- **One file:** Read it immediately.
- **Multiple files:** Present the filenames to the user with `AskUserQuestion` and let them choose which one to work on.

### 3. Read and Understand

Read the selected file in full. Summarize what it asks for so the user can confirm understanding before any work begins.

### 4. Assess Complexity

After reading, decide whether the task is potentially complex (multi-step, architectural decisions, multiple valid approaches, or unclear scope). If it is, invoke the `brainstorming` skill before proceeding to implementation.

For straightforward tasks (single clear action, no ambiguity), skip brainstorming and proceed directly.

### 5. Clean Up

Once the task described in the inbox file is **fully complete**, ask the user for explicit confirmation before deleting the file:

> "The task from `{filename}` is complete. Should I delete the inbox file?"

Only delete after the user confirms. Never delete silently or preemptively.

## Rules

- Never modify inbox files — they are read-only inputs.
- Never delete an inbox file without explicit user confirmation.
- Always summarize the file contents before acting on them.
- When in doubt about complexity, lean toward triggering brainstorming.
- If the task references source files in the sibling project, read them via absolute path.
