#!/usr/bin/env bash
cd example
nix-build |& grep RUNNING
echo 'another license clause' >> LICENSE
nix-build |& grep RUNNING
echo LICENSE >> docs.txt
nix-build |& grep RUNNING
echo 'another license clause' >> LICENSE
nix-build |& grep RUNNING
