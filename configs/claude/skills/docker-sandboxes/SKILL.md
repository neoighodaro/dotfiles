---
name: docker-sandboxes
description: "Use when running AI coding agents in Docker Sandboxes, setting up sbx CLI, managing sandbox network policies, creating templates or kits for custom environments, handling sandbox secrets and credentials, or troubleshooting sandbox issues. Triggers: sbx, docker sandbox, isolated agent, microVM, sandbox network policy, sandbox template, sandbox kit."
---

# Docker Sandboxes

Run AI coding agents in isolated microVM sandboxes. Each sandbox gets its own Docker daemon, filesystem, and network — agents can build containers and install packages without touching your host.

## Installation

| Platform | Install | Login |
|----------|---------|-------|
| macOS (Sonoma 14+, Apple silicon) | `brew install docker/tap/sbx` | `sbx login` |
| Windows (11, 64-bit) | `winget install -h Docker.sbx` | `sbx login` |
| Linux (Ubuntu 24.04+, KVM required) | `curl -fsSL https://get.docker.com \| sudo REPO_ONLY=1 sh && sudo apt-get install docker-sbx` | `sbx login` |

On first login, choose a default network policy: **Open** (unrestricted), **Balanced** (deny-by-default with common dev services allowed), or **Locked Down** (all traffic blocked).

## Quick Reference

| Task | Command |
|------|---------|
| Launch agent | `sbx run claude` |
| Launch on branch | `sbx run claude --branch my-feature` |
| Auto-name branch | `sbx run claude --branch auto` |
| Interactive dashboard | `sbx` |
| List sandboxes | `sbx ls` |
| Stop sandbox | `sbx stop <name>` |
| Remove sandbox | `sbx rm <name>` |
| Shell into sandbox | `sbx exec <name> -- bash` |
| Copy files | `sbx cp <name>:/path/to/file ./local` |
| Publish port | `sbx ports <name> --publish 8080:3000` |
| Diagnose issues | `sbx diagnose` |
| Full reset | `sbx reset` |

## Supported Agents

Claude Code, Codex, Copilot, Cursor, Droid, Gemini, Kiro, OpenCode, Docker Agent, and **Shell** (agent-less for manual setup).

## Git Integration

**Direct mode** (default): Agent modifies your working tree directly. Risk of conflicts with concurrent work.

**Branch mode** (`--branch <name>`): Creates an isolated Git worktree under `.sbx/`. Each worktree branches off your latest commit. Review changes with `git worktree list`, then push/PR as normal.

Mount additional directories: `sbx run claude ~/project-a ~/shared-libs:ro ~/docs:ro`

## Secrets & Credentials

```bash
sbx secret set -g anthropic          # prompts for ANTHROPIC_API_KEY
sbx secret set -g github -t "$(gh auth token)"
```

Credentials are injected by the host proxy into HTTP headers — they never enter the VM.

For unsupported env vars (e.g. `BRAVE_API_KEY`), write to `/etc/sandbox-persistent.sh` inside the sandbox — it's sourced on every shell login.

## Network Policies

Sandboxes use deny-by-default networking. All HTTP/HTTPS goes through the host proxy.

```bash
sbx policy ls                                        # view active rules
sbx policy log                                       # view blocked/allowed requests
sbx policy allow network -g "*.npmjs.org,*.pypi.org" # allow domains
sbx policy allow network -g "**"                     # allow all (escape hatch)
sbx policy allow network -g "10.1.2.3:22"            # non-HTTP needs IP:port
```

UDP and ICMP cannot be unblocked. Git-over-SSH can use HTTPS URLs as alternative.

Org admins can enforce policies centrally via Docker Admin Console — those override local rules.

## Templates

Reusable sandbox images with tools baked in. Base images: `docker/sandbox-templates:<variant>` (e.g. `claude-code`, `shell`). Each has a `-docker` variant with full Docker Engine.

```dockerfile
FROM docker/sandbox-templates:claude-code
USER root
RUN apt-get update && apt-get install -y protobuf-compiler
USER agent
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

```bash
docker build -t my-org/my-template:v1 --push .
sbx run --template docker.io/my-org/my-template:v1 claude
```

Save a running sandbox as template: `sbx template save my-sandbox my-template:v1`

Manage: `sbx template ls`, `sbx template rm`, `sbx template load <tar>`.

## Kits

Declarative YAML extending agents with tools, credentials, network rules, and files at runtime. Two kinds: **mixin** (extends existing agent) and **agent** (defines new agent from scratch). See `kit-reference.md` for the full YAML schema.

```bash
sbx run claude --kit ./my-kit/                    # local directory
sbx run claude --kit ./my-kit.zip                 # zipped
sbx run claude --kit "git+https://github.com/org/repo.git#ref=v1"
sbx run claude --kit ghcr.io/myorg/my-kit:1.0    # OCI registry
sbx kit validate ./my-kit/                        # check well-formedness
sbx kit inspect ./my-kit/                         # display details
sbx kit pack ./my-kit/ -o kit.zip                 # package
sbx kit push ./my-kit/ ghcr.io/myorg/my-kit:1.0  # publish
```

## Security Model

| Layer | What it does |
|-------|-------------|
| Hypervisor | Separate kernel per sandbox, no shared memory/processes |
| Network | Proxied HTTP/HTTPS, deny-by-default, non-HTTP blocked |
| Docker Engine | Each sandbox has its own independent daemon |
| Credentials | Injected by host proxy, never enter VM |

Agent has full privileges inside the VM (sudo, package install, private Docker Engine, read-write workspace). But: **workspace files are shared with host** — review Git hooks, CI configs, Makefiles, and package.json scripts before running them, as they execute automatically.

## Important Gotchas

- Sandboxes ignore `~/.claude` and other user-level config dirs. Copy relevant config into the project directory before starting. Symlinks to paths outside the sandbox don't work.
- Agent config files (like `.claude/settings.json`) are recreated on sandbox creation — they don't persist in saved templates.
- Sandboxes persist after agent exits. Same workspace path reconnects to existing sandbox.
- `sbx rm` deletes everything inside including worktrees. Main working tree is unaffected.
- Stopping doesn't delete the VM — environment setup carries over between runs.
- Services must bind to `0.0.0.0` for port publishing. Ports must be re-published after restarts.
- Access host services from sandbox via `host.docker.internal`.
- For Claude Code OAuth: use `/login` inside the sandbox.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Agent can't install packages / reach APIs | `sbx policy log` to find blocked domains, then `sbx policy allow network -g "domain"` |
| SSH/TCP connections fail | Use IP:port rules: `sbx policy allow network -g "10.1.2.3:22"` |
| Docker build `lchown` error | Use tar exporter: `docker build --output type=tar,dest=- . \| tar xf - -C ./result` |
| Stale worktrees after `sbx rm --branch` | `git worktree remove .sbx/<name>-worktrees/<branch>` then `git branch -D <branch>` |
| Commit signing fails | `ssh-add ~/.ssh/id_ed25519`, use inline key: `git config --global user.signingkey "key::$(ssh-add -L \| head -n 1)"` |
| Version downgrade DB error | `sbx reset --preserve-secrets` |
| Nothing works | `sbx reset` (nuclear), or delete state dirs (see docs) |

Diagnostics: `sbx diagnose` (add `--upload` to share with Docker support).

Telemetry opt-out: `SBX_NO_TELEMETRY=1`.

Issues: [github.com/docker/sbx-releases/issues](https://github.com/docker/sbx-releases/issues)
