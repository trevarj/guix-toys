#!/usr/bin/env sh

# Extracts %load-path-like variables from "guix" command and transforms them
# into PATH format.
function extractvar () {
  cmds="
  (use-modules (gnu packages))
  (%package-module-path)
  $1"

  echo $(echo "$cmds" | guix repl \
  | tail -2 | head -1 \
  | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g' \
  | sed -E 's/^\$2 \= \((.+)\)$/\1/' \
  | sed 's/" "/":"/g' \
  | sed 's/"//g')
}

# Run toys.scm with LOAD variables from guix process. Fixes ABI-mismatches.
GUILE_LOAD_PATH="$(extractvar %load-path)" \
  GUILE_LOAD_COMPILED_PATH="$(extractvar %load-compiled-path)" ./toys.scm
