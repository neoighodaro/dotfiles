package cmd

import (
	"github.com/neoighodaro/dotfiles/cli/internal/installer"
	"github.com/spf13/cobra"
)

var zellijCmd = &cobra.Command{
	Use:   "zellij",
	Short: "Set up Zellij plugins and permissions",
	Long: "Downloads missing Zellij plugins and merges the committed plugin permissions " +
		"into Zellij's runtime cache, so headless plugins (e.g. zjstatus-hints) are " +
		"pre-approved and never block on an unanswerable trust prompt.",
	RunE: func(cmd *cobra.Command, args []string) error {
		return installer.RunZellij(dryRun)
	},
}

func init() {
	rootCmd.AddCommand(zellijCmd)
}
