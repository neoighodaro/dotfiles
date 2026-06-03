# Kit YAML Reference

## Directory Structure

```
my-kit/
├── spec.yaml
└── files/
    ├── home/       # → /home/agent/
    └── workspace/  # → workspace root
```

## spec.yaml Schema

### Top-Level

```yaml
schemaVersion: "1"
kind: mixin | agent
name: lowercase-alphanumeric-hyphens
displayName: Human Readable Name
description: What this kit does
memory: |
  Markdown appended to agent memory file (e.g. CLAUDE.md).
  Multiple kits create separate files under kits-memory/ with index in main file.
```

### Credentials

```yaml
credentials:
  sources:
    <service-id>:
      env: [VAR_NAME, ...]
      file:
        path: /path/to/credentials
        parser: json | toml | ini
      priority: env-first | file-first
```

### Network

```yaml
network:
  allowedDomains: ["*.example.com", "api.service.io"]
  deniedDomains: ["blocked.example.com"]    # takes precedence over allowed
  serviceDomains:
    api.example.com: my-service
  serviceAuth:
    my-service:
      headerName: Authorization
      valueFormat: "Bearer ${credential}"
```

### Environment

```yaml
environment:
  variables:
    MY_VAR: "value"
  proxyManaged: [MANAGED_VAR]   # injected by host proxy
```

### Commands

```yaml
commands:
  install:                        # run once at sandbox creation
    - command: "apt-get install -y ripgrep"
      user: "0"                   # default: root
      description: Install ripgrep

  startup:                        # run at each sandbox start (must be idempotent)
    - command: ["node", "server.js"]
      user: "1000"                # default: agent
      background: true            # default: false
      description: Start dev server

  initFiles:                      # write files at startup
    - path: /home/agent/.config/app.json
      content: |
        {"workdir": "${WORKDIR}"}
      mode: "0644"                # default
      onlyIfMissing: false        # default
      description: App config
```

### Agent Block (required for `kind: agent`)

```yaml
agent:
  image: my-org/my-agent:latest
  aiFilename: CLAUDE.md           # memory file name
  persistence: persistent | ephemeral
  entrypoint:
    run: ["/usr/bin/my-agent"]
    args: ["--flag"]
```

Agent images must provide: non-root `agent` user at UID 1000 with passwordless sudo, `/home/agent/` home dir, and HTTP proxy env vars preserved across sudo.

## Complete Mixin Example

```yaml
schemaVersion: "1"
kind: mixin
name: rust-dev
displayName: Rust Development
description: Adds Rust toolchain and common tools
memory: |
  Rust toolchain is available. Use `cargo` for builds.

credentials:
  sources:
    crates-io:
      env: [CARGO_REGISTRY_TOKEN]

network:
  allowedDomains:
    - "*.crates.io"
    - "static.rust-lang.org"
    - "*.cloudfront.net"

commands:
  install:
    - command: "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | su agent -c 'sh -s -- -y'"
      description: Install Rust toolchain
    - command: "su agent -c '/home/agent/.cargo/bin/cargo install cargo-watch'"
      description: Install cargo-watch

environment:
  variables:
    RUST_BACKTRACE: "1"
```
