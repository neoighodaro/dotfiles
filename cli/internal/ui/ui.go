package ui

import "fmt"

const (
	colorReset  = "\033[0m"
	colorGreen  = "\033[0;32m"
	colorYellow = "\033[0;33m"
	colorIndigo = "\033[0;94m"
	colorGray   = "\033[0;90m"
	colorRed    = "\033[0;31m"
	colorWhite  = "\033[1;37m"
)

func Header(msg string) {
	fmt.Printf("\n%s%s%s\n\n", colorWhite, msg, colorReset)
}

func Info(msg string) {
	fmt.Printf("%s→ %s%s\n", colorIndigo, msg, colorReset)
}

func Success(msg string) {
	fmt.Printf("%s✓ %s%s\n", colorGreen, msg, colorReset)
}

func Warn(msg string) {
	fmt.Printf("%s! %s%s\n", colorYellow, msg, colorReset)
}

func Error(msg string) {
	fmt.Printf("%s✗ %s%s\n", colorRed, msg, colorReset)
}

func DryRun(msg string) {
	fmt.Printf("%s[dry-run] %s%s\n", colorGray, msg, colorReset)
}
