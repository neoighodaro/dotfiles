package platform

import "runtime"

type OS string

const (
	MacOS   OS = "macos"
	Linux   OS = "linux"
	Unknown OS = "unknown"
)

func Detect() OS {
	switch runtime.GOOS {
	case "darwin":
		return MacOS
	case "linux":
		return Linux
	default:
		return Unknown
	}
}
