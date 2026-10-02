# Contributor Guide

Contributions should move the library toward a platform-neutral semantic model
with faithful native backend projection.

## Build Discipline

Use the pinned Alire toolchain. Do not use system GNAT, system GPRbuild, shell
scripts, Python scripts, or non-Ada repository tooling for build/release
automation.

## Change Scope

Keep public semantic APIs platform-neutral. Backend-specific code belongs under
backend-private packages and must not leak D-Bus, COM, Objective-C, or native
handle types into common public packages.

## Tests

Add tests in the `a11y_tests` child crate. Portable semantics should be tested
through the Null backend and semantic packages before native scaffolds claim
support.

## Documentation

Update the relevant guide and the Ada documentation manifest when a public
semantic concept, backend mapping, release gate, or security behavior changes.

## Native Claims

Do not advertise native support without common semantics, Null Backend
validation, conformance identifiers, resource/security documentation, and
native integration evidence.
