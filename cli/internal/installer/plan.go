package installer

// Plan defines the full installation sequence.
func Plan() []Section {
	return []Section{
		{Name: "Preflight", Steps: preflightSteps()},
		{Name: "Configuration Symlinks", Steps: symlinkSteps()},
		{Name: "Packages", Steps: packageSteps()},
		{Name: "Post-install Setup", Steps: postInstallSteps()},
		{Name: "System", Steps: systemSteps()},
		{Name: "Finalize", Steps: finalizeSteps()},
	}
}

// Placeholder sections — will be wired up one at a time.

func finalizeSteps() []Step {
	return []Step{
		{Name: "restart-apps", Desc: "Restart affected apps"},
		{Name: "summary", Desc: "Installation summary"},
	}
}
