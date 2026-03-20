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

// Messages
type (
	tickMsg     struct{}          // demo mode: auto-advance
	doneMsg     struct{}          // all steps finished
	stepDoneMsg struct{ result StepResult } // a real step completed
)

// Model is the Bubble Tea model for the installer TUI.
type Model struct {
	sections   []Section
	curSection int
	curStep    int
	spinner    spinner.Model
	viewport   viewport.Model
	ctx        *Context
	dryRun     bool
	platform   platform.OS
	width      int
	height     int
	done       bool
	ready      bool
	userScroll bool
	paused     bool // waiting for user to continue/exit after a failure
	expanded   bool // show all logs when true
	startTime  time.Time
	elapsed    time.Duration
	demo       bool
}

const headerHeight = 7

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
		ctx:       NewContext(dryRun),
		dryRun:    dryRun,
		platform:  platform.Detect(),
		startTime: time.Now(),
		demo:      demo,
	}
}

func (m Model) Init() tea.Cmd {
	cmds := []tea.Cmd{m.spinner.Tick}

	// Mark the first step as running
	if len(m.sections) > 0 && len(m.sections[0].Steps) > 0 {
		m.sections[0].Steps[0].Status = StatusRunning
	}

	if m.demo {
		cmds = append(cmds, m.scheduleDemoTick())
	} else {
		cmds = append(cmds, m.runCurrentStep())
	}

	return tea.Batch(cmds...)
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.paused {
			switch msg.String() {
			case "c", "enter":
				m.paused = false
				return m.advance()
			case "q", "esc", "ctrl+c":
				return m, tea.Quit
			}
			// Fall through to viewport scrolling
		}
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "e":
			m.expanded = !m.expanded
			m.viewport.SetContent(m.renderBody())
			if m.expanded {
				m.viewport.SetYOffset(0)
			}
			return m, nil
		case "enter":
			if m.done {
				return m, tea.Quit
			}
		}
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
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll && !m.done {
			m.viewport.GotoBottom()
		}
		return m, cmd

	case tickMsg:
		// Demo mode: auto-advance
		return m.completeDemoStep()

	case stepDoneMsg:
		// Real mode: step finished
		return m.completeRealStep(msg.result)

	case doneMsg:
		m.done = true
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll {
			m.viewport.GotoBottom()
		}
		return m, nil
	}

	var cmd tea.Cmd
	m.viewport, cmd = m.viewport.Update(msg)
	m.userScroll = m.viewport.YOffset < m.viewport.TotalLineCount()-m.viewport.Height
	return m, cmd
}

// ── Real step execution ──

func (m Model) runCurrentStep() tea.Cmd {
	step := m.sections[m.curSection].Steps[m.curStep]
	if step.Run == nil {
		// No RunFunc — skip the step
		return func() tea.Msg {
			return stepDoneMsg{result: StepResult{Skip: true, Logs: []string{"not implemented yet"}}}
		}
	}
	ctx := m.ctx
	return func() tea.Msg {
		result := step.Run(ctx)
		return stepDoneMsg{result: result}
	}
}

func (m Model) completeRealStep(result StepResult) (tea.Model, tea.Cmd) {
	step := &m.sections[m.curSection].Steps[m.curStep]

	step.Log = append(step.Log, result.Logs...)

	switch {
	case result.Err != nil:
		step.Status = StatusFailed
		step.Log = append(step.Log, result.Err.Error())
		// Pause and let the user decide
		m.paused = true
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll {
			m.viewport.GotoBottom()
		}
		return m, nil
	case result.Skip:
		step.Status = StatusSkipped
	default:
		step.Status = StatusDone
	}

	return m.advance()
}

// ── Demo step execution ──

func (m Model) scheduleDemoTick() tea.Cmd {
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
	return tea.Tick(delay, func(time.Time) tea.Msg { return tickMsg{} })
}

func (m Model) completeDemoStep() (tea.Model, tea.Cmd) {
	step := &m.sections[m.curSection].Steps[m.curStep]

	var failed bool

	// If the step has a real RunFunc, use it even in demo mode
	if step.Run != nil {
		result := step.Run(m.ctx)
		step.Log = append(step.Log, result.Logs...)
		switch {
		case result.Err != nil:
			step.Status = StatusFailed
			step.Log = append(step.Log, result.Err.Error())
			failed = true
		case result.Skip:
			step.Status = StatusSkipped
		default:
			step.Status = StatusDone
		}
	} else {
		result := m.demoResult(step.Name)
		step.Log = append(step.Log, result.Logs...)
		if result.Skip {
			step.Status = StatusSkipped
		} else {
			step.Status = StatusDone
		}
	}

	if failed {
		m.paused = true
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll {
			m.viewport.GotoBottom()
		}
		return m, nil
	}

	return m.advance()
}

// ── Shared advance logic ──

func (m Model) advance() (tea.Model, tea.Cmd) {
	m.curStep++
	if m.curStep >= len(m.sections[m.curSection].Steps) {
		m.curSection++
		m.curStep = 0
	}

	if m.curSection >= len(m.sections) {
		m.done = true
		m.viewport.SetContent(m.renderBody())
		if !m.userScroll {
			m.viewport.GotoBottom()
		}
		return m, func() tea.Msg { return doneMsg{} }
	}

	m.sections[m.curSection].Steps[m.curStep].Status = StatusRunning
	m.viewport.SetContent(m.renderBody())
	if !m.userScroll {
		m.viewport.GotoBottom()
	}

	if m.demo {
		return m, m.scheduleDemoTick()
	}
	return m, m.runCurrentStep()
}

// ── View ──

func (m Model) View() string {
	if !m.ready {
		return ""
	}
	var b strings.Builder
	b.WriteString(m.renderHeader())
	b.WriteString(m.viewport.View())
	return b.String()
}

func (m Model) renderHeader() string {
	var b strings.Builder

	b.WriteString(ui.RenderLogo())

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
		prefix := "○"
		style := ui.SectionStyle
		if m.isSectionDone(si) {
			prefix = "●"
		} else if si == m.curSection {
			prefix = "◉"
		}
		b.WriteString(style.Render(fmt.Sprintf("%s %s", prefix, section.Name)))
		b.WriteString("\n")

		// Future sections: hide steps entirely
		if si > m.curSection+1 && !m.done {
			continue
		}

		isCurrentSection := si == m.curSection

		for _, step := range section.Steps {
			b.WriteString(m.renderStep(step))
			b.WriteString("\n")

			// Show logs for current section or when expanded
			showLogs := m.expanded || (isCurrentSection && !m.done)

			if showLogs {
				for _, log := range step.Log {
					b.WriteString(ui.LogStyle.Render(log))
					b.WriteString("\n")
				}
			}
		}
		b.WriteString("\n")
	}

	if m.done {
		divWidth := m.width
		if divWidth == 0 {
			divWidth = 60
		}
		b.WriteString(ui.DividerStyle.Render(strings.Repeat("─", divWidth)))
		b.WriteString("\n\n")
		b.WriteString(ui.AccentStyle.Render("  ✦ Done"))
		b.WriteString("\n")
	} else if m.paused {
		b.WriteString(lipgloss.NewStyle().Foreground(ui.Yellow).PaddingLeft(2).Bold(true).Render("Step failed — press c to continue or q to exit"))
		b.WriteString("\n")
	} else {
		b.WriteString(lipgloss.NewStyle().Foreground(ui.Dim).PaddingLeft(2).Render("press e to expand/collapse · q to abort"))
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

func (m Model) demoResult(name string) StepResult {
	switch name {
	case "detect-platform":
		return StepResult{Logs: []string{fmt.Sprintf("detected %s", m.platform)}}
	case "check-deps":
		return StepResult{Logs: []string{"git ✓  brew ✓  zsh ✓"}}
	case "load-config":
		return StepResult{Logs: []string{"found 18 config modules"}}
	case "link-zsh":
		return StepResult{Logs: []string{"~/.zshrc → configs/zsh/zshrc.sh"}}
	case "link-git":
		return StepResult{Logs: []string{"~/.gitconfig → configs/git/base.cfg"}}
	case "link-aerospace":
		return StepResult{Skip: true, Logs: []string{"not on macOS — skipping"}}
	case "install-brew":
		return StepResult{Logs: []string{"45 formulae up to date"}}
	case "install-casks":
		return StepResult{Logs: []string{"12 casks up to date"}}
	case "install-mas":
		return StepResult{Logs: []string{"3 apps up to date"}}
	case "ssh-keys":
		return StepResult{Skip: true, Logs: []string{"key exists — skipping generation"}}
	case "gpg-keys":
		return StepResult{Skip: true, Logs: []string{"key exists — skipping generation"}}
	case "macos-defaults":
		return StepResult{Logs: []string{"applied 42 preferences"}}
	case "restart-apps":
		return StepResult{Logs: []string{"Finder, Dock, SystemUIServer"}}
	case "summary":
		return StepResult{Logs: []string{"0 changed · 0 failed · 2 skipped"}}
	default:
		return StepResult{}
	}
}
