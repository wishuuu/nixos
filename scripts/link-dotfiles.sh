#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ -f $root/external/dotfiles/install.sh && -f $root/external/nvim/init.lua ]] || {
  echo 'Najpierw: git submodule update --init --recursive' >&2; exit 1;
}
exec bash "$root/external/dotfiles/install.sh" "${1:-cli}" "$root/external/nvim"
