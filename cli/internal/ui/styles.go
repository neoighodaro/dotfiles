package ui

import "github.com/charmbracelet/lipgloss"

// Color palette — warm orange accent with neutral grays
var (
	Orange    = lipgloss.Color("#FF8C42")
	Peach     = lipgloss.Color("#FFB380")
	Green     = lipgloss.Color("#A8DB8F")
	Red       = lipgloss.Color("#FF6B6B")
	Yellow    = lipgloss.Color("#FFD93D")
	Gray      = lipgloss.Color("#6B7280")
	DarkGray  = lipgloss.Color("#374151")
	White     = lipgloss.Color("#F9FAFB")
	Dim       = lipgloss.Color("#4B5563")
)

// Styles
var (
	LogoStyle = lipgloss.NewStyle().
			Foreground(Orange).
			Bold(true)

	AccentStyle = lipgloss.NewStyle().
			Foreground(Orange)

	InfoBarStyle = lipgloss.NewStyle().
			Foreground(Gray).
			PaddingLeft(2)

	SectionStyle = lipgloss.NewStyle().
			Foreground(Peach).
			Bold(true).
			PaddingLeft(2)

	StepPendingStyle = lipgloss.NewStyle().
			Foreground(Dim).
			PaddingLeft(4)

	StepActiveStyle = lipgloss.NewStyle().
			Foreground(White).
			PaddingLeft(4)

	StepDoneStyle = lipgloss.NewStyle().
			Foreground(Green).
			PaddingLeft(4)

	StepFailedStyle = lipgloss.NewStyle().
			Foreground(Red).
			PaddingLeft(4)

	StepSkippedStyle = lipgloss.NewStyle().
			Foreground(Yellow).
			PaddingLeft(4)

	LogStyle = lipgloss.NewStyle().
			Foreground(Dim).
			PaddingLeft(6)

	DryRunBadge = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#1F2937")).
			Background(Yellow).
			Bold(true).
			Padding(0, 1)

	DividerStyle = lipgloss.NewStyle().
			Foreground(DarkGray)
)
