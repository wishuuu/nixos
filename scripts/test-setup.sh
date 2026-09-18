#!/usr/bin/env bash
# Regresja: systemd uruchamia skrypt bez PATH z profilu logowania.
# Test nie aktywuje systemu, nie potrzebuje sudo i nie dotyka /etc/nixos.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for minimal_path in '' /usr/bin:/bin; do
  hosts=$(env -i HOME="$HOME" USER="$(id -un)" PATH="$minimal_path" \
    /run/current-system/sw/bin/bash "$repo/setup" --list)
  grep -Fxq loki <<< "$hosts"
  grep -Fxq wsl <<< "$hosts"
done
printf 'Test setup z pustym/minimalnym PATH: OK\n'
