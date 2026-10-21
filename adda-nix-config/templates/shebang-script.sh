#!/usr/bin/env nix
# shellcheck shell=sh
# Specify the dependencies and other flags.
#! nix shell nixpkgs#hello nixpkgs#cowsay
# Specify the real interpreter.
#! nix --command sh
# Additional documentation:
# https://nix.dev/manual/nix/2.22/command-ref/new-cli/nix3-shell#use-as-a--interpreter
hello | cowsay

