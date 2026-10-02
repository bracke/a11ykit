# Troubleshooting Guide

This guide records common failure modes while the native transports are still
staged and semantic/router scaffolds are being expanded.

## Build Failures

Use `alr build` and `alr exec -- gprbuild -q -P tests/all_tests.gpr` from the
repository root. The project pins GNAT through Alire; system compiler results
are not authoritative.

If `alr exec -- gnatls --version` prints a compiler banner that differs from
the Alire package patch number, inspect `alire/alire.lock` and
`tests/alire/alire.lock`. The release gate requires both lockfiles to resolve
`gnat_native` release `15.2.1` and provide `gnat=15.2.1`.

## Release Gate Failures

`tests/bin/release_check` reports stable `FAIL` lines. Check the named
conformance declaration, report schema, documentation marker, or qualification
scenario before changing tests.

## Documentation Report

Run `tests/bin/documentation_report --json` to inspect required docs and marker
coverage. Missing or incomplete entries should be fixed in the document or
manifest rather than bypassed.

## Native Backend Unavailable

Native backends currently return structured unavailable results for live
transport/provider registration. This is expected until Linux D-Bus transport,
Windows COM export, and macOS AppKit bridge work is implemented.

## Protected Text Failures

If protected text appears in a value, text range, event, snapshot, or
diagnostic, treat it as a release-blocking security bug.
