package installer

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

// brewPkg defines a Homebrew formula with an optional tap.
type brewPkg struct {
	name string
	tap  string // e.g. "jorgelbg/tap" — empty means default
}

// caskPkg defines a Homebrew cask with an optional custom install URL.
type caskPkg struct {
	name string
	url  string // custom cask URL (rare)
}

// masApp defines a Mac App Store app.
type masApp struct {
	name string
	id   string
}

// ignoredPackages lists packages to skip during installation.
// Add a formula, cask, or app name here to silently skip it.
var ignoredPackages = map[string]bool{
	"jordanbaird-ice": true,
}

// ── Package lists ──

var brewFormulae = []brewPkg{
	{name: "trash"},
	{name: "gnupg"},
	{name: "pinentry-mac"},
	{name: "pinentry-touchid", tap: "jorgelbg/tap"},
	{name: "zsh-autosuggestions"},
	{name: "zsh-syntax-highlighting"},
	{name: "starship"},
	{name: "eza"},
	{name: "bat"},
	{name: "zoxide"},
	{name: "fzf"},
	{name: "zellij"},
	{name: "lazygit"},
	{name: "git-delta"},
	{name: "bun", tap: "oven-sh/bun"},
	{name: "folderify"},
	{name: "sketchybar", tap: "FelixKratz/formulae"},
	{name: "font-sketchybar-app-font"},
	{name: "jq"},
	{name: "xh"},
	{name: "kubectx"},
	{name: "helm"},
	{name: "ansible"},
	{name: "ansible-lint"},
	{name: "ripgrep"},
	{name: "fd"},
	{name: "nushell"},
	{name: "worktrunk"},
}

var aptPackages = []string{
	"gnupg",
	"zsh-autosuggestions",
	"zsh-syntax-highlighting",
	"eza",
	"bat",
	"zoxide",
	"unzip",
	"xh",
	"git-delta",
}

var brewCasks = []caskPkg{
	{name: "cursor"},
	{name: "claude-code"},
	{name: "ghostty"},
	{name: "affinity"},
	{name: "1password"},
	{name: "nordvpn"},
	{name: "docker"},
	{name: "arc"},
	{name: "zen"},
	{name: "font-jetbrains-mono-nerd-font"},
	{name: "font-hack-nerd-font"},
	{name: "visual-studio-code"},
	{name: "phpstorm"},
	{name: "hazel"},
	{name: "jordanbaird-ice"},
	{name: "herd"},
	{name: "raycast"},
	{name: "nikitabobko/tap/aerospace"},
	{name: "ray"},
	{name: "boop"},
	{name: "tableplus"},
	{name: "sensei"},
	{name: "postman"},
	{name: "tinkerwell"},
	{name: "gitkraken"},
	{name: "karabiner-elements"},
	{name: "font-sf-pro"},
	{name: "sketch", url: "https://raw.githubusercontent.com/Homebrew/homebrew-cask/5c951dd3412c1ae1764924888f29058ed0991162/Casks/s/sketch.rb"},
	{name: "wezterm"},
}

var masApps = []masApp{
	{name: "DropOver", id: "1355679052"},
	{name: "RocketSim", id: "1504940162"},
}

func packageSteps() []Step {
	return []Step{
		{Name: "install-brew", Desc: "Homebrew formulae", Run: stepInstallBrew},
		{Name: "install-casks", Desc: "Homebrew casks", Run: stepInstallCasks},
		{Name: "install-mas", Desc: "AppStore apps", Run: stepInstallMas},
	}
}

// ── Steps ──

func stepInstallBrew(ctx *Context) StepResult {
	switch ctx.Platform {
	case platform.MacOS:
		return installBrewFormulae(ctx)
	case platform.Linux:
		return installAptPackages(ctx)
	default:
		return StepResult{Skip: true, Logs: []string{"unsupported platform"}}
	}
}

func stepInstallCasks(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}
	return installBrewCasks(ctx)
}

func stepInstallMas(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}

	// Check which apps are missing by looking in /Applications
	var missing []masApp
	var logs []string
	for _, app := range masApps {
		if ignoredPackages[app.name] {
			logs = append(logs, fmt.Sprintf("%s (ignored)", app.name))
			continue
		}
		if isMacAppInstalled(app.name) {
			logs = append(logs, fmt.Sprintf("%s (already installed)", app.name))
		} else {
			missing = append(missing, app)
		}
	}

	// All present — nothing to do
	if len(missing) == 0 {
		return StepResult{Logs: logs}
	}

	if ctx.DryRun {
		for _, app := range missing {
			logs = append(logs, fmt.Sprintf("%s (would install via mas)", app.name))
		}
		return StepResult{Logs: logs}
	}

	// Install mas if not available
	masInstalled := exec.Command("brew", "list", "--formula", "mas").Run() == nil
	if _, err := exec.LookPath("mas"); err != nil {
		if err := run("brew", "install", "mas"); err != nil {
			logs = append(logs, fmt.Sprintf("failed to install mas: %s", err))
			return StepResult{Logs: logs, Err: errorString("mas is required to install AppStore apps")}
		}
		logs = append(logs, "mas (installed temporarily)")
	}

	// Install missing apps
	var hasErr bool
	for _, app := range missing {
		if err := run("mas", "install", app.id); err != nil {
			logs = append(logs, fmt.Sprintf("%s (failed: %s)", app.name, err))
			hasErr = true
		} else {
			logs = append(logs, fmt.Sprintf("%s (installed)", app.name))
		}
	}

	// Clean up mas if we installed it
	if !masInstalled {
		if err := run("brew", "uninstall", "mas"); err != nil {
			logs = append(logs, fmt.Sprintf("failed to uninstall mas: %s", err))
		} else {
			logs = append(logs, "mas (uninstalled)")
		}
	}

	if hasErr {
		return StepResult{Logs: logs, Err: errorString("some AppStore apps failed to install")}
	}
	return StepResult{Logs: logs}
}

// ── Brew formulae ──

func installBrewFormulae(ctx *Context) StepResult {
	installed := brewInstalledFormulae()
	var logs []string
	var hasErr bool

	for _, pkg := range brewFormulae {
		if ignoredPackages[pkg.name] {
			logs = append(logs, fmt.Sprintf("%s (ignored)", pkg.name))
			continue
		}
		if installed[pkg.name] {
			logs = append(logs, fmt.Sprintf("%s (already installed)", pkg.name))
			continue
		}

		fullName := pkg.name
		if pkg.tap != "" {
			fullName = pkg.tap + "/" + pkg.name
		}

		if ctx.DryRun {
			logs = append(logs, fmt.Sprintf("%s (would install)", fullName))
			continue
		}

		// Tap first if needed
		if pkg.tap != "" {
			if err := run("brew", "tap", pkg.tap); err != nil {
				logs = append(logs, fmt.Sprintf("%s tap failed: %s", pkg.tap, err))
				hasErr = true
				continue
			}
		}

		if err := run("brew", "install", fullName); err != nil {
			logs = append(logs, fmt.Sprintf("%s (failed: %s)", fullName, err))
			hasErr = true
		} else {
			logs = append(logs, fmt.Sprintf("%s (installed)", fullName))
		}
	}

	if hasErr {
		return StepResult{Logs: logs, Err: errorString("some formulae failed to install")}
	}
	return StepResult{Logs: logs}
}

// ── Apt packages ──

func installAptPackages(ctx *Context) StepResult {
	var logs []string
	var hasErr bool

	for _, pkg := range aptPackages {
		if ignoredPackages[pkg] {
			logs = append(logs, fmt.Sprintf("%s (ignored)", pkg))
			continue
		}
		if isAptInstalled(pkg) {
			logs = append(logs, fmt.Sprintf("%s (already installed)", pkg))
			continue
		}

		if ctx.DryRun {
			logs = append(logs, fmt.Sprintf("%s (would install)", pkg))
			continue
		}

		if err := run("sudo", "apt-get", "install", "-y", pkg); err != nil {
			logs = append(logs, fmt.Sprintf("%s (failed: %s)", pkg, err))
			hasErr = true
		} else {
			logs = append(logs, fmt.Sprintf("%s (installed)", pkg))
		}
	}

	if hasErr {
		return StepResult{Logs: logs, Err: errorString("some packages failed to install")}
	}
	return StepResult{Logs: logs}
}

// ── Brew casks ──

func installBrewCasks(ctx *Context) StepResult {
	installed := brewInstalledCasks()
	var logs []string
	var hasErr bool

	for _, cask := range brewCasks {
		if ignoredPackages[cask.name] {
			logs = append(logs, fmt.Sprintf("%s (ignored)", cask.name))
			continue
		}
		// Normalize name for checking (e.g. "nikitabobko/tap/aerospace" → "aerospace")
		checkName := cask.name
		if parts := strings.Split(cask.name, "/"); len(parts) > 1 {
			checkName = parts[len(parts)-1]
		}

		if installed[checkName] {
			logs = append(logs, fmt.Sprintf("%s (already installed)", cask.name))
			continue
		}

		if ctx.DryRun {
			logs = append(logs, fmt.Sprintf("%s (would install)", cask.name))
			continue
		}

		if cask.url != "" {
			if err := run("brew", "install", "--cask", cask.url); err != nil {
				logs = append(logs, fmt.Sprintf("%s (failed: %s)", cask.name, err))
				hasErr = true
			} else {
				logs = append(logs, fmt.Sprintf("%s (installed)", cask.name))
			}
		} else {
			if err := run("brew", "install", "--cask", cask.name); err != nil {
				logs = append(logs, fmt.Sprintf("%s (failed: %s)", cask.name, err))
				hasErr = true
			} else {
				logs = append(logs, fmt.Sprintf("%s (installed)", cask.name))
			}
		}
	}

	if hasErr {
		return StepResult{Logs: logs, Err: errorString("some casks failed to install")}
	}
	return StepResult{Logs: logs}
}


// ── Helpers ──

// run executes a command and returns any error.
func run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("%w: %s", err, strings.TrimSpace(string(out)))
	}
	return nil
}

// brewInstalledFormulae returns a set of currently installed brew formulae.
func brewInstalledFormulae() map[string]bool {
	return cmdOutputSet("brew", "list", "--formula")
}

// brewInstalledCasks returns a set of currently installed brew casks.
func brewInstalledCasks() map[string]bool {
	return cmdOutputSet("brew", "list", "--cask")
}

// cmdOutputSet runs a command and returns each output line as a set entry.
func cmdOutputSet(name string, args ...string) map[string]bool {
	out, err := exec.Command(name, args...).Output()
	if err != nil {
		return nil
	}
	set := make(map[string]bool)
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if line = strings.TrimSpace(line); line != "" {
			set[line] = true
		}
	}
	return set
}

// isAptInstalled checks if a package is installed via dpkg.
func isAptInstalled(pkg string) bool {
	return exec.Command("dpkg", "-s", pkg).Run() == nil
}

// isMacAppInstalled checks if an app exists in /Applications (case-insensitive).
func isMacAppInstalled(name string) bool {
	entries, err := os.ReadDir("/Applications")
	if err != nil {
		return false
	}
	lower := strings.ToLower(name)
	for _, e := range entries {
		if strings.Contains(strings.ToLower(e.Name()), lower) {
			return true
		}
	}
	return false
}
