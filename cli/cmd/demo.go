package cmd

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/neoighodaro/dotfiles/cli/internal/installer"
	"github.com/spf13/cobra"
)

var demoCmd = &cobra.Command{
	Use:   "demo",
	Short: "Preview the installer TUI",
	Long:  "Runs a simulated installation to preview the TUI without making any changes.",
	RunE: func(cmd *cobra.Command, args []string) error {
		m := installer.New(true, true)
		p := tea.NewProgram(m, tea.WithAltScreen())
		if _, err := p.Run(); err != nil {
			return fmt.Errorf("demo failed: %w", err)
		}
		return nil
	},
}

func init() {
	rootCmd.AddCommand(demoCmd)
}
