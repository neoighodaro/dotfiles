---
name: hotfix
description: "Use when the user says 'hotfix' or asks to create a hotfix branch, commit a quick fix, or merge a hotfix. Covers the full hotfix flow: branch, commit, merge back."
---

# Hotfix

Create a hotfix branch, commit the fix, and merge it back into the current branch.

## Workflow

1. Identify the current branch (the target to merge back into)
2. Create branch `hotfix/<short-description>` from current HEAD
3. Stage and commit the changes with a descriptive message
4. Switch back to the original branch
5. Merge the hotfix branch with `--no-ff`
6. Delete the hotfix branch after merging

## Rules

- Branch name format: `hotfix/<kebab-case-description>`
- Keep the description short but meaningful (e.g. `fix-sessions-tab-active-state`)
- Always use `--no-ff` merge to preserve the hotfix branch in history
- Always delete the hotfix branch after merging
- Do NOT push unless explicitly asked
