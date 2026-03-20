package ui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

var logoLines = []string{
	" ▗       ",
	"▛▘▜▘▛▘▀▌▛▌",
	"▄▌▐▖▌ █▌▙▌",
	"        ▌ ",
}

var logoColors = []lipgloss.Color{
	"#FF6B35", // deep orange
	"#FF8C42", // orange
	"#FFB380", // peach
	"#FFD4AA", // light peach
}

func RenderLogo() string {
	var b strings.Builder
	for i, line := range logoLines {
		color := logoColors[0]
		if i < len(logoColors) {
			color = logoColors[i]
		}
		b.WriteString(lipgloss.NewStyle().Foreground(color).Bold(true).PaddingLeft(2).Render(line))
		b.WriteString("\n")
	}
	return b.String()
}
