#!/usr/bin/env bash
set -e


if [[ -z "$1" ]]; then
  echo "You must provide a name option to name the directory"
else
  mkdir "./archive/$name"
  cp "./src/Goerli-DssSpell.sol" "./archive/$name"
  cp "./src/Goerli-DssSpell.t.sol" "./archive/$name"
  cp "./src/Goerli-DssSpell.t.base.sol" "./archive/$name"
  echo "Spell, tests and base copied to archive directory"
fi