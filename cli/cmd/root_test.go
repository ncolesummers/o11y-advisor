package cmd

import (
	"bytes"
	"strings"
	"testing"
)

func TestHelp(t *testing.T) {
	buf := &bytes.Buffer{}
	root := newRootCmd()
	root.SetOut(buf)
	root.SetArgs([]string{"--help"})
	if err := root.Execute(); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), "o11y") {
		t.Errorf("help output missing 'o11y': %s", buf.String())
	}
}

func TestVersionCmd(t *testing.T) {
	buf := &bytes.Buffer{}
	root := newRootCmd()
	root.SetOut(buf)
	root.SetArgs([]string{"version"})
	if err := root.Execute(); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), Version) {
		t.Errorf("expected %q in output, got %q", Version, buf.String())
	}
}

func TestExecute(t *testing.T) {
	if err := Execute([]string{"version"}); err != nil {
		t.Fatal(err)
	}
}
