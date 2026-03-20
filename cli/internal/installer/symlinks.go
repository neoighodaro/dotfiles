package installer

import (
	"os"
	"path/filepath"

	"github.com/neoighodaro/dotfiles/cli/internal/link"
	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

// linkDef defines a single symlink: source (relative to configs/) → target (relative to $HOME).
type linkDef struct {
	source string
	target string
}

func symlinkSteps() []Step {
	return []Step{
		{Name: "link-zsh", Desc: "ZSH configuration", Run: stepLinkZsh},
		{Name: "link-git", Desc: "Git configuration", Run: stepLinkGit},
		{Name: "link-starship", Desc: "Starship", Run: stepLinkStarship},
		{Name: "link-ghostty", Desc: "Ghostty", Run: stepLinkGhostty},
		{Name: "link-wezterm", Desc: "Wezterm", Run: stepLinkWezterm},
		{Name: "link-zellij", Desc: "Zellij", Run: stepLinkZellij},
		{Name: "link-lazygit", Desc: "Lazygit", Run: stepLinkLazygit},
		{Name: "link-aerospace", Desc: "Aerospace WM", Run: stepLinkAerospace},
		{Name: "link-karabiner", Desc: "Karabiner-Elements", Run: stepLinkKarabiner},
		{Name: "link-sketchybar", Desc: "Sketchybar", Run: stepLinkSketchybar},
		{Name: "link-claude", Desc: "Claude Code", Run: stepLinkClaude},
		{Name: "link-k9s", Desc: "K9s", Run: stepLinkK9s},
		{Name: "link-ssh", Desc: "SSH", Run: stepLinkSSH},
		{Name: "link-hazel", Desc: "Hazel", Run: stepLinkHazel},
		{Name: "link-vscode", Desc: "VS Code", Run: stepLinkVSCode},
		{Name: "link-cursor", Desc: "Cursor", Run: stepLinkCursor},
		{Name: "link-ansible", Desc: "Ansible", Run: stepLinkAnsible},
		{Name: "link-misc", Desc: "Miscellaneous", Run: stepLinkMisc},
	}
}

// linkOpt marks a linkDef as optional (skip if source doesn't exist).
type linkOpt struct {
	linkDef
	optional bool
}

func required(source, target string) linkOpt {
	return linkOpt{linkDef: linkDef{source, target}}
}

func optional(source, target string) linkOpt {
	return linkOpt{linkDef: linkDef{source, target}, optional: true}
}

// runLinks executes a batch of link definitions and collects results.
func runLinks(ctx *Context, links []linkOpt) StepResult {
	var logs []string
	var hasErr bool

	for _, l := range links {
		source := filepath.Join(ctx.DotfilesDir, "configs", l.source)
		target := filepath.Join(ctx.HomeDir, l.target)

		// Skip optional links when source doesn't exist
		if l.optional {
			if _, err := os.Stat(source); os.IsNotExist(err) {
				logs = append(logs, link.ShortPath(target)+" (skipped — source not found)")
				continue
			}
		}

		res := link.Create(source, target, ctx.DryRun)
		logs = append(logs, res.String())
		if res.Err != nil {
			hasErr = true
		}
	}

	if hasErr {
		return StepResult{Logs: logs, Err: errSomeLinksFailed}
	}
	return StepResult{Logs: logs}
}

var errSomeLinksFailed = errorString("some links failed")

type errorString string

func (e errorString) Error() string { return string(e) }

// macOnly returns a skip result if not on macOS, otherwise runs the links.
func macOnly(ctx *Context, links []linkOpt) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only — skipping"}}
	}
	return runLinks(ctx, links)
}

func stepLinkZsh(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("zsh/zprofile.sh", ".zprofile"),
		required("zsh/zshrc.sh", ".zshrc"),
		required("zsh/aliases.sh", ".zshrc_aliases"),
		required("zsh/functions.sh", ".zshrc_functions"),
		required("zsh/paths.sh", ".zshrc_paths"),
		optional("zsh/private.sh", ".zshrc_scripts"),
	})
}

func stepLinkGit(ctx *Context) StepResult {
	links := []linkOpt{
		required("git/base.cfg", ".gitconfig"),
		required("git/global-gitignore", ".global-gitignore"),
		required("git/githooks", ".githooks"),
		optional("git/private.cfg", ".gitconfig.private"),
		optional("git/work.cfg", ".gitconfig.work"),
	}

	// Platform-specific git config
	switch ctx.Platform {
	case platform.MacOS:
		links = append(links, required("git/mac.cfg", ".gitconfig.extended"))
	case platform.Linux:
		links = append(links, required("git/linux.cfg", ".gitconfig.extended"))
	}

	return runLinks(ctx, links)
}

func stepLinkStarship(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("starship/starship.toml", ".config/starship.toml"),
	})
}

func stepLinkGhostty(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("ghostty", ".config/ghostty"),
	})
}

func stepLinkWezterm(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("wezterm", ".config/wezterm"),
	})
}

func stepLinkZellij(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("zellij", ".config/zellij"),
	})
}

func stepLinkLazygit(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("lazygit/lazygit.yml", ".config/lazygit/config.yml"),
	})
}

func stepLinkAerospace(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("aerospace", ".config/aerospace"),
	})
}

func stepLinkKarabiner(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("karabiner", ".config/karabiner"),
	})
}

func stepLinkSketchybar(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("sketchybar", ".config/sketchybar"),
	})
}

func stepLinkClaude(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("claude/settings.json", ".claude/settings.json"),
		required("claude/CLAUDE.md", ".claude/CLAUDE.md"),
		required("claude/skills", ".claude/skills"),
		required("claude/hooks", ".claude/hooks"),
	})
}

func stepLinkK9s(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("k9s", ".config/k9s"),
	})
}

func stepLinkSSH(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		optional("ssh/ssh-config", ".ssh/config"),
		optional("ssh/config.d", ".ssh/config.d"),
	})
}

func stepLinkHazel(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("hazel/com.noodlesoft.Hazel.plist", "Library/Preferences/com.noodlesoft.Hazel.plist"),
		required("hazel/Application Support", "Library/Application Support/Hazel"),
	})
}

func stepLinkVSCode(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("vscode/keybindings.json", "Library/Application Support/Code/User/keybindings.json"),
		required("vscode/settings.json", "Library/Application Support/Code/User/settings.json"),
		optional("vscode/custom.css", "Library/Application Support/Code/User/custom.css"),
		optional("vscode/custom.js", "Library/Application Support/Code/User/custom.js"),
	})
}

func stepLinkCursor(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("vscode/keybindings.json", "Library/Application Support/Cursor/User/keybindings.json"),
		required("vscode/settings.json", "Library/Application Support/Cursor/User/settings.json"),
	})
}

func stepLinkAnsible(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("ansible", ".config/ansible"),
	})
}

func stepLinkMisc(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("curlrc", ".curlrc"),
		required("hushlogin", ".hushlogin"),
		required("wgetrc", ".wgetrc"),
		required("screenrc", ".screenrc"),
	})
}
