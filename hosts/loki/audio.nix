{ ... }:
{
  # ALC256 w tym laptopie: fizyczny mikrofon jest na pinie 0x1b
  # (Internal Mic 1), a domyślny profil ACP wybiera niepodłączony 0x13.
  # Nadpisanie ścieżki ACP dotyczy tylko loki; profile słuchawek zostają bez zmian.
  environment.etc."alsa-card-profile/mixer/paths/analog-input-internal-mic.conf".source =
    ./analog-input-internal-mic.conf;
}
