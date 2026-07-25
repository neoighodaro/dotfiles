package installer

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

func TestParseZellijPermissions(t *testing.T) {
	in := `// a comment
"~/.config/zellij/plugins/a.wasm" {
    ReadApplicationState
    RunCommands
}

"~/.config/zellij/plugins/b.wasm" {
    ReadApplicationState
}
`
	order, perms := parseZellijPermissions(in)

	if got, want := len(order), 2; got != want {
		t.Fatalf("order length = %d, want %d", got, want)
	}
	if order[0] != "~/.config/zellij/plugins/a.wasm" {
		t.Errorf("first key = %q", order[0])
	}
	if got := perms["~/.config/zellij/plugins/a.wasm"]; len(got) != 2 {
		t.Errorf("a.wasm perms = %v, want 2", got)
	}
}

func TestExpandHome(t *testing.T) {
	if got := expandHome("~/x/y", "/home/neo"); got != "/home/neo/x/y" {
		t.Errorf("expandHome = %q", got)
	}
	if got := expandHome("/abs/path", "/home/neo"); got != "/abs/path" {
		t.Errorf("expandHome should leave absolute paths untouched, got %q", got)
	}
}

func TestSyncZellijPermissions(t *testing.T) {
	home := t.TempDir()
	dotfiles := t.TempDir()

	// Seed uses portable ~/ paths.
	seedDir := filepath.Join(dotfiles, "configs", "zellij")
	if err := os.MkdirAll(seedDir, 0755); err != nil {
		t.Fatal(err)
	}
	seed := `"~/.config/zellij/plugins/hints.wasm" {
    ReadApplicationState
    MessageAndLaunchOtherPlugins
}
"~/.config/zellij/plugins/status.wasm" {
    ReadApplicationState
    RunCommands
}
`
	if err := os.WriteFile(filepath.Join(seedDir, "permissions.kdl"), []byte(seed), 0644); err != nil {
		t.Fatal(err)
	}

	ctx := &Context{Platform: platform.MacOS, HomeDir: home, DotfilesDir: dotfiles}
	dest := zellijPermissionsCachePath(ctx)

	// Pre-existing cache: status already granted (with an extra perm Zellij added),
	// hints missing entirely.
	if err := os.MkdirAll(filepath.Dir(dest), 0755); err != nil {
		t.Fatal(err)
	}
	existing := "\"" + filepath.Join(home, ".config/zellij/plugins/status.wasm") + "\" {\n    ChangeApplicationState\n    ReadApplicationState\n}\n"
	if err := os.WriteFile(dest, []byte(existing), 0644); err != nil {
		t.Fatal(err)
	}

	// First sync should add the missing hints block and merge RunCommands into status.
	if res := syncZellijPermissions(ctx); res.Err != nil {
		t.Fatalf("sync err: %v", res.Err)
	}

	_, perms := parseZellijPermissions(readFile(t, dest))
	hintsKey := filepath.Join(home, ".config/zellij/plugins/hints.wasm")
	statusKey := filepath.Join(home, ".config/zellij/plugins/status.wasm")

	if !hasPerm(perms[hintsKey], "MessageAndLaunchOtherPlugins") {
		t.Errorf("hints missing MessageAndLaunchOtherPlugins: %v", perms[hintsKey])
	}
	// Zellij's pre-existing ChangeApplicationState must be preserved, seed's
	// RunCommands must be merged in.
	if !hasPerm(perms[statusKey], "ChangeApplicationState") || !hasPerm(perms[statusKey], "RunCommands") {
		t.Errorf("status perms not merged: %v", perms[statusKey])
	}

	// Second sync is a no-op.
	res := syncZellijPermissions(ctx)
	if res.Err != nil {
		t.Fatalf("re-sync err: %v", res.Err)
	}
	if len(res.Logs) != 1 || res.Logs[0] != "permissions already in sync" {
		t.Errorf("re-sync not idempotent: %v", res.Logs)
	}
}

func readFile(t *testing.T, path string) string {
	t.Helper()
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return string(b)
}

func hasPerm(list []string, want string) bool {
	for _, p := range list {
		if p == want {
			return true
		}
	}
	return false
}
