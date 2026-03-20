package cmd

import (
	"github.com/neoighodaro/dotfiles/cli/internal/ui"
	"github.com/spf13/cobra"
)

var dryRun bool

var rootCmd = &cobra.Command{
	Use:   "strap",
	Short: "Bootstrap and manage dotfiles",
	Long:  ui.RenderLogo() + "\n  A CLI tool to bootstrap macOS and Linux systems with dotfiles, packages, and preferences.",
}

func Execute() error {
	return rootCmd.Execute()
}

func init() {
	rootCmd.PersistentFlags().BoolVar(&dryRun, "dry-run", false, "Print what would be done without making changes")
	rootCmd.CompletionOptions.DisableDefaultCmd = true
}
