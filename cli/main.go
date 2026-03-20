package main

import (
	"os"

	"github.com/neoighodaro/dotfiles/cli/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}
