package link

import (
	"fmt"
	"os"
	"path/filepath"
)

// Result holds the outcome of a single link operation.
type Result struct {
	Target  string
	Source  string
	Skipped bool // already linked
	BackedUp bool
	Created bool
	Err     error
}

// ShortPath returns a path relative to $HOME using ~ notation.
func ShortPath(p string) string {
	home, _ := os.UserHomeDir()
	if rel, err := filepath.Rel(home, p); err == nil {
		return "~/" + rel
	}
	return p
}

func (r Result) String() string {
	target := ShortPath(r.Target)
	source := ShortPath(r.Source)
	if r.Err != nil {
		return fmt.Sprintf("%s ✗ %s", target, r.Err)
	}
	if r.Skipped {
		return fmt.Sprintf("%s (already linked)", target)
	}
	if r.BackedUp {
		return fmt.Sprintf("%s → %s (backed up original)", target, source)
	}
	return fmt.Sprintf("%s → %s", target, source)
}

// Create creates a symlink from source to target, backing up any existing file.
// If dryRun is true, it only records what would happen.
func Create(source, target string, dryRun bool) Result {
	source, _ = filepath.Abs(source)
	target, _ = filepath.Abs(target)

	res := Result{Target: target, Source: source}

	// Check if source exists
	if _, err := os.Stat(source); os.IsNotExist(err) {
		res.Err = fmt.Errorf("source does not exist: %s", source)
		return res
	}

	if dryRun {
		res.Created = true
		return res
	}

	// Handle existing target
	if info, err := os.Lstat(target); err == nil {
		if info.Mode()&os.ModeSymlink != 0 {
			// It's a symlink — check if it already points to our source
			existing, _ := os.Readlink(target)
			if existing == source {
				res.Skipped = true
				return res
			}
			// Different symlink — just remove it, no backup needed
			if err := os.Remove(target); err != nil {
				res.Err = fmt.Errorf("failed to remove old symlink %s: %w", target, err)
				return res
			}
		} else {
			// Real file/directory — back it up
			backup := target + ".backup"
			if _, err := os.Lstat(backup); err == nil {
				if err := os.RemoveAll(backup); err != nil {
					res.Err = fmt.Errorf("failed to remove old backup %s: %w", backup, err)
					return res
				}
			}
			if err := os.Rename(target, backup); err != nil {
				res.Err = fmt.Errorf("failed to backup %s: %w", target, err)
				return res
			}
			res.BackedUp = true
		}
	}

	// Ensure parent directory exists
	if err := os.MkdirAll(filepath.Dir(target), 0755); err != nil {
		res.Err = fmt.Errorf("failed to create parent dir: %w", err)
		return res
	}

	if err := os.Symlink(source, target); err != nil {
		res.Err = fmt.Errorf("failed to symlink: %w", err)
		return res
	}

	res.Created = true
	return res
}
