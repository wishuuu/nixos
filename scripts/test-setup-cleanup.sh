#!/usr/bin/env bash
# Test prawdziwej funkcji cleanup w sandboxie, bez roota i aktywacji systemu.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
source_text=$(< "$root/setup")
cleanup_text=${source_text#*$'cleanup() {\n'}
cleanup_text=${cleanup_text%%$'\ntrap cleanup EXIT'*}
cleanup_text=$'cleanup() {\n'"$cleanup_text"
cleanup_text=${cleanup_text//\/etc\/nixos/\$sandbox\/nixos}

for scenario in activation-failed user-failed success; do
  sandbox="$tmp/$scenario"
  mkdir -p "$sandbox/nixos" "$sandbox/backup" "$sandbox/stage"
  printf new > "$sandbox/nixos/version"
  printf old > "$sandbox/backup/version"
  status=0
  (
    stage="$sandbox/stage"
    backup="$sandbox/backup"
    installed=true
    activated=false
    success=false
    timer_masked_by_setup=true
    timer_was_active=false
    systemctl() { printf '%s\n' "$*" >> "$sandbox/systemctl.log"; }
    eval "$cleanup_text"
    trap cleanup EXIT
    case "$scenario" in
      activation-failed) exit 23 ;;
      user-failed) activated=true; exit 24 ;;
      success) activated=true; success=true; exit 0 ;;
    esac
  ) 2> "$sandbox/stderr" || status=$?
  [[ ! -e $sandbox/stage ]]
  grep -Fxq 'unmask --runtime nixos-upgrade.timer' "$sandbox/systemctl.log"
  case "$scenario" in
    activation-failed)
      [[ $status == 23 && $(< "$sandbox/nixos/version") == old ]]
      [[ ! -e $sandbox/backup ]]
      ! grep -q '^start ' "$sandbox/systemctl.log"
      ;;
    user-failed)
      [[ $status == 24 && $(< "$sandbox/nixos/version") == new ]]
      [[ $(< "$sandbox/backup/version") == old ]]
      grep -q 'konfiguracja użytkownika' "$sandbox/stderr"
      grep -Fxq 'start nixos-upgrade.timer' "$sandbox/systemctl.log"
      ;;
    success)
      [[ $status == 0 && $(< "$sandbox/nixos/version") == new ]]
      [[ $(< "$sandbox/backup/version") == old ]]
      grep -Fxq 'start nixos-upgrade.timer' "$sandbox/systemctl.log"
      ;;
  esac
done
printf 'Test cleanup: błąd aktywacji, błąd dotfiles, sukces: OK\n'
