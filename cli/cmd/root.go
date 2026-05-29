package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// Version is the current CLI version.
const Version = "0.1.0-dev"

func newRootCmd() *cobra.Command {
	root := &cobra.Command{
		Use:     "o11y",
		Short:   "o11y-advisor — specialist observability advisor",
		Version: Version,
	}
	root.SilenceUsage = true
	root.AddCommand(newVersionCmd())
	return root
}

func newVersionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print o11y version",
		Run: func(cmd *cobra.Command, _ []string) {
			fmt.Fprintln(cmd.OutOrStdout(), "o11y "+Version)
		},
	}
}

// Execute runs the root command with the given args.
func Execute(args []string) error {
	root := newRootCmd()
	root.SetArgs(args)
	return root.Execute()
}
