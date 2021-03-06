#!/usr/bin/env bash
set -euo pipefail
cd example
set -v
remove_noise () {
  grep RUNNING || true
}

nix-build |& remove_noise
echo

echo 'another license clause' >> LICENSE
nix-build |& remove_noise
echo

echo LICENSE >> docs.txt
nix-build |& remove_noise
echo

echo 'another license clause' >> LICENSE
nix-build |& remove_noise
echo
