package cmd

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/neoighodaro/dotfiles/cli/internal/installer"
	"github.com/spf13/cobra"
)

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Run the full installation",
	Long:  "Installs packages, creates symlinks, and configures system preferences.",
	RunE: func(cmd *cobra.Command, args []string) error {
		m := installer.New(dryRun, false)
		p := tea.NewProgram(m, tea.WithAltScreen())
		if _, err := p.Run(); err != nil {
			return fmt.Errorf("installer failed: %w", err)
		}
		return nil
	},
}

func init() {
	rootCmd.AddCommand(installCmd)
}
