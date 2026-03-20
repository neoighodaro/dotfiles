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

// StepResult is returned by a step's RunFunc.
type StepResult struct {
	Logs    []string
	Skip    bool   // mark step as skipped instead of done
	Err     error  // non-nil marks step as failed
}

// RunFunc executes a step's work. It receives the installer context and
// returns a result. It runs in a goroutine so it must not touch the model.
type RunFunc func(ctx *Context) StepResult

// Step is a single unit of work in the installation process.
type Step struct {
	Name   string
	Desc   string
	Status StepStatus
	Log    []string
	Run    RunFunc
}

// Section groups related steps under a heading.
type Section struct {
	Name  string
	Steps []Step
}
