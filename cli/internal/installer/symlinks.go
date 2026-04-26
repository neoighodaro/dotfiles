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
		{Name: "link-aerospace", Desc: "\uf2d2 Aerospace", Run: stepLinkAerospace},
		{Name: "link-ansible", Desc: "\U000f048d Ansible", Run: stepLinkAnsible},
		{Name: "link-claude", Desc: "\U000f06a9 Claude Code", Run: stepLinkClaude},
		{Name: "link-cursor", Desc: "\U000f0a1e Cursor", Run: stepLinkCursor},
		{Name: "link-ghostty", Desc: "\U000f02a0 Ghostty", Run: stepLinkGhostty},
		{Name: "link-git", Desc: "\ue702 Git", Run: stepLinkGit},
		{Name: "link-k9s", Desc: "\U000f10fe K9s", Run: stepLinkK9s},
		{Name: "link-karabiner", Desc: "\U000f030c Karabiner-Elements", Run: stepLinkKarabiner},
		{Name: "link-lazygit", Desc: "\ue702 Lazygit", Run: stepLinkLazygit},
		{Name: "link-sketchybar", Desc: "\uee19 Sketchybar", Run: stepLinkSketchybar},
		{Name: "link-ssh", Desc: "\U000f0306 SSH", Run: stepLinkSSH},
		{Name: "link-starship", Desc: "\uf489 Starship", Run: stepLinkStarship},
		{Name: "link-superwhisper", Desc: "\U000f036c Superwhisper", Run: stepLinkSuperwhisper},
		{Name: "link-vscode", Desc: "\U000f0a1e VS Code", Run: stepLinkVSCode},
		{Name: "link-wezterm", Desc: "\uf489 Wezterm", Run: stepLinkWezterm},
		{Name: "link-worktrunk", Desc: "\U000f0493 Worktrunk", Run: stepLinkWorktrunk},
		{Name: "link-zellij", Desc: "\uf0db Zellij", Run: stepLinkZellij},
		{Name: "link-zsh", Desc: "\uf489 ZSH", Run: stepLinkZsh},
		{Name: "link-misc", Desc: "\uf141 Miscellaneous", Run: stepLinkMisc},
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
	// Create empty .gitignore.work if it doesn't exist
	workIgnore := filepath.Join(ctx.DotfilesDir, "configs", "git", "work.cfg")
	if _, err := os.Stat(workIgnore); os.IsNotExist(err) {
		if !ctx.DryRun {
			_ = os.WriteFile(workIgnore, []byte{}, 0644)
		}
	}

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

func stepLinkWorktrunk(ctx *Context) StepResult {
	return runLinks(ctx, []linkOpt{
		required("worktrunk", ".config/worktrunk"),
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

func stepLinkSuperwhisper(ctx *Context) StepResult {
	return macOnly(ctx, []linkOpt{
		required("superwhisper/modes", "Documents/superwhisper/modes"),
		required("superwhisper/settings", "Documents/superwhisper/settings"),
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
