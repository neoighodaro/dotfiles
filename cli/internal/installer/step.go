package installer

// StepStatus represents the current state of an installation step.
type StepStatus int

const (
	StatusPending StepStatus = iota
	StatusRunning
	StatusDone
	StatusFailed
	StatusSkipped
)

// Step is a single unit of work in the installation process.
type Step struct {
	Name   string
	Desc   string
	Status StepStatus
	Log    []string
}

// Section groups related steps under a heading.
type Section struct {
	Name  string
	Steps []Step
}

// Plan defines the full installation sequence.
func Plan() []Section {
	return []Section{
		{
			Name: "Preflight",
			Steps: []Step{
				{Name: "detect-platform", Desc: "Detecting platform"},
				{Name: "check-deps", Desc: "Checking dependencies"},
				{Name: "load-config", Desc: "Loading configuration"},
			},
		},
		{
			Name: "Symlinks",
			Steps: []Step{
				{Name: "link-zsh", Desc: "ZSH configuration"},
				{Name: "link-git", Desc: "Git configuration"},
				{Name: "link-starship", Desc: "Starship prompt"},
				{Name: "link-ghostty", Desc: "Ghostty terminal"},
				{Name: "link-zellij", Desc: "Zellij multiplexer"},
				{Name: "link-lazygit", Desc: "Lazygit"},
				{Name: "link-aerospace", Desc: "Aerospace WM"},
				{Name: "link-karabiner", Desc: "Karabiner-Elements"},
				{Name: "link-sketchybar", Desc: "Sketchybar"},
				{Name: "link-claude", Desc: "Claude Code"},
				{Name: "link-misc", Desc: "Misc dotfiles"},
			},
		},
		{
			Name: "Packages",
			Steps: []Step{
				{Name: "install-brew", Desc: "Homebrew formulae"},
				{Name: "install-casks", Desc: "Homebrew casks"},
				{Name: "install-mas", Desc: "Mac App Store apps"},
			},
		},
		{
			Name: "System",
			Steps: []Step{
				{Name: "ssh-keys", Desc: "SSH key setup"},
				{Name: "gpg-keys", Desc: "GPG key setup"},
				{Name: "macos-defaults", Desc: "macOS preferences"},
				{Name: "shell-default", Desc: "Set default shell"},
			},
		},
		{
			Name: "Finalize",
			Steps: []Step{
				{Name: "restart-apps", Desc: "Restart affected apps"},
				{Name: "summary", Desc: "Installation summary"},
			},
		},
	}
}
