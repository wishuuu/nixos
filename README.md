# NixOS: loki + WSL

Moduły systemowe NixOS, zwykłe dotfiles i osobny Neovim. Bez Home Managera.

## Układ

- `flake.nix`, `flake.lock` — wejścia, przypięte wersje, hosty, szablony.
- `hosts/loki/` — laptop: Intel, ext4, NetworkManager, zram, zasilanie.
- `hosts/wsl/` — NixOS-WSL, bez pulpitu i pakietów GUI.
- `modules/base.nix` — konto, Fish, Neovim, Git, CLI, direnv, ustawienia Nix.
- `modules/containers.nix` — Docker (w tym `docker compose`).
- `modules/desktop.nix` — Hyprland, logowanie, audio, aplikacje GUI.
- `modules/updates.nix` — automatyczne aktualizacje obu hostów.
- `hardware-configuration.nix` — sprzęt **wyłącznie tego laptopa**.
- `external/dotfiles/` — podmoduł `wishuuu/dotfiles`, edytowalne konfiguracje.
- `external/nvim/` — podmoduł `wishuuu/nvim-cfg`, zastana konfiguracja bez zmian.
- `templates/` — izolowane środowiska .NET, Rust, Bun/Node.js.

`configuration.nix` to pomocniczy import laptopa, nie samodzielna konfiguracja
bez flakes: moduł desktop wymaga wejścia Zen przekazanego przez flake.
Nie zmieniaj `system.stateVersion` przy aktualizacji pakietów.

## Wdrożenie i aktualizacje jednym poleceniem

Pierwsze uruchomienie na już zainstalowanym NixOS (lub zaimportowanym NixOS-WSL):

```sh
cd ~/nixos
sudo ./setup loki
```

Po pierwszym wdrożeniu `setup` jest poleceniem systemowym, dostępnym również przez sudo:

```sh
setup --list               # dostępne hosty odczytane z flake
sudo setup loki            # wdrożenie bieżącego repo, wersje z flake.lock
sudo setup loki --update   # aktualizacja wszystkich wejść flake i wdrożenie
sudo setup wsl             # tylko wewnątrz NixOS-WSL
```

**Zapisz pracę przed uruchomieniem** — aktywacja może restartować usługi i sesję
pulpitu. Cały proces działa w usłudze systemd, więc zamknięcie terminala go nie
przerywa. Log na żywo: `journalctl -fu nixos-setup.service`. Ostatnie komunikaty
są wyświetlane po zakończeniu. Nie uruchamiaj dwóch wdrożeń jednocześnie.

Skrypt automatycznie:

1. Sprawdza nazwę hosta i odmawia pomylenia hosta WSL z fizycznym laptopem.
2. Pobiera tylko brakujące podmoduły (nie resetuje istniejących zmian).
3. Z opcją `--update` aktualizuje `flake.lock` jako właściciel repo.
4. Buduje system, zanim zastąpi konfigurację i rozpocznie aktywację.
5. Zachowuje `/etc/nixos` jako `/etc/nixos.before-setup-DATA-PID` i instaluje
   rootową kopię źródeł. Ręczne kopiowanie modułów nie jest już potrzebne.
6. Aktywuje system i podłącza dotfiles oraz skrypty jako `oskarw`.
7. Kolidujące pliki użytkownika przenosi do
   `~/.local/state/dotfiles-backups/DATA-PID/`, zachowując pełny układ ścieżek.
8. Zapamiętuje repo w `/var/lib/nixos-setup/source` i wznawia timer aktualizacji.

Bez `--update` setup nie zmienia wersji wejść, nie robi `git pull`, commitów ani
push. `--update` pozostawia zmieniony lock do sprawdzenia i commita, również jeśli
budowanie nie powiedzie się. Korzystaj wyłącznie z zaufanego repo: jego kod jest
uruchamiany jako root. Ustawienia i konto `oskarw` są wspólne dla obecnych hostów.

Dotfiles pozostają dowiązane do lokalnego repo. Nie przenoś go po wdrożeniu;
jeśli to zrobisz, uruchom `sudo ./setup HOST` z nowej lokalizacji. Podmoduły nie
trafiają do `/etc/nixos`. Nowe pliki Nix są uwzględniane nawet przed `git add`.
Samodzielny `install.sh` nadal odmawia kolizji; automatyczne kopie włącza setup.

Skrypt nie partycjonuje dysków, nie instaluje systemu z ISO, nie loguje do GitHuba
ani aplikacji i nie restartuje komputera. Po pierwszym wdrożeniu zaloguj się
ponownie, a po zmianie kernela uruchom system ponownie w dogodnym momencie.
Konfiguracja sprzętowa `loki` pasuje tylko do obecnego laptopa.

Błąd budowania nie aktywuje systemu. Błąd po podmianie `/etc/nixos` przywraca
poprzednie źródła, ale **nie cofa automatycznie częściowej aktywacji ani dotfiles**.
Sprawdź log i w razie potrzeby wykonaj rollback poniżej. Kopie zapasowe nie są
automatycznie usuwane. Zachowaj potrzebne, a stare usuń ręcznie po weryfikacji.

Na ekranie greetd zaloguj się jako `oskarw`. Po ponownym logowaniu działa Fish
oraz członkostwo w grupie Docker. `Super+Enter` otwiera terminal, `Super+D`
launcher, `Super+C` zamyka okno, `Super+L` blokuje ekran. Skróty i touchpad:
`external/dotfiles/config/hypr/`. Włącz Bluetooth przez Blueman, gdy potrzebujesz;
radio domyślnie nie jest włączane przy starcie. Drukowanie, SSH-serwer i gry
nie są włączone. Udostępnianie ekranu korzysta z portalu Hyprland.

### Powrót

```sh
sudo nixos-rebuild switch --rollback
```

Możesz też uruchomić poprzednią generację z menu systemd-boot. Jeśli aktualizacje
ponawiają problem, zatrzymaj timer: `sudo systemctl disable --now nixos-upgrade.timer`.
Rollback NixOS nie cofa dotfiles — te cofasz osobno Gitem. Automatyczny GC usuwa
stare generacje po 14 dniach; menu bootloadera ma limit 10 wpisów.

## Aktualizacje

Oba hosty: niedziela ok. 04:00, losowe opóźnienie do 45 min; pominięty termin jest
nadrabiany po uruchomieniu. System buduje i aktywuje nową wersję bez restartu.
Kernel zacznie działać po ręcznym restarcie. Aktywacja może restartować usługi.

Usługa używa rootowej kopii `/etc/nixos`, odświeża `nixpkgs`, ale nie zapisuje
nowego `flake.lock`. Zen i NixOS-WSL pozostają przypięte do swoich rewizji.
To kompromis: automatycznie aktualizowany system może różnić się od locka repo.
Dla w pełni utrwalonej aktualizacji wykonuj okresowo:

```sh
sudo setup loki --update
# Po sprawdzeniu działania systemu, w repo jako zwykły użytkownik:
git add flake.lock
git commit -m 'Aktualizuj wejścia flake'
```

Logi: `journalctl -u nixos-upgrade`; timer: `systemctl list-timers nixos-upgrade.timer`.
Niepowodzenie budowania nie przełącza systemu; błędy podczas aktywacji mogą wymagać
interwencji. Aktualizacje nie commitują ani nie wypychają niczego do GitHuba.

## NixOS-WSL

Zainstaluj świeży obraz zgodnie z https://nix-community.github.io/NixOS-WSL/ .
Ta konfiguracja jest dla NixOS-WSL, nie Ubuntu z doinstalowanym Nixem.
Obraz ma początkowo własnego użytkownika; z niego (lub roota) sklonuj repo.
W katalogu repo (poza `/etc/nixos`) wykonaj:

```sh
sudo ./setup wsl
```

Jeżeli repo należało do roota/innego użytkownika i oskarw nie może go edytować,
setup kopiuje je do `/home/oskarw/nixos`, pod warunkiem że ta ścieżka jest wolna.
Brakujące narzędzia instalatora pobierane są tymczasowo przez `nix shell`.

Następnie z PowerShell zakończ daną dystrybucję (`wsl --terminate NixOS`, dostosuj
nazwę), uruchom ją ponownie i sprawdź `whoami` — powinno być `oskarw`.
W razie potrzeby ustaw hasło przez `sudo passwd oskarw` z konta administratora.
Dotfiles CLI są już podłączone przez setup; nie musisz uruchamiać osobnego instalatora.

Docker działa wewnątrz WSL. Nie włączaj jednocześnie integracji Docker Desktop
z tą dystrybucją. Grupa `docker` daje uprawnienia równoważne rootowi; nie publikuj
portów kontenerów bez potrzeby (reguły Dockera mogą omijać typowe reguły firewalla).
WSL korzysta z tego samego timera, ale selektora `#wsl` (wybieranego z nazwy hosta).
Timer działa tylko podczas działania dystrybucji WSL, nie uruchamia jej z Windows.
Ręczne aktualizacje: `sudo setup wsl --update`.

## Development i direnv

SDK są projektowe, nie globalne. Przykład dla nowego projektu (ścieżkę dostosuj):

```sh
mkdir -p ~/projects/demo && cd ~/projects/demo
git init
nix flake init -t /home/oskarw/nixos#dotnet
# Pozostałe szablony: #rust, #web
git add flake.nix .envrc
nix flake lock
git add flake.lock
direnv allow
```

Dodaj `.direnv/` do `.gitignore` projektu. Fish automatycznie aktywuje środowisko
po wejściu do katalogu i dezaktywuje po wyjściu. Alternatywnie: `nix develop`.
`direnv allow` wykonuje kod z `.envrc` — zezwalaj tylko zaufanym projektom.
Jeżeli projekt już ma flake lub `.envrc`, połącz konfiguracje zamiast nadpisywać.
Aktualizacja narzędzi danego projektu: `nix flake update` w jego katalogu.

- .NET: `dotnet --info`, `dotnet new console`, `dotnet run` (SDK 10).
- Web: `bun --version`, `node --version` (Node.js 24 LTS), `bun install`.
- Rust, po wejściu w środowisko:

```sh
rustup toolchain install stable --component rustfmt --component clippy --component rust-analyzer
rustup toolchain install nightly --component rustfmt --component clippy --component rust-analyzer
rustup default stable
cargo build
cargo +nightly build
```

Rustup pobiera toolchainy do katalogu użytkownika — nie są przypięte przez Nix.
Dla powtarzalnych projektów commituj `rust-toolchain.toml` z konkretną wersją
(np. `nightly-RRRR-MM-DD`), nie tylko ruchomym `nightly`/`stable`.
Biblioteki natywne dodawaj do `packages` w flake projektu. Gotowe binaria
pobierane przez menedżery pakietów mogą wymagać dostosowania do NixOS.
Uruchamiaj Neovim z katalogu projektu po aktywacji direnv, aby widział jego SDK.
Dotychczasowa konfiguracja Neovima nie była testowana pod kątem zewnętrznych
binarek/LSP; pobierane automatycznie binaria mogą wymagać pakietów Nix.

## Dodatkowe CLI i własne skrypty

W obu hostach dostępne są `fzf`, `bat`, `delta` i `lazygit` (bez zoxide).
Git używa delta do prezentowania diffów. W Fish fzf zapewnia skróty m.in.
`Ctrl+r` (historia), `Ctrl+t` (pliki), `Alt+c` (katalogi).

Przenośne skrypty trzymaj w **`external/dotfiles/bin/`**. Nix przez
`environment.localBinInPath` dodaje `~/.local/bin` do PATH użytkowników.
Instalator tworzy tam dowiązania do wykonywalnych plików z `bin/`, nie
nadpisując istniejących poleceń. Działa dla profili `desktop` i `cli`.

Dodanie skryptu:

1. Utwórz `external/dotfiles/bin/nazwa` z nagłówkiem `#!/usr/bin/env bash`.
2. Wykonaj `chmod +x external/dotfiles/bin/nazwa`.
3. Uruchom `bash scripts/link-dotfiles.sh desktop` (na WSL: `cli`).
4. Po pierwszym włączeniu PATH wyloguj się i zaloguj ponownie. Edycje skryptów
   działają od razu, bez przebudowy NixOS. Nowy skrypt wymaga ponownego
   uruchomienia instalatora, a nowe zależności — dodania pakietów do Nix.

### `sese`: wybór projektu i sesji Zellij

Uruchom `sese` i wybierz katalog przez fzf. Lista zawiera **bezpośrednie
podkatalogi** `~`, `~/personal` i `~/work`, w tym ukryte katalogi oraz dowiązania
do katalogów. Nie przeszukuje głębiej; nie wymaga istnienia personal/work.
Esc lub Ctrl+C kończy wybór bez uruchamiania sesji.

Sesja ma nazwę `sese-NAZWA-SKRÓT_SHA256_ŚCIEŻKI`. Nazwy projektów są czytelne,
a skrót rozróżnia np. `~/personal/api` i `~/work/api`. Ścieżka jest kanonizowana:
dowiązanie do projektu wybiera tę samą sesję. Przeniesienie projektu zmienia nazwę
sesji. Istniejąca sesja zachowuje swoje panele i katalogi; nowa startuje w wybranym
katalogu. Uruchomienie wewnątrz Zellij przełącza sesję bez zagnieżdżania.

Testy logiki (atrapy fzf i Zellij): `bash scripts/test-sese.sh`.

## GitHub CLI i Zellij

Oba narzędzia są w `modules/base.nix`, również na WSL. Po zmianach wystarczy
`sudo setup loki` (na WSL: `sudo setup wsl`).

### GitHub CLI

```sh
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
gh auth status
```

Zaloguj się w przeglądarce zgodnie z instrukcją. `gh auth setup-git` konfiguruje
Git do korzystania z uwierzytelnienia gh. Ustawienia: `~/.config/gh/config.yml`,
alias `gh co NUMER` przełącza na pull request, edytor to Neovim.
Dowiązany jest tylko plik preferencji, **nie cały katalog gh**. Dane logowania
trafiają do systemowego magazynu sekretów lub lokalnego `hosts.yml` (gdy magazyn
jest niedostępny, np. na WSL); nie commituj tego pliku ani nie używaj
`gh auth token` w logach udostępnianych innym. Operacje `gh config set` mogą
zmieniać dowiązane preferencje w repo — sprawdzaj diff przed commitem.

### Zellij

```sh
zellij -s dev          # nowa sesja
zellij list-sessions
zellij attach dev     # powrót do istniejącej sesji
```

Ghostty automatycznie tworzy/przywraca sesję `main` (także w nowych oknach).
Konfiguracja: `~/.config/zellij/config.kdl`, Nord, powłoka Fish.
Pulpit Nord, panel sterowania i skróty opisano w
[`external/dotfiles/README.md`](external/dotfiles/README.md#pulpit-nord).
Hyprland używa teraz `hyprland.lua` i `bindings.lua`; migracja wymaga ponownego
logowania po przebudowie systemu.
Startuje w trybie `locked`, żeby skróty nie kolidowały z Neovimem:

- `Ctrl+a` — wejście do trybu Tab;
- `Ctrl+a`, `1…9` / strzałka — wybór taba i powrót do Locked;
- `Ctrl+a`, `n` — nowy tab i powrót do Locked;
- `Ctrl+a`, `Ctrl+a` — ostatnio aktywny tab i powrót do Locked;
- `Ctrl+a`, `Esc` — anulowanie i powrót do Locked;
- `Ctrl+a`, `Ctrl+p`, `r` / `d` — panel po prawej / poniżej;
- `Ctrl+a`, `Ctrl+o`, `d` — odłączenie sesji (okno Ghostty kończy działanie).

Przejścia do pozostałych trybów i ich bindy pozostają domyślne, w tym powrót
do Normal po ich akcjach. W tych trybach `Ctrl+g` nadal blokuje skróty.
`sese` przełącza z `main` na sesję projektu, bez zagnieżdżania Zellij.

Pasek na dole pokazuje dostępne akcje. Przy zaznaczaniu tekstu w terminalu
przytrzymaj Shift, jeśli Zellij przechwytuje mysz. Odtwarzanie sesji z dysku
jest wyłączone; odłączenie i ponowne dołączenie działa do zamknięcia serwera
Zellij lub restartu systemu. Uruchom nową sesję po zmianach konfiguracji.

## Git i opcjonalne podpisywanie SSH

Imię, email, domyślna gałąź i format podpisu są ustawione systemowo. Podpisywanie
nie jest wymuszone, dopóki nie utworzysz klucza — nie generujemy sekretów w repo.

```sh
# Upewnij się, że plik nie istnieje; wybierz hasło do klucza.
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_signing -C ppwiszu@gmail.com
git config --global user.signingkey ~/.ssh/id_ed25519_signing.pub
git config --global commit.gpgsign true
# W aktywnym ssh-agent:
ssh-add ~/.ssh/id_ed25519_signing
```

Dodaj klucz **publiczny** na GitHub jako „Signing key”. Klucz prywatny i hasło
pozostają poza repo. Przy podpisywaniu poza sesją z agentem Git może pytać o hasło.
Lokalne `git verify-commit` wymaga dodatkowo pliku `gpg.ssh.allowedSignersFile`;
GitHub weryfikuje podpis na podstawie klucza dodanego do konta.

## Podmoduły i publikacja

Pierwszy commit dotfiles istnieje obecnie tylko lokalnie! **Najpierw wypchnij
podmoduł, potem repo główne**, inaczej klonowanie podmodułu na innym urządzeniu
nie znajdzie tego commita. Nie zmieniano zawartości ani historii Neovima.

```sh
git -C external/dotfiles push -u origin main
# Ustaw własny adres repo konfiguracji:
git remote add origin <URL_REPO_NIXOS>
git add .
git commit -m 'Konfiguracja loki i NixOS-WSL'
git push -u origin main
```

Nowy komputer: `git clone --recurse-submodules <URL_REPO_NIXOS>`.
Edycja dotfiles przez `~/.config` zmienia podmoduł, nie wymaga rebuilda:

```sh
git -C external/dotfiles add .
git -C external/dotfiles commit -m 'Zmień skróty'
git -C external/dotfiles push
git add external/dotfiles
git commit -m 'Zaktualizuj dotfiles'
git push
```

Po aktualizacji repo głównego: `git submodule update --init --recursive`.
Podmoduły bywają w detached HEAD — przed własną edycją przełącz/utwórz gałąź.
Nix nie musi odczytywać podmodułów: służą do konfiguracji użytkownika przez skrypt.
Publiczne repo zawiera podany email oraz UUID partycji (identyfikatory, nie hasła).
Nie dodawaj tokenów, prywatnych kluczy ani danych logowania do aplikacji.

## Rozszerzanie

Nowy host: utwórz `hosts/nazwa/default.nix`, wybierz `imports` jak kafelki i dodaj
`nixosConfigurations.nazwa` we flake. Dla fizycznego urządzenia wygeneruj **jego**
konfigurację sprzętową; nie kopiuj UUID laptopa. Host bez GUI nie importuje
`desktop.nix`. Nowy moduł tematyczny umieść w `modules/` i jawnie zaimportuj.
Pakiety CLI wspólne dodawaj do `base.nix`, GUI do `desktop.nix`, SDK do projektu.
Nowe pliki muszą być dodane przez `git add`, aby flake w repo Git je widział.

Zen pochodzi z zewnętrznego `0xc000022070/zen-browser-flake` (dodatkowe źródło
zaufania), NordPass/Discord/Spotify z nixpkgs, z włączonym `allowUnfree`.

## Weryfikacja wykonana podczas przygotowania

- Ewaluacja obu systemów: `nix flake check --no-build`.
- Ewaluacja środowisk developerskich dla x86_64-linux.
- Kontrola składni Bash instalatorów i test dowiązań, ponownego uruchomienia oraz kolizji w tymczasowym katalogu.
- Plan budowy laptopa: `nix build .#nixosConfigurations.loki.config.system.build.toplevel --dry-run`.

Nie wykonano pełnej budowy ani aktywacji systemu. Działanie Hyprlanda, aplikacji,
kamery, usypiania i obrazu WSL należy sprawdzić po wdrożeniu. Inne architektury
szablonów są zadeklarowane, ale nie były tutaj testowane.
