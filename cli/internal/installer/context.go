package installer

import (
	"os"
	"path/filepath"

	"github.com/neoighodaro/dotfiles/cli/internal/platform"
)

// Context holds shared state for step execution.
type Context struct {
	Platform   platform.OS
	HomeDir    string
	DotfilesDir string
	DryRun     bool
}

// NewContext builds the installer context.
func NewContext(dryRun bool) *Context {
	home, _ := os.UserHomeDir()

	// Default to cwd (run strap from the dotfiles repo root)
	dotfiles, _ := os.Getwd()

	// Allow override via env
	if v := os.Getenv("DOTFILES_DIR"); v != "" {
		dotfiles, _ = filepath.Abs(v)
	}

	return &Context{
		Platform:    platform.Detect(),
		HomeDir:     home,
		DotfilesDir: dotfiles,
		DryRun:      dryRun,
	}
}
