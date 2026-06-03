package installer

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/neoighodaro/dotfiles/cli/internal/link"
	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

func postInstallSteps() []Step {
	return []Step{
		{Name: "create-dirs", Desc: "\U000f024b Directories", Run: stepCreateDirs},
		{Name: "link-scripts", Desc: "\U000f0306 Scripts", Run: stepLinkScripts},
		{Name: "cursor-extensions", Desc: "\U000f0a1e Cursor extensions", Run: stepCursorExtensions},
		{Name: "sketchybar-setup", Desc: "\uee19 Sketchybar", Run: stepSketchybarSetup},
		{Name: "set-wallpaper", Desc: "\U000f00be Wallpaper", Run: stepSetWallpaper},
		{Name: "zellij-plugins", Desc: "\uf0db Zellij plugins", Run: stepZellijPlugins},
		{Name: "default-browser", Desc: "\U000f0288 Default browser", Run: stepDefaultBrowser},
		{Name: "folder-icons", Desc: "\U000f024b Folder icons", Run: stepFolderIcons},
	}
}

// ── Directories ──

var macDirs = []string{
	"Developer",
	"Developer/bin",
	"Downloads/• Trashable",
	"Downloads/• Keep",
	"Documents/• Screenshots",
	"Documents/• Unsorted",
}

var linuxDirs = []string{
	"Developer",
	"Developer/bin",
}

func stepCreateDirs(ctx *Context) StepResult {
	var dirs []string
	switch ctx.Platform {
	case platform.MacOS:
		dirs = macDirs
	default:
		dirs = linuxDirs
	}

	var logs []string
	for _, dir := range dirs {
		full := filepath.Join(ctx.HomeDir, dir)
		if _, err := os.Stat(full); err == nil {
			logs = append(logs, fmt.Sprintf("~/%s (exists)", dir))
			continue
		}
		if ctx.DryRun {
			logs = append(logs, fmt.Sprintf("~/%s (would create)", dir))
			continue
		}
		if err := os.MkdirAll(full, 0755); err != nil {
			logs = append(logs, fmt.Sprintf("~/%s (failed: %s)", dir, err))
		} else {
			logs = append(logs, fmt.Sprintf("~/%s (created)", dir))
		}
	}
	return StepResult{Logs: logs}
}

// ── Scripts ──

func stepLinkScripts(ctx *Context) StepResult {
	scriptsDir := filepath.Join(ctx.DotfilesDir, "scripts")
	binDir := filepath.Join(ctx.HomeDir, "Developer", "bin")

	entries, err := os.ReadDir(scriptsDir)
	if err != nil {
		return StepResult{Logs: []string{"scripts/ dir not found"}, Skip: true}
	}

	var logs []string
	var hasErr bool

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		// Skip hidden/system files
		if strings.HasPrefix(name, ".") {
			continue
		}
		// Strip file extension for the target name
		nameNoExt := strings.TrimSuffix(name, filepath.Ext(name))

		source := filepath.Join(scriptsDir, name)
		target := filepath.Join(binDir, nameNoExt)

		res := link.Create(source, target, ctx.DryRun)
		logs = append(logs, res.String())
		if res.Err != nil {
			hasErr = true
		}
	}

	// Link the strap CLI binary itself
	strapSource := filepath.Join(ctx.DotfilesDir, "cli", "strap")
	strapTarget := filepath.Join(binDir, "strap")
	if _, err := os.Stat(strapSource); err == nil {
		res := link.Create(strapSource, strapTarget, ctx.DryRun)
		logs = append(logs, res.String())
		if res.Err != nil {
			hasErr = true
		}
	}

	if hasErr {
		return StepResult{Logs: logs, Err: errorString("some script links failed")}
	}
	return StepResult{Logs: logs}
}

// ── Cursor extensions ──

func stepCursorExtensions(ctx *Context) StepResult {
	// Check if cursor CLI is available
	if _, err := exec.LookPath("cursor"); err != nil {
		return StepResult{Skip: true, Logs: []string{"cursor CLI not found \u2014 skipping"}}
	}

	extFile := filepath.Join(ctx.DotfilesDir, "configs", "cursor", "extensions.txt")
	data, err := os.ReadFile(extFile)
	if err != nil {
		return StepResult{Skip: true, Logs: []string{"configs/cursor/extensions.txt not found \u2014 skipping"}}
	}

	// Get currently installed extensions
	installed := cursorInstalledExtensions()

	var logs []string
	var installCount, skipCount int

	for _, line := range strings.Split(string(data), "\n") {
		ext := strings.TrimSpace(line)
		if ext == "" {
			continue
		}

		if installed[strings.ToLower(ext)] {
			skipCount++
			continue
		}

		if ctx.DryRun {
			logs = append(logs, fmt.Sprintf("%s (would install)", ext))
			continue
		}

		if err := run("cursor", "--install-extension", ext); err != nil {
			logs = append(logs, fmt.Sprintf("%s (failed)", ext))
		} else {
			installCount++
		}
	}

	summary := fmt.Sprintf("%d installed, %d already present", installCount, skipCount)
	if ctx.DryRun {
		summary = fmt.Sprintf("%d already present", skipCount)
	}
	logs = append(logs, summary)

	return StepResult{Logs: logs}
}

func cursorInstalledExtensions() map[string]bool {
	out, err := exec.Command("cursor", "--list-extensions").Output()
	if err != nil {
		return nil
	}
	set := make(map[string]bool)
	for _, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if ext := strings.TrimSpace(line); ext != "" {
			set[strings.ToLower(ext)] = true
		}
	}
	return set
}

// ── Sketchybar ──

func stepSketchybarSetup(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}

	// Check if sketchybar is installed
	if _, err := exec.LookPath("sketchybar"); err != nil {
		return StepResult{Skip: true, Logs: []string{"sketchybar not installed \u2014 skipping"}}
	}

	var logs []string

	// Update icon map from latest sketchybar-app-font release (at most once per week)
	stampFile := filepath.Join(ctx.DotfilesDir, ".sketchybar-icons-updated")
	needsUpdate := true
	if info, err := os.Stat(stampFile); err == nil {
		if time.Since(info.ModTime()) < 7*24*time.Hour {
			needsUpdate = false
			logs = append(logs, "icon map up to date (checked within last week)")
		}
	}

	if needsUpdate {
		updateScript := filepath.Join(ctx.DotfilesDir, "scripts", "update-sketchybar-icons.sh")
		if _, err := os.Stat(updateScript); err == nil {
			if ctx.DryRun {
				logs = append(logs, "would update icon map")
			} else {
				cmd := exec.Command("bash", updateScript)
				cmd.Env = append(os.Environ(), "DOTFILES_DIR="+ctx.DotfilesDir)
				if out, err := cmd.CombinedOutput(); err != nil {
					logs = append(logs, fmt.Sprintf("icon map update failed: %s", strings.TrimSpace(string(out))))
				} else {
					logs = append(logs, "icon map updated")
					// Write timestamp file
					_ = os.WriteFile(stampFile, []byte(time.Now().Format(time.RFC3339)), 0644)
				}
			}
		}
	}

	// Ensure sketchybar service is running
	if ctx.DryRun {
		logs = append(logs, "would start/reload sketchybar")
	} else {
		// Check if already running via brew services
		out, _ := exec.Command("brew", "services", "list").Output()
		if !strings.Contains(string(out), "sketchybar") || !strings.Contains(string(out), "started") {
			_ = run("brew", "services", "start", "sketchybar")
			logs = append(logs, "sketchybar service started")
		} else {
			logs = append(logs, "sketchybar service already running")
		}

		if err := run("sketchybar", "--reload"); err != nil {
			logs = append(logs, fmt.Sprintf("reload failed: %s", err))
		} else {
			logs = append(logs, "sketchybar reloaded")
		}
	}

	return StepResult{Logs: logs}
}

// ── Wallpaper ──

func stepSetWallpaper(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}

	// Check for skip file
	skipFile := filepath.Join(ctx.HomeDir, "Pictures", "wallpaper.skip")
	if _, err := os.Stat(skipFile); err == nil {
		return StepResult{Skip: true, Logs: []string{"wallpaper.skip found \u2014 skipping"}}
	}

	// Find wallpaper in dotfiles
	wallpapersDir := filepath.Join(ctx.DotfilesDir, "wallpapers")
	var sourceExt string
	for _, ext := range []string{"heic", "jpg", "jpeg", "png"} {
		candidate := filepath.Join(wallpapersDir, "wallpaper."+ext)
		if _, err := os.Stat(candidate); err == nil {
			sourceExt = ext
			break
		}
	}

	if sourceExt == "" {
		return StepResult{Skip: true, Logs: []string{"no wallpaper found in wallpapers/"}}
	}

	source := filepath.Join(wallpapersDir, "wallpaper."+sourceExt)
	target := filepath.Join(ctx.HomeDir, "Pictures", "wallpaper."+sourceExt)

	var logs []string

	// Check if wallpaper already exists at target
	if _, err := os.Stat(target); err == nil {
		// Already there — check if it's our symlink
		if info, err := os.Lstat(target); err == nil && info.Mode()&os.ModeSymlink != 0 {
			existing, _ := os.Readlink(target)
			if existing == source {
				logs = append(logs, link.ShortPath(target)+" (already linked)")
			}
		}
	} else {
		// Link the wallpaper
		res := link.Create(source, target, ctx.DryRun)
		logs = append(logs, res.String())
		if res.Err != nil {
			return StepResult{Logs: logs, Err: res.Err}
		}
	}

	// Set the wallpaper via osascript
	if ctx.DryRun {
		logs = append(logs, "would set desktop wallpaper")
	} else {
		script := fmt.Sprintf(`tell application "System Events" to set picture of every desktop to POSIX file %q`, target)
		if err := run("osascript", "-e", script); err != nil {
			logs = append(logs, fmt.Sprintf("failed to set wallpaper: %s", err))
		} else {
			logs = append(logs, "desktop wallpaper set")
		}
	}

	return StepResult{Logs: logs}
}

// ── Zellij plugins ──

func stepZellijPlugins(ctx *Context) StepResult {
	pluginDir := filepath.Join(ctx.HomeDir, ".config", "zellij", "plugins")
	wasmPath := filepath.Join(pluginDir, "zjstatus.wasm")

	if _, err := os.Stat(wasmPath); err == nil {
		return StepResult{Logs: []string{"zjstatus.wasm already installed"}}
	}

	if ctx.DryRun {
		return StepResult{Logs: []string{"would download zjstatus.wasm"}}
	}

	if err := os.MkdirAll(pluginDir, 0755); err != nil {
		return StepResult{Logs: []string{fmt.Sprintf("failed to create plugin dir: %s", err)}, Err: err}
	}

	if err := run("curl", "-L", "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm", "-o", wasmPath); err != nil {
		return StepResult{Logs: []string{fmt.Sprintf("download failed: %s", err)}, Err: err}
	}
	_ = run("chmod", "a+x", wasmPath)

	return StepResult{Logs: []string{"zjstatus.wasm installed"}}
}

// ── Default browser ──

func stepDefaultBrowser(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}

	// Check current default browser via the HTTP handler in Launch Services
	// plutil outputs the plist as readable text; we look for the https handler
	out, _ := exec.Command("bash", "-c",
		`defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist LSHandlers 2>/dev/null`).Output()
	outStr := strings.ToLower(string(out))

	// Look for the https scheme handler — Zen's bundle ID contains "zen"
	// Split by entries and find the one with URLScheme = https
	if strings.Contains(outStr, "urlscheme = https") {
		// Find the block containing https and check if zen is the handler
		parts := strings.Split(outStr, "{")
		for _, part := range parts {
			if strings.Contains(part, "urlscheme = https") && strings.Contains(part, "zen") {
				return StepResult{Logs: []string{"Zen is already the default browser"}}
			}
		}
	}

	if ctx.DryRun {
		return StepResult{Logs: []string{"would set Zen as default browser"}}
	}

	var logs []string

	// Check if Zen is even installed
	if !isMacAppInstalled("Zen") {
		return StepResult{Skip: true, Logs: []string{"Zen not installed \u2014 skipping"}}
	}

	// Install defaultbrowser temporarily if not present
	hadDefaultBrowser := exec.Command("brew", "list", "--formula", "defaultbrowser").Run() == nil
	if !hadDefaultBrowser {
		if err := run("brew", "install", "defaultbrowser"); err != nil {
			return StepResult{Logs: []string{fmt.Sprintf("failed to install defaultbrowser: %s", err)}, Err: err}
		}
	}

	if err := run("defaultbrowser", "zen"); err != nil {
		logs = append(logs, fmt.Sprintf("failed to set default browser: %s", err))
	} else {
		logs = append(logs, "Zen set as default browser")
	}

	// Clean up if we installed it
	if !hadDefaultBrowser {
		_ = run("brew", "uninstall", "defaultbrowser")
	}

	return StepResult{Logs: logs}
}

// ── Folder icons ──

func stepFolderIcons(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}

	if _, err := exec.LookPath("folderify"); err != nil {
		return StepResult{Skip: true, Logs: []string{"folderify not installed \u2014 skipping"}}
	}

	maskPath := filepath.Join(ctx.DotfilesDir, "images", "ck-mask.png")
	if _, err := os.Stat(maskPath); os.IsNotExist(err) {
		return StepResult{Skip: true, Logs: []string{"images/ck-mask.png not found \u2014 skipping"}}
	}

	dirs := []string{
		filepath.Join(ctx.HomeDir, "Developer", "ck"),
		filepath.Join(ctx.HomeDir, "Developer", "bin"),
	}

	var logs []string
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			logs = append(logs, fmt.Sprintf("%s (failed to create: %s)", dir, err))
			continue
		}

		// Check if folder already has a custom icon (Icon\r file)
		iconFile := filepath.Join(dir, "Icon\r")
		if _, err := os.Stat(iconFile); err == nil {
			logs = append(logs, fmt.Sprintf("%s (icon already set)", link.ShortPath(dir)))
			continue
		}

		if ctx.DryRun {
			logs = append(logs, fmt.Sprintf("%s (would apply icon)", link.ShortPath(dir)))
			continue
		}

		if err := run("folderify", "--color-scheme", "dark", maskPath, dir); err != nil {
			logs = append(logs, fmt.Sprintf("%s (icon failed: %s)", link.ShortPath(dir), err))
		} else {
			logs = append(logs, fmt.Sprintf("%s (icon applied)", link.ShortPath(dir)))
		}
	}

	return StepResult{Logs: logs}
}

