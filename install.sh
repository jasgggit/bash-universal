#!/usr/bin/env bash
# Universal interactive Bash defaults: Debian, Ubuntu, Rocky Linux.
# Usage: sudo bash install.sh [--install|--uninstall|--status]
set -Eeuo pipefail
umask 077

VERSION='1.3.0'
CONFIG='/etc/profile.d/99-jgomes-bash.sh'
STATE='/var/lib/jgomes-bash'
GLOBAL_RC=''
[[ -f /etc/bash.bashrc ]] && GLOBAL_RC=/etc/bash.bashrc
[[ -z $GLOBAL_RC && -f /etc/bashrc ]] && GLOBAL_RC=/etc/bashrc
BEGIN='# >>> JGOMES BASH MANAGED >>>'
END='# <<< JGOMES BASH MANAGED <<<'
ACTION="${1:---install}"

say() { printf '%s\n' "$*"; }
fail() { say "ERRO: $*" >&2; exit 1; }
[[ ${EUID} -eq 0 ]] || fail 'Executar como root (sudo).'
[[ -f /etc/os-release ]] || fail 'Sistema sem /etc/os-release.'
# This installer is intentionally Linux + GNU ls only.
[[ $(uname -s) == Linux ]] || fail 'Apenas Linux; não aplicar no macOS.'
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *debian*|*ubuntu*|*rhel*|*fedora*|*rocky*) ;;
  *) fail "Distribuição não validada: ${ID:-desconhecida}." ;;
esac

# Modify only existing interactive Bash startup files, never user history files.
# Per-user tail hook is needed because ~/.bashrc can override /etc/bash.bashrc.
user_rcs() {
  local name uid home shell
  while IFS=: read -r name _ uid _ _ home shell; do
    [[ $uid =~ ^[0-9]+$ ]] || continue
    [[ $uid -eq 0 || $uid -ge 1000 ]] || continue
    [[ $shell == */bash ]] || continue
    [[ -d $home && ! -L $home ]] || continue
    [[ -f $home/.bashrc && ! -L $home/.bashrc ]] && printf '%s\n' "$home/.bashrc"
  done < /etc/passwd
  # New accounts inherit this hook via /etc/skel.
  [[ -f /etc/skel/.bashrc && ! -L /etc/skel/.bashrc ]] && printf '%s\n' /etc/skel/.bashrc
}

hook() {
  cat <<'HOOK'
# >>> JGOMES BASH MANAGED >>>
# Carregar depois das personalizações locais; apenas Bash interativo.
if [[ $- == *i* && -r /etc/profile.d/99-jgomes-bash.sh ]]; then
    . /etc/profile.d/99-jgomes-bash.sh
fi
# <<< JGOMES BASH MANAGED <<<
HOOK
}

remove_hook() {
  local file=$1 tmp
  [[ -f $file && ! -L $file ]] || return 0
  grep -Fqx "$BEGIN" "$file" || return 0
  tmp=$(mktemp "${file}.XXXXXX")
  # Keep ownership/mode when replacing. No historical data is touched.
  awk -v start="$BEGIN" -v stop="$END" '
    $0 == start { skip=1; next }
    $0 == stop && skip { skip=0; next }
    !skip { print }
  ' "$file" > "$tmp"
  chmod --reference="$file" "$tmp"
  chown --reference="$file" "$tmp"
  mv -f -- "$tmp" "$file"
}

append_hook() {
  local file=$1
  [[ -f $file && ! -L $file ]] || return 0
  if grep -Fqx "$BEGIN" "$file"; then
    grep -Fqx "$END" "$file" || fail "Bloco gerido incompleto em $file"
    return 0
  fi
  printf '\n' >> "$file"
  hook >> "$file"
}

write_config() {
  local tmp
  tmp=$(mktemp /etc/profile.d/.jgomes-bash.XXXXXX)
  cat > "$tmp" <<'CONFIG'
# JGomes Bash - common interactive defaults (managed; do not edit here)
[[ -n ${BASH_VERSION:-} && $- == *i* ]] || return 0

# Respect larger limits already configured. Do not clear/rewrite history.
[[ ${HISTSIZE:-0} =~ ^[0-9]+$ ]] || HISTSIZE=0
[[ ${HISTFILESIZE:-0} =~ ^[0-9]+$ ]] || HISTFILESIZE=0
(( HISTSIZE < 50000 )) && HISTSIZE=50000
(( HISTFILESIZE < 100000 )) && HISTFILESIZE=100000
export HISTSIZE HISTFILESIZE
shopt -s histappend

# Do not overwrite other PROMPT_COMMAND hooks; avoid duplicate history -a.
# Supports both scalar and indexed-array PROMPT_COMMAND (Bash 5.1+).
_jg_pc_decl=$(declare -p PROMPT_COMMAND 2>/dev/null || true)
if [[ $_jg_pc_decl == 'declare -a '* ]]; then
    _jg_found=0
    for _jg_cmd in "${PROMPT_COMMAND[@]}"; do
        [[ $_jg_cmd == *'history -a'* ]] && _jg_found=1
    done
    (( _jg_found )) || PROMPT_COMMAND+=('history -a')
    unset _jg_found _jg_cmd
else
    case ";${PROMPT_COMMAND:-};" in
        *'history -a'*) ;;
        *) PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }history -a" ;;
    esac
fi
unset _jg_pc_decl

# Only override the ordinary directory color; keep other dircolors rules.
# 01;36 = bold cyan, readable on dark terminal backgrounds.
case ":${LS_COLORS:-}:" in
    *':di=01;36:'*) ;;
    *) LS_COLORS="${LS_COLORS:+${LS_COLORS}:}di=01;36" ;;
esac
export LS_COLORS

alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'
alias l='ls -CF --color=auto'

# Kali-style prompt: root red, non-root light green; hostname cyan.
# Preserve the AISYS frame, terminal title, chroot and Python virtualenv.
if (( EUID == 0 )); then
    _jg_user_color='\[\033[1;31m\]'
else
    _jg_user_color='\[\033[1;92m\]'
fi
_jg_host_color='\[\033[1;36m\]'
_jg_frame_color='\[\033[;94m\]'
PS1='\[\e]0;\u@\h: \w\a\]'"${_jg_frame_color}"'┌──${debian_chroot:+($debian_chroot)──}${VIRTUAL_ENV:+(\[\033[0;1m\]$(basename "$VIRTUAL_ENV")\[\033[;94m\])}('"${_jg_user_color}"'\u㉿'"${_jg_host_color}"'\h'"${_jg_frame_color}"')-[\[\033[0;1m\]\w'"${_jg_frame_color}"']\n'"${_jg_frame_color}"'└─'"${_jg_user_color}"'\$\[\033[0m\] '
unset _jg_user_color _jg_host_color _jg_frame_color

CONFIG
  chmod 0644 "$tmp"
  mv -f -- "$tmp" "$CONFIG"
}

case "$ACTION" in
  --install)
    mkdir -p -m 0700 "$STATE"
    stamp=$(date +%Y%m%d-%H%M%S)
    backup="$STATE/backup-$stamp-$$"
    mkdir -m 0700 "$backup"
    # Preserve a copy of each startup file before modification.
    mapfile -t rcs < <(user_rcs | sort -u)
    for rc in "${rcs[@]}"; do
      mkdir -p "$backup$(dirname "$rc")"
      cp -a -- "$rc" "$backup$rc"
      history_file="$(dirname "$rc")/.bash_history"
      if [[ -f $history_file && ! -L $history_file ]]; then
        cp -a -- "$history_file" "$backup$(dirname "$rc")/.bash_history"
      fi
    done
    [[ ! -e $CONFIG ]] || cp -a -- "$CONFIG" "$backup/previous-config.sh"
    if [[ -n $GLOBAL_RC ]]; then
      mkdir -p "$backup$(dirname "$GLOBAL_RC")"
      cp -a -- "$GLOBAL_RC" "$backup$GLOBAL_RC"
    fi
    if [[ -f /etc/profile.d/99-shell-custom.sh ]]; then
      say 'AVISO: configuração manual antiga /etc/profile.d/99-shell-custom.sh detetada; não será removida automaticamente.'
    fi
    write_config
    # Global hook handles interactive Bash, including accounts without ~/.bashrc.
    # Per-user hook at EOF restores our settings after distribution defaults.
    [[ -z $GLOBAL_RC ]] || append_hook "$GLOBAL_RC"
    for rc in "${rcs[@]}"; do append_hook "$rc"; done
    say "Instalado JGomes Bash v$VERSION em ${ID} ${VERSION_ID:-}."
    say "Utilizadores Bash atualizados: ${#rcs[@]}"
    say "Backup dos ficheiros de configuração: $backup"
    say 'Históricos ~/.bash_history existentes foram copiados para o backup; originais intactos.'
    say 'IMPORTANTE: sessões SSH antigas podem manter limites antigos; feche-as com cuidado.'
    say 'Abra NOVA sessão SSH e valide: echo "$HISTSIZE $HISTFILESIZE"; declare -p PROMPT_COMMAND; alias ll; ll /opt'
    ;;
  --uninstall)
    mapfile -t rcs < <(user_rcs | sort -u)
    for rc in "${rcs[@]}"; do remove_hook "$rc"; done
    [[ -z $GLOBAL_RC ]] || remove_hook "$GLOBAL_RC"
    rm -f -- "$CONFIG"
    say 'Blocos geridos removidos dos .bashrc existentes e configuração global apagada.'
    say "Backups de configuração mantidos em $STATE. Históricos intactos."
    ;;
  --status)
    say "Sistema: ${ID} ${VERSION_ID:-}"
    [[ -f $CONFIG ]] && say "Configuração: $CONFIG (instalada)" || say 'Configuração: ausente'
    mapfile -t rcs < <(user_rcs | sort -u)
    [[ -z $GLOBAL_RC ]] || rcs+=("$GLOBAL_RC")
    for rc in "${rcs[@]}"; do
      if grep -Fqx "$BEGIN" "$rc"; then say "HOOK OK: $rc"; else say "HOOK AUSENTE: $rc"; fi
    done
    ;;
  *) fail 'Uso: bash install.sh [--install|--uninstall|--status]' ;;
esac
