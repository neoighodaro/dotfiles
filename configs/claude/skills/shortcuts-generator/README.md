# Shortcuts Generator Skill for Claude Code

A Claude Code skill that enables AI-assisted generation of macOS/iOS Shortcuts. Create valid `.shortcut` plist files that can be signed and imported into Apple's Shortcuts app.

## Installation

### 1. Create the skills directory (if it doesn't exist)

```bash
mkdir -p ~/.claude/skills
```

### 2. Clone or copy this repository

```bash
cd ~/.claude/skills
git clone https://github.com/drewocarr/shortcuts-generator.git
```

Or download and extract the files manually into `~/.claude/skills/shortcuts-generator/`.

### 3. Verify the installation

Your directory structure should look like:

```
~/.claude/
└── skills/
    └── shortcuts-generator/
        ├── SKILL.md          # Required - skill definition
        ├── ACTIONS.md
        ├── APPINTENTS.md
        ├── CONTROL_FLOW.md
        ├── EXAMPLES.md
        ├── FILTERS.md
        ├── PARAMETER_TYPES.md
        ├── PLIST_FORMAT.md
        └── VARIABLES.md
```

### 4. Restart Claude Code

The skill will be automatically detected on the next conversation.

## Usage

Once installed, simply ask Claude Code to create a shortcut:

- "Create a shortcut that shows the current weather"
- "Build a shortcut that asks for text input and shows it"
- "Make a shortcut that opens Safari and navigates to a URL"

Claude will generate the plist XML, write it to a `.shortcut` file, and sign it so you can import it directly into the Shortcuts app.

## What's Included

| File | Description |
|------|-------------|
| `SKILL.md` | Skill definition with quick start guide |
| `ACTIONS.md` | All 427 WF*Action identifiers and parameters |
| `APPINTENTS.md` | All 728 AppIntent actions |
| `PARAMETER_TYPES.md` | Parameter value types and serialization formats |
| `VARIABLES.md` | Variable reference system |
| `CONTROL_FLOW.md` | Repeat, Conditional, Menu patterns |
| `FILTERS.md` | Content filters for Find/Filter actions |
| `EXAMPLES.md` | Complete working examples |

## Requirements

- macOS with the `shortcuts` CLI tool (included with macOS)
- Claude Code CLI

## How Skills Work

Skills are collections of markdown files that provide Claude Code with specialized knowledge and capabilities. The `SKILL.md` file defines:

- **name**: Identifier for the skill
- **description**: When to use this skill (triggers automatic invocation)
- **allowed-tools**: Which tools Claude can use when the skill is active

When you ask Claude Code to do something that matches the skill's description, it automatically loads the skill's documentation to provide accurate, specialized assistance.

## License

MIT
