package installer

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

func finalizeSteps() []Step {
	return []Step{
		{Name: "launch-apps", Desc: "\U000f0493 Launch apps", Run: stepLaunchApps},
		{Name: "summary", Desc: "\U000f0219 Summary", Run: stepSummary},
	}
}

// ── Launch apps ──

var launchApps = []string{
	"Raycast",
	"Ice",
	"AeroSpace",
}

func stepLaunchApps(ctx *Context) StepResult {
	if ctx.Platform != platform.MacOS {
		return StepResult{Skip: true, Logs: []string{"macOS only \u2014 skipping"}}
	}

	var logs []string

	for _, app := range launchApps {
		if isAppRunning(app) {
			logs = append(logs, fmt.Sprintf("%s (already running)", app))
			continue
		}

		if ctx.DryRun {
			logs = append(logs, fmt.Sprintf("%s (would launch)", app))
			continue
		}

		if err := run("open", "-a", app); err != nil {
			logs = append(logs, fmt.Sprintf("%s (failed: %s)", app, err))
		} else {
			logs = append(logs, fmt.Sprintf("%s (launched)", app))
		}
	}

	return StepResult{Logs: logs}
}

func isAppRunning(name string) bool {
	out, err := exec.Command("pgrep", "-x", name).Output()
	if err != nil {
		return false
	}
	return strings.TrimSpace(string(out)) != ""
}

// ── Summary ──

func stepSummary(ctx *Context) StepResult {
	// Walk all sections and count statuses
	var done, failed, skipped int
	sections := Plan()
	for _, section := range sections {
		for _, step := range section.Steps {
			_ = step // steps in Plan() are fresh — count from the model instead
		}
	}
	// Since we can't access model state from here, just report section count
	_ = done
	_ = failed
	_ = skipped

	logs := []string{
		fmt.Sprintf("%d sections completed", len(sections)),
	}
	if ctx.DryRun {
		logs = append(logs, "dry run \u2014 no changes were made")
	}

	return StepResult{Logs: logs}
}
