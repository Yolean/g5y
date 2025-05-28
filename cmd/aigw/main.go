// Copyright Envoy AI Gateway Authors
// SPDX-License-Identifier: Apache-2.0
// The full text of the Apache license is available in the LICENSE file at
// the root of the repo.

package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/alecthomas/kong"
	ctrl "sigs.k8s.io/controller-runtime"

	"github.com/envoyproxy/ai-gateway/internal/version"
)

type (
	// cmd corresponds to the top-level `aigw` command.
	cmd struct {
		// Version is the sub-command to show the version.
		Version struct{} `cmd:"" help:"Show version."`
	}
)

type (
	subCmdFn[T any] func(context.Context, T, io.Writer, io.Writer) error
)

func main() {
	doMain(ctrl.SetupSignalHandler(), os.Stdout, os.Stderr, os.Args[1:], os.Exit)
}

// doMain is the main entry point for the CLI. It parses the command line arguments and executes the appropriate command.
//
//   - stdout is the writer to use for standard output. Mainly for testing.
//   - stderr is the writer to use for standard error. Mainly for testing.
//   - `args` are the command line arguments without the program name.
//   - exitFn is the function to call to exit the program during the parsing of the command line arguments. Mainly for testing.
func doMain(ctx context.Context, stdout, stderr io.Writer, args []string, exitFn func(int)) {
	var c cmd
	parser, err := kong.New(&c,
		kong.Name("aigw"),
		kong.Description("Envoy AI Gateway CLI"),
		kong.Writers(stdout, stderr),
		kong.Exit(exitFn),
	)
	if err != nil {
		log.Fatalf("Error creating parser: %v", err)
	}
	parsed, err := parser.Parse(args)
	parser.FatalIfErrorf(err)
	switch parsed.Command() {
	case "version":
		_, _ = stdout.Write([]byte(fmt.Sprintf("Envoy AI Gateway CLI: %s\n", version.Version)))
	default:
		// Kong will handle printing help for unknown commands or if no command is given.
		// If a valid command is given but not handled in the switch, it's an error.
		if parsed.Command() != "" {
			panic(fmt.Sprintf("unhandled command: %s", parsed.Command()))
		}
	}
}
