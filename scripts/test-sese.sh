#!/usr/bin/env bash
# Test bez uruchamiania interaktywnego fzf ani prawdziwych sesji Zellij.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/.config"
export LOG="$tmp/log" WANTED=''
unset ZELLIJ ZELLIJ_SESSION_NAME
mkdir -p "$tmp/bin" "$HOME/personal/same name" "$HOME/work/same name" "$HOME/top/deeper"
cat > "$tmp/bin/fzf" <<'EOF'
#!/usr/bin/env bash
while IFS= read -r -d '' item; do
  if [[ $item == "$WANTED" ]]; then printf '%s\0' "$item"; exit 0; fi
done
exit 1
EOF
cat > "$tmp/bin/zellij" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$PWD" "$@" > "$LOG"
EOF
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH"
run() { bash "$repo/external/dotfiles/bin/sese"; }
export WANTED="$HOME/personal/same name"
run
mapfile -t first < "$LOG"
[[ ${first[0]} == "$WANTED" && ${first[1]} == attach && ${first[2]} == --create ]]
run
mapfile -t again < "$LOG"
[[ ${first[3]} == "${again[3]}" ]]
export WANTED="$HOME/work/same name"
run
mapfile -t second < "$LOG"
[[ ${first[3]} != "${second[3]}" ]]
export ZELLIJ=0
run
mapfile -t nested < "$LOG"
[[ ${nested[1]} == action && ${nested[2]} == switch-session && ${nested[4]} == "$WANTED" ]]
unset ZELLIJ
ln -s "$HOME/work/same name" "$HOME/alias"
export WANTED="$HOME/alias"
run
mapfile -t alias_result < "$LOG"
[[ ${alias_result[3]} == "${second[3]}" ]]
for WANTED in "$HOME/top/deeper" "$HOME/nonexistent"; do
  export WANTED
  rm -f "$LOG"
  run
  [[ ! -e $LOG ]]
done
# Instalator udostępnia skrypt, jest idempotentny i nie dowiązuje całego gh.
bash "$repo/external/dotfiles/install.sh" cli >/dev/null
bash "$repo/external/dotfiles/install.sh" cli >/dev/null
[[ -x $HOME/.local/bin/sese && ! -L $HOME/.config/gh ]]
# Kolizja bez zgody odmawia zmian; setup może jawnie włączyć kopie.
rm "$HOME/.config/fish"
mkdir "$HOME/.config/fish"
printf 'zachowaj\n' > "$HOME/.config/fish/local.fish"
if bash "$repo/external/dotfiles/install.sh" cli >/dev/null 2>&1; then
  echo 'Błąd: instalator zaakceptował kolizję bez kopii' >&2; exit 1
fi
export DOTFILES_BACKUP_DIR="$HOME/backups/test"
bash "$repo/external/dotfiles/install.sh" cli >/dev/null
[[ -L $HOME/.config/fish ]]
[[ $(< "$DOTFILES_BACKUP_DIR/${HOME#/}/.config/fish/local.fish") == zachowaj ]]
bash "$repo/external/dotfiles/install.sh" cli >/dev/null
printf 'Testy sese i instalatora: OK\n'
