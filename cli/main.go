package main

import (
	"os"

	"github.com/ncolesummers/o11y-advisor/cli/cmd"
)

func main() {
	if err := cmd.Execute(os.Args[1:]); err != nil {
		os.Exit(1)
	}
}
