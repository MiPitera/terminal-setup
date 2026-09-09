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
  60-ssh.sh             zgodność TERM przy ssh
  61-tty-guard.sh       przywracanie dyscypliny linii po narzędziach raw
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

## Kolory

* `ls`, `grep` — aliasy z `--color=auto` + `LS_COLORS` z `dircolors` (`30-aliases.sh`).
  Własną paletę wrzuć do `~/.dircolors`, moduł ją wykryje.
* Podpowiedzi Tab — readline domyślnie ma `colored-stats` i
  `colored-completion-prefix` **wyłączone**, przez co kandydaci są białi mimo
  ustawionego `LS_COLORS`. `40-completion.sh` włącza je przez `bind`, razem z
  `completion-ignore-case` i `show-all-if-ambiguous`.
* `man` — `20-shell-options.sh` ustawia `LESS_TERMCAP_*` i `GROFF_NO_SGR`.

Bash nie ma kolorowania składni w trakcie pisania (to funkcja zsh/fish). Jeśli
tego brakuje: [ble.sh](https://github.com/akinomyoga/ble.sh) — dokłada
highlighting, podpowiedzi z historii i lepsze menu uzupełniania. Nie jest
instalowany przez `install.sh`.

## SSH

kitty ustawia `TERM=xterm-kitty`. `ssh` przekazuje tę wartość dalej, a zdalny
host zwykle nie ma wpisu terminfo `xterm-kitty` — readline nie potrafi wtedy
poprawnie przerysować linii i edycja wklejonej komendy zostawia śmieci
(`./chisel client remote 10.10.15.147/23    :8080    1234`).

Moduł `60-ssh.sh` daje trzy rzeczy:

* `ssh` — funkcja opakowująca, wymusza `TERM=xterm-256color`. Działa zawsze,
  nic nie instaluje na zdalnym hoście. Aktywna tylko gdy `TERM=xterm-kitty`,
  więc poza kitty `ssh` jest zwykłym `ssh`.
* `kssh` — `kitten ssh`, kopiuje terminfo kitty na zdalny host i zachowuje
  funkcje kitty. Wymaga zapisywalnego `$HOME` po drugiej stronie.
* `fixterm` — ratunek dla sesji już rozjechanej (reverse shell, `su`, tmux
  odpalony przed poprawką): ustawia TERM, robi `stty sane` i `reset`.

Żeby ominąć wrapper jednorazowo: `command ssh host`.

## Narzędzia w trybie raw (socat, impacket, reverse shelle)

Osobny objaw, inna przyczyna niż TERM. `socat file:/dev/tty,raw,echo=0`,
`impacket-psexec`, shelle złapane przez `nc` — wszystkie przestawiają tty w tryb
raw i mają przywrócić ustawienia przy wyjściu. Gdy połączenie padnie albo
proces zostanie zabity, nie przywracają. Zostaje `-onlcr`: `\n` przesuwa kursor
w dół, ale nie wraca na kolumnę 0, więc każdy kolejny prompt startuje coraz
dalej w prawo, a wyjście schodkuje. Wygląda to jak zły rozmiar terminala, ale
rozmiar jest poprawny — zepsuta jest dyscyplina linii.

`61-tty-guard.sh` robi snapshot dyscypliny przy pierwszym prompcie, porównuje
przy każdym kolejnym i przywraca, gdy komenda ją zmieniła.

* `TERMINAL_SETUP_TTY_GUARD=0` — wyłącza guard,
* `ttysave` — przyjmij bieżące ustawienia jako nową bazę (po świadomym
  `stty -ixon` itp.),
* `fixterm` — pełny reset, gdy rozjechał się też sam ekran; odświeża bazę.

## Ucinana linia poleceń w zdalnym shellu

Objaw: edytowana komenda renderuje się jako `<...>` z uciętym początkiem i nie
zawija na kolejny wiersz, mimo że w terminalu jest miejsce. Cała komenda jest
w buforze — readline przewija ją poziomo zamiast zawijać.

Przyczyna: zdalny host nie ma wpisu terminfo dla swojego `$TERM` (reverse shell
dziedziczy pusty albo śmieciowy). Readline nie odczyta wtedy capability
autowrap (`am`) i wymusza przewijanie poziome. `bind 'set
horizontal-scroll-mode off'` tego **nie** obejdzie — pomaga wyłącznie
rozwiązywalny `TERM`.

`ptyfix` wypisuje gotowy do wklejenia snippet: wybiera pierwszy wpis terminfo,
który na zdalnym faktycznie istnieje, i przypina geometrię z bieżącego
terminala (reverse shell nie negocjuje jej tak jak ssh).

```
$ ptyfix
for t in xterm-256color xterm vt100; do infocmp "$t" >/dev/null 2>&1 && { export TERM="$t"; break; }; done; stty rows 24 cols 80
```

Wklej wynik do zdalnego shella — najlepiej zaraz po podniesieniu go do pty.

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
