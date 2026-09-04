# terminal-setup

Przenośna konfiguracja `bash` + `kitty` (motyw i fonty), instalowana jednym
skryptem na Ubuntu, Debianie, Kali i Fedorze.

## Instalacja na nowej maszynie

```bash
git clone <adres-repo> ~/terminal-setup
cd ~/terminal-setup
./install.sh
```

Skrypt:

1. wykrywa dystrybucję z `/etc/os-release` (rodzina `debian` → `apt-get`,
   `fedora` → `dnf`/`dnf5`),
2. instaluje pakiety: `kitty git bash-completion fontconfig curl unzip
   ca-certificates`,
3. pobiera fonty do `~/.local/share/fonts/terminal-setup`:
   **DM Mono** (Google Fonts) i **Symbols Nerd Font** (glify powerline),
4. robi kopię zapasową istniejących plików (`*.terminal-setup-backup.<data>`),
5. podpina `~/.bashrc`, `~/.config/kitty/kitty.conf` i `~/.config/kitty/theme.conf`
   jako symlinki do repo,
6. zakłada `~/.bashrc.local` z szablonu (jeżeli jeszcze nie istnieje).

Po instalacji: `exec bash`, a w kitty `Ctrl+Shift+F5`.

## Opcje

| Flaga | Działanie |
|---|---|
| `--no-packages` | pomija menedżer pakietów (nie wymaga roota) |
| `--no-fonts` | pomija pobieranie fontów |
| `--bash-only` / `--kitty-only` | instaluje tylko jedną część |
| `--copy` | kopiuje pliki zamiast symlinków (repo można potem skasować) |
| `--theme NAZWA` | motyw kitty z `kitty/themes` (domyślnie `Espresso`) |
| `--dry-run` | pokazuje co zrobi, nic nie zmienia |
| `--uninstall` | usuwa symlinki i przywraca najnowsze kopie zapasowe |

Bez roota i bez sieci:

```bash
./install.sh --no-packages --no-fonts
```

## Struktura

```
install.sh              instalator
lib/distro.sh           detekcja dystrybucji, mapowanie pakietów
bash/bashrc             loader – ustala TERMINAL_SETUP_DIR i ładuje moduły
bash/bashrc.d/          moduły ładowane leksykalnie
  10-history.sh         historia
  20-shell-options.sh   shopt, EDITOR, lesspipe
  30-aliases.sh         aliasy i kolory
  40-completion.sh      bash-completion + __git_ps1 (różne ścieżki per distro)
  50-prompt.sh          prompt powerline
  90-tools.sh           PATH, nvm, bun, deno, cargo, go, Android SDK
bash/bashrc.local.example  szablon ustawień lokalnych
kitty/kitty.conf        konfiguracja kitty
kitty/themes/           motywy
```

## Rzeczy per-maszyna

Nie edytuj plików z repo dla ustawień jednej maszyny — użyj:

* `~/.bashrc.local` — ładowany na końcu, nadpisuje moduły,
* `~/.config/kitty/local.conf` — wciągany przez `globinclude` w `kitty.conf`.

Oba pliki nie są w repo i instalator ich nie nadpisuje.

## Prompt

```
 użytkownik ▶ gałąź-git ▶ ścieżka ▶
```

Zmienne sterujące (ustaw w `~/.bashrc.local`):

* `TERMINAL_SETUP_POWERLINE=0` — separatory ASCII zamiast glifów powerline
  (przydatne na gołej konsoli tekstowej; wykrywane automatycznie dla `TERM=linux`),
* `TERMINAL_SETUP_SHOW_HOST=1` — zawsze pokazuj hostname (domyślnie tylko po SSH).

Segment gałęzi wymaga `__git_ps1`. Moduł `40-completion.sh` szuka go kolejno w:
`/usr/lib/git-core/git-sh-prompt` (Debian/Ubuntu/Kali),
`/usr/share/git-core/contrib/completion/git-prompt.sh` (Fedora) i kilku innych.
Gdy go nie ma, prompt po prostu pomija segment gałęzi.

## Nowy motyw kitty

Wrzuć plik `.conf` do `kitty/themes/` i uruchom `./install.sh --kitty-only
--theme NazwaPliku`. Gotowe motywy: <https://github.com/kovidgoyal/kitty-themes>.

## Uwagi migracyjne

* Stary `~/.bashrc` miał zaszyte ścieżki `/home/taliyah/...` (deno, snap) —
  teraz wszystko jest względem `$HOME` i pod warunkiem `[[ -r ... ]]`.
* `synth-shell-prompt.sh` był ładowany, ale `build_prompt` i tak nadpisywał
  `PS1`, więc został usunięty. Jeśli go chcesz, dodaj `source` w `~/.bashrc.local`.
* DM Mono nie ma glifów powerline — dlatego `kitty.conf` mapuje zakresy
  Private Use Area na `Symbols Nerd Font Mono`.
