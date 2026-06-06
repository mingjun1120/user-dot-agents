#!/usr/bin/env bash
#
# install.sh — symlink this repo's agent config back into your home directories.
#
# Links created:
#   ~/.agents/skills        ->  <repo>/skills          (skills, shared)
#   ~/.claude/skills        ->  <repo>/skills          (skills, shared)
#   ~/.claude/hooks         ->  <repo>/hooks
#   ~/.claude/settings.json ->  <repo>/settings.json
#   ~/.claude/CLAUDE.md     ->  <repo>/CLAUDE.md
#
# Cross-platform: macOS, Linux, and Windows (Git Bash / MSYS2).
#   On Windows, native symlinks require EITHER "Developer Mode" turned on
#   (Settings > Privacy & security > For developers) OR running this script
#   from an elevated (Administrator) shell.
#
# Safety:
#   * If a target is already a symlink, it is simply re-pointed.
#   * If a target is an empty leftover directory, it is removed.
#   * If a target is a real file/dir, it is moved to "<target>.backup"
#     (timestamped if a .backup already exists) BEFORE the link is created.
#
# Usage:
#   bash install.sh

set -u

# ---- pretty output ---------------------------------------------------------
if [ -t 1 ]; then
  B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'
else
  B=""; G=""; Y=""; R=""; D=""; N=""
fi
ok()   { printf '%s  + %s%s\n' "$G" "$1" "$N"; }
info() { printf '%s  . %s%s\n' "$D" "$1" "$N"; }
warn() { printf '%s  ! %s%s\n' "$Y" "$1" "$N"; }
err()  { printf '%s  x %s%s\n' "$R" "$1" "$N"; }

FAILED=0

# ---- locate repo root (this script's directory, resolving symlinks) --------
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  dir="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  case "$SOURCE" in /*) ;; *) SOURCE="$dir/$SOURCE" ;; esac
done
REPO="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

# ---- detect OS; enable native symlinks on Windows shells -------------------
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*) OS="windows"
    export MSYS="winsymlinks:nativestrict"
    export CYGWIN="winsymlinks:nativestrict" ;;
  Darwin) OS="macos" ;;
  *)      OS="linux" ;;
esac

printf '%sInstalling agent config%s\n' "$B" "$N"
info "repo: $REPO"
info "os:   $OS"
echo

# ---- helpers ---------------------------------------------------------------
is_empty_dir() { [ -d "$1" ] && [ -z "$(ls -A "$1" 2>/dev/null)" ]; }

# link_one <source-in-repo> <target-in-home>
link_one() {
  local src="$1" dest="$2"

  if [ ! -e "$src" ]; then
    warn "skip (source missing): ${src#"$REPO"/}"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    rm -f "$dest"                       # already a symlink -> re-point it
  elif is_empty_dir "$dest"; then
    rmdir "$dest"                       # empty leftover dir -> drop it
  elif [ -e "$dest" ]; then
    local backup="${dest}.backup"       # real file/dir -> preserve it
    [ -e "$backup" ] && backup="${dest}.backup.$(date +%Y%m%d-%H%M%S)"
    mv "$dest" "$backup"
    info "backed up existing -> ${backup}"
  fi

  if ln -s "$src" "$dest" 2>/dev/null; then
    ok "${dest}  ->  ${src#"$REPO"/}"
  else
    err "failed to link ${dest}"
    if [ "$OS" = "windows" ]; then
      err "  on Windows: enable Developer Mode or run this shell as Administrator"
    fi
    FAILED=1
  fi
}

# ---- the links -------------------------------------------------------------
AGENTS="$HOME/.agents"
CLAUDE="$HOME/.claude"

link_one "$REPO/skills"        "$AGENTS/skills"          # skills -> .agents
link_one "$REPO/skills"        "$CLAUDE/skills"          # skills -> .claude
link_one "$REPO/hooks"         "$CLAUDE/hooks"
link_one "$REPO/settings.json" "$CLAUDE/settings.json"
link_one "$REPO/CLAUDE.md"     "$CLAUDE/CLAUDE.md"

echo
if [ "$FAILED" -eq 0 ]; then
  ok "Done. All links are in place."
else
  err "Finished with errors (see above)."
  exit 1
fi
