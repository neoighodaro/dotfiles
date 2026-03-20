package installer

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

func preflightSteps() []Step {
	return []Step{
		{
			Name: "detect-platform",
			Desc: "\U000f0349 Detecting platform",
			Run:  stepDetectPlatform,
		},
		{
			Name: "check-deps",
			Desc: "\U000f0349 Checking dependencies",
			Run:  stepCheckDeps,
		},
		{
			Name: "load-config",
			Desc: "\U000f0349 Loading configuration",
			Run:  stepLoadConfig,
		},
	}
}

func stepDetectPlatform(ctx *Context) StepResult {
	switch ctx.Platform {
	case platform.MacOS:
		return StepResult{Logs: []string{"detected macOS"}}
	case platform.Linux:
		return StepResult{Logs: []string{"detected Linux"}}
	default:
		return StepResult{
			Err: fmt.Errorf("unsupported platform: %s", ctx.Platform),
		}
	}
}

func stepCheckDeps(ctx *Context) StepResult {
	type dep struct {
		name     string
		bin      string
		required bool
		macOnly  bool
	}

	deps := []dep{
		{name: "git", bin: "git", required: true},
		{name: "zsh", bin: "zsh", required: true},
		{name: "brew", bin: "brew", required: false, macOnly: true},
	}

	var logs []string
	allOk := true

	for _, d := range deps {
		if d.macOnly && ctx.Platform != platform.MacOS {
			continue
		}

		_, err := exec.LookPath(d.bin)
		if err != nil {
			// Try to auto-install Homebrew on macOS
			if d.name == "brew" && ctx.Platform == platform.MacOS && !ctx.DryRun {
				logs = append(logs, "brew ‒ not found, installing Homebrew...")
				installCmd := exec.Command("/bin/bash", "-c", "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash")
				if out, installErr := installCmd.CombinedOutput(); installErr != nil {
					logs = append(logs, fmt.Sprintf("brew ✗ install failed: %s", string(out)))
				} else {
					logs = append(logs, "brew ✓ (installed)")
				}
				continue
			}
			if d.required {
				allOk = false
				logs = append(logs, fmt.Sprintf("%s ✗ (not found)", d.name))
			} else {
				logs = append(logs, fmt.Sprintf("%s ‒ (optional, not found)", d.name))
			}
		} else {
			logs = append(logs, fmt.Sprintf("%s ✓", d.name))
		}
	}

	if !allOk {
		return StepResult{
			Logs: logs,
			Err:  fmt.Errorf("missing required dependencies"),
		}
	}

	return StepResult{Logs: logs}
}

func stepLoadConfig(ctx *Context) StepResult {
	var logs []string

	// Verify dotfiles directory exists
	if _, err := os.Stat(ctx.DotfilesDir); os.IsNotExist(err) {
		return StepResult{
			Logs: []string{fmt.Sprintf("dotfiles dir not found: %s", ctx.DotfilesDir)},
			Err:  fmt.Errorf("dotfiles directory does not exist"),
		}
	}
	logs = append(logs, fmt.Sprintf("dotfiles: %s", ctx.DotfilesDir))

	// Verify configs subdirectory
	configsDir := ctx.DotfilesDir + "/configs"
	if _, err := os.Stat(configsDir); os.IsNotExist(err) {
		return StepResult{
			Logs: []string{fmt.Sprintf("configs dir not found: %s", configsDir)},
			Err:  fmt.Errorf("configs directory does not exist"),
		}
	}

	// Count config dirs
	entries, _ := os.ReadDir(configsDir)
	dirCount := 0
	for _, e := range entries {
		if e.IsDir() {
			dirCount++
		}
	}
	logs = append(logs, fmt.Sprintf("found %d config modules", dirCount))

	return StepResult{Logs: logs}
}
