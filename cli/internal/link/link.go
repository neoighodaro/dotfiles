package link

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/neoighodaro/dotfiles/cli/internal/ui"
)

// Create creates a symlink from source to target, backing up any existing file.
// If dryRun is true, it only prints what would happen.
func Create(source, target string, dryRun bool) error {
	source, _ = filepath.Abs(source)
	target, _ = filepath.Abs(target)

	if dryRun {
		ui.DryRun(fmt.Sprintf("link %s → %s", target, source))
		return nil
	}

	// Back up existing file if it's not already a symlink to our source
	if info, err := os.Lstat(target); err == nil {
		if info.Mode()&os.ModeSymlink != 0 {
			existing, _ := os.Readlink(target)
			if existing == source {
				ui.Info(fmt.Sprintf("already linked: %s", target))
				return nil
			}
		}
		backup := target + ".backup"
		ui.Warn(fmt.Sprintf("backing up %s → %s", target, backup))
		if err := os.Rename(target, backup); err != nil {
			return fmt.Errorf("failed to backup %s: %w", target, err)
		}
	}

	// Ensure parent directory exists
	if err := os.MkdirAll(filepath.Dir(target), 0755); err != nil {
		return fmt.Errorf("failed to create parent dir for %s: %w", target, err)
	}

	if err := os.Symlink(source, target); err != nil {
		return fmt.Errorf("failed to create symlink %s → %s: %w", target, source, err)
	}

	ui.Success(fmt.Sprintf("linked %s → %s", target, source))
	return nil
}
