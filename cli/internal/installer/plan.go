package installer

// Plan defines the full installation sequence.
func Plan() []Section {
	return []Section{
		{Name: "Preflight", Steps: preflightSteps()},
		{Name: "Symlinks", Steps: symlinkSteps()},
		{Name: "Packages", Steps: packageSteps()},
		{Name: "System", Steps: systemSteps()},
		{Name: "Finalize", Steps: finalizeSteps()},
	}
}

// Placeholder sections — will be wired up one at a time.

func symlinkSteps() []Step {
	return []Step{
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
	}
}

func packageSteps() []Step {
	return []Step{
		{Name: "install-brew", Desc: "Homebrew formulae"},
		{Name: "install-casks", Desc: "Homebrew casks"},
		{Name: "install-mas", Desc: "Mac App Store apps"},
	}
}

func systemSteps() []Step {
	return []Step{
		{Name: "ssh-keys", Desc: "SSH key setup"},
		{Name: "gpg-keys", Desc: "GPG key setup"},
		{Name: "macos-defaults", Desc: "macOS preferences"},
		{Name: "shell-default", Desc: "Set default shell"},
	}
}

func finalizeSteps() []Step {
	return []Step{
		{Name: "restart-apps", Desc: "Restart affected apps"},
		{Name: "summary", Desc: "Installation summary"},
	}
}
