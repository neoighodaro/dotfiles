package installer

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/neoighodaro/dotfiles/cli/internal/link"
	"github.com/neoighodaro/dotfiles/cli/internal/platform"
	"github.com/neoighodaro/dotfiles/cli/internal/ui"
)

// ── Zellij plugin permissions ──
//
// Zellij prompts to trust each plugin on first load and records the grant in a
// runtime cache. Headless plugins (e.g. zjstatus-hints, which pipes into the
// status bar) have no focusable pane, so the y/n prompt can never be answered
// interactively. To avoid that dead end we keep a committed seed of the expected
// grants in configs/zellij/permissions.kdl and merge it into the cache here.

// stepZellijPermissions merges the committed permission seed into Zellij's
// runtime cache so trusted plugins are pre-approved.
func stepZellijPermissions(ctx *Context) StepResult {
	return syncZellijPermissions(ctx)
}

// zellijPermissionsCachePath returns the file Zellij actually reads at startup
// for the current platform — distinct from the committed seed under configs/.
func zellijPermissionsCachePath(ctx *Context) string {
	switch ctx.Platform {
	case platform.MacOS:
		return filepath.Join(ctx.HomeDir, "Library", "Caches", "org.Zellij-Contributors.Zellij", "permissions.kdl")
	default:
		cache := os.Getenv("XDG_CACHE_HOME")
		if cache == "" {
			cache = filepath.Join(ctx.HomeDir, ".cache")
		}
		return filepath.Join(cache, "zellij", "permissions.kdl")
	}
}

func syncZellijPermissions(ctx *Context) StepResult {
	seedPath := filepath.Join(ctx.DotfilesDir, "configs", "zellij", "permissions.kdl")
	seedData, err := os.ReadFile(seedPath)
	if err != nil {
		return StepResult{Skip: true, Logs: []string{"configs/zellij/permissions.kdl not found — skipping"}}
	}

	dest := zellijPermissionsCachePath(ctx)

	// Existing cache may not exist yet on a fresh machine.
	var destData []byte
	if b, err := os.ReadFile(dest); err == nil {
		destData = b
	}

	seedOrder, seedPerms := parseZellijPermissions(string(seedData))
	order, perms := parseZellijPermissions(string(destData))

	var added []string
	for _, seedKey := range seedOrder {
		// Seed paths use ~/ so they stay portable across machines; Zellij keys
		// them by absolute path, so expand before merging.
		key := expandHome(seedKey, ctx.HomeDir)
		_, existed := perms[key]
		if !existed {
			order = append(order, key)
		}

		var newPerms []string
		for _, perm := range seedPerms[seedKey] {
			before := len(perms[key])
			perms[key] = appendUnique(perms[key], perm)
			if existed && len(perms[key]) != before {
				newPerms = append(newPerms, perm)
			}
		}

		switch {
		case !existed:
			added = append(added, filepath.Base(key)+" (added)")
		case len(newPerms) > 0:
			added = append(added, filepath.Base(key)+": +"+strings.Join(newPerms, ", "))
		}
	}

	if len(added) == 0 {
		return StepResult{Logs: []string{"permissions already in sync"}}
	}

	if ctx.DryRun {
		return StepResult{Logs: append([]string{"would update " + link.ShortPath(dest)}, added...)}
	}

	if err := os.MkdirAll(filepath.Dir(dest), 0755); err != nil {
		return StepResult{Logs: []string{fmt.Sprintf("failed to create cache dir: %s", err)}, Err: err}
	}
	if err := os.WriteFile(dest, []byte(renderZellijPermissions(order, perms)), 0644); err != nil {
		return StepResult{Logs: []string{fmt.Sprintf("write failed: %s", err)}, Err: err}
	}

	return StepResult{Logs: append([]string{"updated " + link.ShortPath(dest)}, added...)}
}

// parseZellijPermissions reads a permissions.kdl into an ordered list of plugin
// paths and their permission sets. The format is a flat list of blocks:
//
//	"<plugin path>" {
//	    PermissionA
//	    PermissionB
//	}
func parseZellijPermissions(data string) ([]string, map[string][]string) {
	var order []string
	perms := map[string][]string{}
	var cur string

	for _, raw := range strings.Split(data, "\n") {
		line := strings.TrimSpace(raw)
		switch {
		case line == "" || strings.HasPrefix(line, "//"):
			continue
		case strings.HasSuffix(line, "{"):
			path := strings.Trim(strings.TrimSpace(strings.TrimSuffix(line, "{")), "\"")
			cur = path
			if _, ok := perms[cur]; !ok {
				order = append(order, cur)
				perms[cur] = nil
			}
		case line == "}":
			cur = ""
		case cur != "":
			perms[cur] = appendUnique(perms[cur], line)
		}
	}

	return order, perms
}

func renderZellijPermissions(order []string, perms map[string][]string) string {
	var b strings.Builder
	for _, p := range order {
		fmt.Fprintf(&b, "%q {\n", p)
		for _, perm := range perms[p] {
			b.WriteString("    ")
			b.WriteString(perm)
			b.WriteString("\n")
		}
		b.WriteString("}\n")
	}
	return b.String()
}

func expandHome(p, home string) string {
	if strings.HasPrefix(p, "~/") {
		return filepath.Join(home, p[2:])
	}
	return p
}

func appendUnique(list []string, v string) []string {
	for _, x := range list {
		if x == v {
			return list
		}
	}
	return append(list, v)
}

// ── Standalone runner ──

// RunZellij runs just the Zellij-related setup (plugin download + permission
// sync) outside the full installer TUI, for `strap zellij`.
func RunZellij(dryRun bool) error {
	ctx := NewContext(dryRun, false, false)

	steps := []Step{
		{Desc: "Plugins", Run: stepZellijPlugins},
		{Desc: "Permissions", Run: stepZellijPermissions},
	}

	fmt.Println(ui.RenderLogo())
	if dryRun {
		fmt.Println(ui.AccentStyle.Render("  DRY RUN — no changes will be made"))
	}
	fmt.Println()

	var failed bool
	for _, step := range steps {
		res := step.Run(ctx)

		switch {
		case res.Err != nil:
			fmt.Println(ui.StepFailedStyle.Render("  ✗ " + step.Desc))
			failed = true
		case res.Skip:
			fmt.Println(ui.StepSkippedStyle.Render("  ‒ " + step.Desc + " (skipped)"))
		default:
			fmt.Println(ui.StepDoneStyle.Render("  ✓ " + step.Desc))
		}

		for _, l := range res.Logs {
			fmt.Println(ui.LogStyle.Render("    " + l))
		}
		if res.Err != nil {
			fmt.Println(ui.LogStyle.Render("    " + res.Err.Error()))
		}
	}

	fmt.Println()
	if failed {
		return fmt.Errorf("zellij setup completed with errors")
	}
	fmt.Println(ui.AccentStyle.Render("  ✦ Done"))
	return nil
}
