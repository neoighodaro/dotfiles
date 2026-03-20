package installer

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/neoighodaro/dotfiles/cli/internal/platform"
	"github.com/neoighodaro/dotfiles/cli/internal/ui"
)

// tickMsg advances the demo to the next step.
type tickMsg struct{}

// doneMsg signals the installer has finished.
type doneMsg struct{}

// Model is the Bubble Tea model for the installer TUI.
type Model struct {
	sections    []Section
	curSection  int
	curStep     int
	spinner     spinner.Model
	viewport    viewport.Model
	dryRun      bool
	platform    platform.OS
	width       int
	height      int
	done        bool
	ready       bool
	userScroll  bool // true when user has scrolled away from bottom
	startTime   time.Time
	elapsed     time.Duration
	demo        bool // when true, auto-advances steps for preview
}

const headerHeight = 7 // logo (4 lines) + info bar (1) + divider (1) + blank (1)

// New creates a new installer model.
func New(dryRun bool, demo bool) Model {
	s := spinner.New()
	s.Spinner = spinner.Spinner{
		Frames: []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
		FPS:    80 * time.Millisecond,
	}
	s.Style = lipgloss.NewStyle().Foreground(ui.Orange)

	return Model{
		sections:  Plan(),
		spinner:   s,
		dryRun:    dryRun,
		platform:  platform.Detect(),
		startTime: time.Now(),
		demo:      demo,
	}
}

func (m Model) Init() tea.Cmd {
	cmds := []tea.Cmd{m.spinner.Tick}
	if m.demo {
		cmds = append(cmds, m.scheduleNext())
	}
	// Mark the first step as running
	if len(m.sections) > 0 && len(m.sections[0].Steps) > 0 {
		m.sections[0].Steps[0].Status = StatusRunning
	}
	return tea.Batch(cmds...)
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "enter":
			if m.done {
				return m, tea.Quit
			}
		}
		// Forward all other keys (arrows, j/k, pgup/pgdn) to viewport
		var cmd tea.Cmd
		m.viewport, cmd = m.viewport.Update(msg)
		m.userScroll = m.viewport.YOffset < m.viewport.TotalLineCount()-m.viewport.Height
		return m, cmd

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		vpHeight := m.height - headerHeight
		if vpHeight < 1 {
			vpHeight = 1
		}
		if !m.ready {
			m.viewport = viewport.New(m.width, vpHeight)
			m.ready = true
		} else {
			m.viewport.Width = m.width
			m.viewport.Height = vpHeight
		}

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		m.elapsed = time.Since(m.startTime)
		// Update viewport content on every tick to keep it current
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll {
			m.viewport.GotoBottom()
		}
		return m, cmd

	case tickMsg:
		return m.advanceStep()

	case doneMsg:
		m.done = true
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll {
			m.viewport.GotoBottom()
		}
		return m, nil // don't quit — wait for user input
	}

	// Forward mouse/other events to viewport
	var cmd tea.Cmd
	m.viewport, cmd = m.viewport.Update(msg)
	m.userScroll = m.viewport.YOffset < m.viewport.TotalLineCount()-m.viewport.Height
	return m, cmd
}

func (m Model) View() string {
	if !m.ready {
		return ""
	}

	var b strings.Builder

	// ── Fixed header: logo + info bar + divider ──
	b.WriteString(m.renderHeader())

	// ── Scrollable body ──
	b.WriteString(m.viewport.View())

	return b.String()
}

func (m Model) renderHeader() string {
	var b strings.Builder

	// Logo
	b.WriteString(ui.RenderLogo())

	// Info bar
	mode := ui.AccentStyle.Render("install")
	if m.dryRun {
		mode = ui.DryRunBadge.Render("DRY RUN")
	}
	elapsed := ui.AccentStyle.Render(m.elapsed.Truncate(time.Second).String())
	info := fmt.Sprintf("  %s  %s  %s  %s  %s",
		lipgloss.NewStyle().Foreground(ui.Gray).Render("platform"),
		ui.AccentStyle.Render(string(m.platform)),
		lipgloss.NewStyle().Foreground(ui.Gray).Render("mode"),
		mode,
		lipgloss.NewStyle().Foreground(ui.Dim).Render("elapsed "+elapsed),
	)
	b.WriteString(info)
	b.WriteString("\n")

	// Divider
	divWidth := m.width
	if divWidth == 0 {
		divWidth = 60
	}
	b.WriteString(ui.DividerStyle.Render(strings.Repeat("─", divWidth)))
	b.WriteString("\n")

	return b.String()
}

func (m Model) renderBody() string {
	var b strings.Builder
	b.WriteString("\n")

	divWidth := m.width
	if divWidth == 0 {
		divWidth = 60
	}

	for si, section := range m.sections {
		// Section header
		prefix := "○"
		style := ui.SectionStyle
		if m.isSectionDone(si) {
			prefix = "●"
		} else if si == m.curSection {
			prefix = "◉"
		}
		b.WriteString(style.Render(fmt.Sprintf("%s %s", prefix, section.Name)))
		b.WriteString("\n")

		// Only show steps for current and completed sections, or the next section
		if si > m.curSection+1 && !m.done {
			continue
		}

		for _, step := range section.Steps {
			line := m.renderStep(step)
			b.WriteString(line)
			b.WriteString("\n")

			// Show log lines for active/just-completed steps
			for _, log := range step.Log {
				b.WriteString(ui.LogStyle.Render(log))
				b.WriteString("\n")
			}
		}
		b.WriteString("\n")
	}

	// Footer
	if m.done {
		b.WriteString(ui.DividerStyle.Render(strings.Repeat("─", divWidth)))
		b.WriteString("\n\n")
		total := m.elapsed.Truncate(time.Second).String()
		b.WriteString(ui.AccentStyle.Render(fmt.Sprintf("  ✦ Done in %s", total)))
		b.WriteString("\n\n")
		b.WriteString(lipgloss.NewStyle().Foreground(ui.Dim).PaddingLeft(2).Render("press q or enter to exit"))
		b.WriteString("\n")
	} else {
		b.WriteString(lipgloss.NewStyle().Foreground(ui.Dim).PaddingLeft(2).Render("press q to abort"))
		b.WriteString("\n")
	}

	return b.String()
}

func (m Model) renderStep(step Step) string {
	switch step.Status {
	case StatusRunning:
		return ui.StepActiveStyle.Render(fmt.Sprintf("%s %s", m.spinner.View(), step.Desc))
	case StatusDone:
		return ui.StepDoneStyle.Render(fmt.Sprintf("✓ %s", step.Desc))
	case StatusFailed:
		return ui.StepFailedStyle.Render(fmt.Sprintf("✗ %s", step.Desc))
	case StatusSkipped:
		return ui.StepSkippedStyle.Render(fmt.Sprintf("‒ %s (skipped)", step.Desc))
	default:
		return ui.StepPendingStyle.Render(fmt.Sprintf("· %s", step.Desc))
	}
}

func (m Model) isSectionDone(si int) bool {
	for _, step := range m.sections[si].Steps {
		if step.Status != StatusDone && step.Status != StatusSkipped {
			return false
		}
	}
	return true
}

// advanceStep marks the current step done and moves to the next.
func (m Model) advanceStep() (tea.Model, tea.Cmd) {
	// Mark current step as done (with occasional skips for realism)
	step := &m.sections[m.curSection].Steps[m.curStep]
	if m.demo && step.Name == "link-aerospace" {
		step.Status = StatusSkipped
		step.Log = append(step.Log, "not on macOS — skipping")
	} else {
		step.Status = StatusDone
		// Add a demo log line for some steps
		if m.demo {
			step.Log = append(step.Log, m.demoLog(step.Name)...)
		}
	}

	// Advance to next step
	m.curStep++
	if m.curStep >= len(m.sections[m.curSection].Steps) {
		m.curSection++
		m.curStep = 0
	}

	// Check if we're done
	if m.curSection >= len(m.sections) {
		m.done = true
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll {
			m.viewport.GotoBottom()
		}
		return m, func() tea.Msg { return doneMsg{} }
	}

	// Mark next step as running
	m.sections[m.curSection].Steps[m.curStep].Status = StatusRunning

	// Update viewport
	m.viewport.SetContent(m.renderBody())
	m.viewport.GotoBottom()

	return m, m.scheduleNext()
}

func (m Model) scheduleNext() tea.Cmd {
	// Vary timing for a natural feel
	delays := map[string]time.Duration{
		"detect-platform": 300 * time.Millisecond,
		"check-deps":      500 * time.Millisecond,
		"load-config":     200 * time.Millisecond,
		"install-brew":    1200 * time.Millisecond,
		"install-casks":   900 * time.Millisecond,
		"install-mas":     700 * time.Millisecond,
		"macos-defaults":  600 * time.Millisecond,
		"restart-apps":    400 * time.Millisecond,
	}

	step := m.sections[m.curSection].Steps[m.curStep]
	delay, ok := delays[step.Name]
	if !ok {
		delay = 350 * time.Millisecond
	}

	return tea.Tick(delay, func(time.Time) tea.Msg {
		return tickMsg{}
	})
}

func (m Model) demoLog(name string) []string {
	switch name {
	case "detect-platform":
		return []string{fmt.Sprintf("detected %s", m.platform)}
	case "check-deps":
		return []string{"git ✓  brew ✓  zsh ✓"}
	case "load-config":
		return []string{"loaded 24 symlinks, 45 packages, 12 casks"}
	case "link-zsh":
		return []string{"~/.zshrc → configs/zsh/zshrc.sh"}
	case "link-git":
		return []string{"~/.gitconfig → configs/git/base.cfg"}
	case "install-brew":
		return []string{"45 formulae up to date"}
	case "install-casks":
		return []string{"12 casks up to date"}
	case "install-mas":
		return []string{"3 apps up to date"}
	case "ssh-keys":
		return []string{"key exists — skipping generation"}
	case "gpg-keys":
		return []string{"key exists — skipping generation"}
	case "macos-defaults":
		return []string{"applied 42 preferences"}
	case "restart-apps":
		return []string{"Finder, Dock, SystemUIServer"}
	case "summary":
		return []string{"0 changed · 0 failed · 2 skipped"}
	default:
		return nil
	}
}
