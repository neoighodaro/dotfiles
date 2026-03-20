package installer

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

func systemSteps() []Step {
	return []Step{
		{Name: "ssh-keys", Desc: "\U000f0306 SSH keys", Run: stepSSHKeys},
		{Name: "gpg-keys", Desc: "\U000f0306 GPG keys", Run: stepGPGKeys},
		{Name: "system-defaults", Desc: "\U000f0493 System preferences", Run: stepSystemDefaults},
		{Name: "shell-default", Desc: "\uf489 Default shell", Run: stepDefaultShell},
	}
}

// ── SSH keys ──

func stepSSHKeys(ctx *Context) StepResult {
	keyPath := filepath.Join(ctx.HomeDir, ".ssh", "id_ed25519")

	if _, err := os.Stat(keyPath); err == nil {
		return StepResult{Logs: []string{"SSH key already exists"}}
	}

	if ctx.DryRun {
		return StepResult{Logs: []string{"would generate SSH key at " + keyPath}}
	}

	// Ensure .ssh directory exists
	sshDir := filepath.Join(ctx.HomeDir, ".ssh")
	if err := os.MkdirAll(sshDir, 0700); err != nil {
		return StepResult{Logs: []string{fmt.Sprintf("failed to create ~/.ssh: %s", err)}, Err: err}
	}

	// Generate key
	if err := run("ssh-keygen", "-t", "ed25519", "-f", keyPath, "-N", ""); err != nil {
		return StepResult{Logs: []string{fmt.Sprintf("key generation failed: %s", err)}, Err: err}
	}

	var logs []string
	logs = append(logs, "generated "+keyPath)

	// Add to ssh-agent
	if err := run("ssh-add", keyPath); err != nil {
		logs = append(logs, fmt.Sprintf("ssh-add failed: %s", err))
	} else {
		logs = append(logs, "added to ssh-agent")
	}

	return StepResult{Logs: logs}
}

// ── GPG keys ──

func stepGPGKeys(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}

	gnupgDir := filepath.Join(ctx.HomeDir, ".gnupg")
	agentConf := filepath.Join(gnupgDir, "gpg-agent.conf")

	var logs []string

	if ctx.DryRun {
		logs = append(logs, "would configure GPG agent with pinentry-touchid")
		return StepResult{Logs: logs}
	}

	// Create .gnupg with correct permissions
	if _, err := os.Stat(gnupgDir); os.IsNotExist(err) {
		if err := os.MkdirAll(gnupgDir, 0700); err != nil {
			return StepResult{Logs: []string{fmt.Sprintf("failed to create ~/.gnupg: %s", err)}, Err: err}
		}
		logs = append(logs, "created ~/.gnupg")
	}

	// Fix permissions
	_ = run("chmod", "700", gnupgDir)
	if entries, err := os.ReadDir(gnupgDir); err == nil {
		for _, e := range entries {
			if !e.IsDir() {
				_ = run("chmod", "600", filepath.Join(gnupgDir, e.Name()))
			}
		}
	}
	logs = append(logs, "permissions set (700/600)")

	// Find pinentry-touchid
	pinentryPath, err := exec.LookPath("pinentry-touchid")
	if err != nil {
		logs = append(logs, "pinentry-touchid not found \u2014 skipping agent config")
		return StepResult{Logs: logs}
	}

	// Configure gpg-agent.conf
	pinentryLine := "pinentry-program " + pinentryPath
	needsUpdate := true

	if data, err := os.ReadFile(agentConf); err == nil {
		if strings.Contains(string(data), pinentryLine) {
			needsUpdate = false
			logs = append(logs, "gpg-agent.conf already configured")
		}
	}

	if needsUpdate {
		// Create or overwrite with pinentry config
		if err := os.WriteFile(agentConf, []byte(pinentryLine+"\n"), 0600); err != nil {
			logs = append(logs, fmt.Sprintf("failed to write gpg-agent.conf: %s", err))
		} else {
			logs = append(logs, "gpg-agent.conf updated with pinentry-touchid")
		}
	}

	// Fix pinentry-touchid
	_ = run("pinentry-touchid", "-fix")

	// Reload gpg-agent
	_ = run("gpg-connect-agent", "reloadagent", "/bye")
	logs = append(logs, "gpg-agent reloaded")

	// Disable GPG keychain
	_ = run("defaults", "write", "org.gpgtools.common", "DisableKeychain", "-bool", "yes")
	logs = append(logs, "GPG keychain disabled")

	return StepResult{Logs: logs}
}

// ── System preferences ──

func stepSystemDefaults(ctx *Context) StepResult {
	switch ctx.Platform {
	case platform.MacOS:
		return applyMacDefaults(ctx)
	case platform.Linux:
		return applyLinuxDefaults(ctx)
	default:
		return StepResult{Skip: true, Logs: []string{"unsupported platform"}}
	}
}

func applyMacDefaults(ctx *Context) StepResult {
	type defaultsCmd struct {
		args    []string
		comment string
	}

	commands := []defaultsCmd{
		// Dock
		{[]string{"write", "com.apple.dock", "persistent-apps", "-array"}, "clear dock apps"},
		{[]string{"write", "com.apple.dock", "minimize-to-application", "-bool", "true"}, "minimize to app icon"},
		{[]string{"write", "com.apple.dock", "magnification", "-bool", "false"}, "disable magnification"},
		{[]string{"write", "com.apple.dock", "mineffect", "-string", "scale"}, "scale minimize effect"},
		{[]string{"write", "com.apple.dock", "autohide", "-bool", "true"}, "auto-hide dock"},
		{[]string{"write", "com.apple.dock", "autohide-delay", "-float", "1"}, "dock auto-hide delay"},
		{[]string{"write", "com.apple.dock", "autohide-time-modifier", "-float", "0"}, "instant dock hide"},
		{[]string{"write", "com.apple.dock", "launchanim", "-bool", "false"}, "disable launch animation"},
		{[]string{"write", "com.apple.dock", "tilesize", "-int", "37"}, "dock tile size 37"},
		{[]string{"write", "com.apple.dock", "wvous-bl-corner", "-int", "4"}, "hot corner: bottom-left → desktop"},
		{[]string{"write", "com.apple.dock", "wvous-bl-modifier", "-int", "0"}, "hot corner modifier"},
		{[]string{"write", "com.apple.dock", "show-recents", "-int", "0"}, "hide recents"},
		{[]string{"write", "com.apple.dock", "expose-group-apps", "-int", "1"}, "group windows in expose"},

		// Finder
		{[]string{"write", "com.apple.finder", "EmptyTrashSecurely", "-bool", "true"}, "secure empty trash"},
		{[]string{"write", "com.apple.finder", "WarnOnEmptyTrash", "-bool", "false"}, "no trash warning"},
		{[]string{"write", "com.apple.finder", "FXEnableExtensionChangeWarning", "-bool", "false"}, "no extension warning"},
		{[]string{"write", "com.apple.finder", "ShowPathbar", "-bool", "true"}, "show path bar"},
		{[]string{"write", "com.apple.finder", "ShowStatusBar", "-bool", "true"}, "show status bar"},
		{[]string{"write", "com.apple.finder", "QuitMenuItem", "-bool", "true"}, "enable quit menu"},
		{[]string{"write", "com.apple.finder", "QLEnableTextSelection", "-bool", "true"}, "quick look text selection"},
		{[]string{"write", "com.apple.finder", "FXPreferredViewStyle", "-string", "clmv"}, "column view"},
		{[]string{"write", "com.apple.finder", "FXDefaultSearchScope", "-string", "SCcf"}, "search current folder"},
		{[]string{"write", "com.apple.finder", "_FXSortFoldersFirst", "-bool", "true"}, "sort folders first"},
		{[]string{"write", "com.apple.finder", "ShowRecentTags", "-bool", "false"}, "hide recent tags"},
		{[]string{"write", "com.apple.Finder", "SidebarTagsSctionDisclosedState", "-bool", "false"}, "hide sidebar tags"},
		{[]string{"write", "com.apple.Finder", "SidebarDevicesSectionDisclosedState", "-bool", "false"}, "hide sidebar devices"},
		{[]string{"write", "com.apple.finder", "NewWindowTarget", "-string", "PfHm"}, "new window → home"},
		{[]string{"write", "com.apple.finder", "ShowExternalHardDrivesOnDesktop", "-bool", "false"}, "hide external drives"},
		{[]string{"write", "com.apple.finder", "ShowRemovableMediaOnDesktop", "-bool", "false"}, "hide removable media"},
		{[]string{"write", "com.apple.finder", "FinderSpawnTab", "-int", "1"}, "open folders in tabs"},

		// Global
		{[]string{"write", "NSGlobalDomain", "NSAutomaticSpellingCorrectionEnabled", "-bool", "false"}, "disable autocorrect"},
		{[]string{"write", "NSGlobalDomain", "AppleShowAllExtensions", "-bool", "true"}, "show all extensions"},
		{[]string{"write", "NSGlobalDomain", "NSNavPanelExpandedStateForSaveMode", "-bool", "true"}, "expand save panel"},
		{[]string{"write", "NSGlobalDomain", "_HIHideMenuBar", "-bool", "true"}, "auto-hide menu bar"},

		// Window Manager
		{[]string{"write", "com.apple.WindowManager", "EnableStandardClickToShowDesktop", "-bool", "false"}, "disable click-to-desktop"},
		{[]string{"write", "com.apple.WindowManager", "StandardHideDesktopIcons", "-bool", "true"}, "hide desktop icons"},
		{[]string{"write", "com.apple.WindowManager", "HideDesktop", "-bool", "true"}, "hide desktop (stage mgr)"},
		{[]string{"write", "com.apple.WindowManager", "StageManagerHideWidgets", "-bool", "true"}, "hide widgets (stage mgr)"},
		{[]string{"write", "com.apple.WindowManager", "StandardHideWidgets", "-bool", "false"}, "show widgets (normal)"},

		// Others
		{[]string{"write", "com.apple.menuextra.battery", "ShowTime", "-string", "YES"}, "show battery time"},
		{[]string{"write", "com.apple.screensaver", "askForPassword", "-int", "1"}, "password on screensaver"},
		{[]string{"write", "com.apple.screensaver", "askForPasswordDelay", "-int", "0"}, "immediate password"},
		{[]string{"write", "com.apple.desktopservices", "DSDontWriteNetworkStores", "-bool", "true"}, "no .DS_Store on network"},
		{[]string{"write", "com.apple.Siri", "StatusMenuVisible", "-int", "0"}, "hide Siri menu"},
		{[]string{"write", "com.apple.Siri", "VoiceTriggerUserEnabled", "-int", "0"}, "disable Siri voice"},
		{[]string{"write", "com.apple.Siri", "ConfirmSiriInvokedViaEitherCmdTwice", "-int", "0"}, "disable Siri confirm"},
		{[]string{"write", "com.apple.HIToolbox", "AppleFnUsageType", "-int", "0"}, "disable globe key"},
		{[]string{"write", "com.apple.HIToolbox", "AppleDictationAutoEnable", "-int", "0"}, "disable dictation"},
		{[]string{"write", "com.apple.TextInputMenu", "visible", "-bool", "false"}, "hide text input menu"},
		{[]string{"write", "NSGlobalDomain", "SLSMenuBarUseBlurredAppearance", "-bool", "true"}, "blurred menu bar"},
	}

	// Screenshot location
	screenshotDir := filepath.Join(ctx.HomeDir, "Documents", "• Screenshots")
	commands = append(commands, defaultsCmd{
		args:    []string{"write", "com.apple.screencapture", "location", "-string", screenshotDir},
		comment: "screenshots → Documents/• Screenshots",
	})

	if ctx.DryRun {
		return StepResult{Logs: []string{fmt.Sprintf("would apply %d macOS defaults", len(commands))}}
	}

	var failed int
	for _, cmd := range commands {
		if err := run("defaults", cmd.args...); err != nil {
			failed++
		}
	}

	var logs []string
	logs = append(logs, fmt.Sprintf("applied %d preferences", len(commands)-failed))
	if failed > 0 {
		logs = append(logs, fmt.Sprintf("%d failed", failed))
	}

	// Unhide ~/Library
	_ = run("chflags", "nohidden", filepath.Join(ctx.HomeDir, "Library"))
	logs = append(logs, "~/Library unhidden")

	// Disable Spotlight shortcut (Cmd+Space) to free it for other tools
	_ = run("/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings", "-u")

	// Kill affected apps to apply changes
	for _, app := range []string{"Finder", "Dock", "SystemUIServer", "WindowManager", "cfprefsd"} {
		_ = run("killall", app)
	}
	logs = append(logs, "restarted Finder, Dock, SystemUIServer")

	return StepResult{Logs: logs}
}

func applyLinuxDefaults(ctx *Context) StepResult {
	var logs []string

	if ctx.DryRun {
		return StepResult{Logs: []string{"would configure Linux system settings"}}
	}

	// Locale
	out, _ := exec.Command("cat", "/etc/locale.gen").Output()
	if !strings.Contains(string(out), "en_US.UTF-8") {
		if err := run("sudo", "locale-gen", "en_US.UTF-8"); err != nil {
			logs = append(logs, fmt.Sprintf("locale-gen failed: %s", err))
		} else {
			logs = append(logs, "locale set to en_US.UTF-8")
		}
	} else {
		logs = append(logs, "locale already set")
	}

	// SSH hardening
	sshdConf := "/etc/ssh/sshd_config"
	if data, err := os.ReadFile(sshdConf); err == nil {
		content := string(data)
		changed := false
		replacements := map[string]string{
			"UsePAM yes":                "UsePAM no",
			"PermitRootLogin yes":       "PermitRootLogin no",
			"PasswordAuthentication yes": "PasswordAuthentication no",
		}
		for old, new := range replacements {
			if strings.Contains(content, old) {
				content = strings.ReplaceAll(content, old, new)
				changed = true
			}
		}
		if changed {
			// Write via sudo
			cmd := exec.Command("sudo", "tee", sshdConf)
			cmd.Stdin = strings.NewReader(content)
			if err := cmd.Run(); err != nil {
				logs = append(logs, fmt.Sprintf("sshd_config update failed: %s", err))
			} else {
				_ = run("sudo", "systemctl", "restart", "ssh")
				logs = append(logs, "SSH hardened (PAM, root login, password auth disabled)")
			}
		} else {
			logs = append(logs, "SSH already hardened")
		}
	}

	return StepResult{Logs: logs}
}

// ── Default shell ──

func stepDefaultShell(ctx *Context) StepResult {
	currentShell := os.Getenv("SHELL")
	if strings.HasSuffix(currentShell, "/zsh") {
		return StepResult{Logs: []string{"already using zsh"}}
	}

	zshPath, err := exec.LookPath("zsh")
	if err != nil {
		return StepResult{Logs: []string{"zsh not found"}, Err: fmt.Errorf("zsh not found")}
	}

	if ctx.DryRun {
		return StepResult{Logs: []string{fmt.Sprintf("would set default shell to %s", zshPath)}}
	}

	if err := run("chsh", "-s", zshPath); err != nil {
		return StepResult{Logs: []string{fmt.Sprintf("chsh failed: %s", err)}, Err: err}
	}

	return StepResult{Logs: []string{fmt.Sprintf("default shell set to %s", zshPath)}}
}
