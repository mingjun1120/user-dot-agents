#!/usr/bin/env bash
# PreToolUse safety hook for the Bash tool.
# Defense-in-depth beyond permissions.deny: inspects the FULL command string
# and blocks destructive patterns regardless of flag order or position.
# Reads the hook JSON on stdin; on a match it emits a PreToolUse "deny"
# decision and exits 0. No match -> exits 0 silently (command proceeds).

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

deny() {
  jq -nc --arg r "Blocked by safety hook ($1)" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# A command "start" is the beginning of the string or anything following a
# shell separator: whitespace, ; & | ( or a backtick.
S='(^|[[:space:];&|(`])'

# --- Delete: rm with any recursive/force flag, any order, long or short ---
# Match rm followed by any tokens, then a *flag token* (space-prefixed dash)
# that contains r/R/f, or the long --recursive/--force. Filenames with dashes
# (e.g. ./my-report) are single tokens and never start with '-', so they pass.
echo "$cmd" | grep -Eq "${S}rm([[:space:]]+[^[:space:]]+)*[[:space:]]+(-[[:alnum:]]*[rRf][[:alnum:]]*|--recursive|--force)" \
  && deny "rm -r/-f"

# --- Delete via find: -delete, or -exec/-execdir rm (same destruction, diff binary) ---
# Token-anchored like the rm rule above: a path/expr like ./my-delete-file is one
# token and never matches the standalone "-delete" / "rm" flag tokens we look for.
echo "$cmd" | grep -Eq "${S}find([[:space:]]+[^[:space:]]+)*[[:space:]]+-delete([[:space:]]|$)" \
  && deny "find -delete"
echo "$cmd" | grep -Eq "${S}find([[:space:]]+[^[:space:]]+)*[[:space:]]+-exec(dir)?[[:space:]]+rm([[:space:]]|$)" \
  && deny "find -exec rm"

# --- Highest privileges ---
echo "$cmd" | grep -Eq "${S}sudo([[:space:]]|$)" && deny "sudo"

# --- Disk destruction ---
echo "$cmd" | grep -Eq "${S}dd([[:space:]]|$)"               && deny "dd"
echo "$cmd" | grep -Eq "${S}mkfs(\.[[:alnum:]]+)?([[:space:]]|$)" && deny "mkfs"
echo "$cmd" | grep -Eq "${S}diskutil[[:space:]]+erase"       && deny "diskutil erase"

# --- Permission abuse: chmod ... 777 (covers 0777 and -R) ---
echo "$cmd" | grep -Eq "${S}chmod[[:space:]][^;&|]*777" && deny "chmod 777"

# --- Irreversible Git operations ---
echo "$cmd" | grep -Eq "${S}git[[:space:]].*reset[[:space:]].*--hard" && deny "git reset --hard"
echo "$cmd" | grep -Eq "${S}git[[:space:]].*push[[:space:]].*(--force(-with-lease)?|[[:space:]]-f([[:space:]]|$))" && deny "git push --force"
echo "$cmd" | grep -Eq "${S}git[[:space:]].*clean([[:space:]]+[^[:space:]]+)*[[:space:]]+(-[[:alnum:]]*f[[:alnum:]]*|--force)" && deny "git clean -f"
echo "$cmd" | grep -Eq "${S}git[[:space:]].*branch([[:space:]]+[^[:space:]]+)*[[:space:]]+-D([[:space:]]|$)" && deny "git branch -D"

# --- System shutdown/restart ---
echo "$cmd" | grep -Eq "${S}(shutdown|reboot)([[:space:]]|$)" && deny "shutdown/reboot"

# --- File truncation/emptying ---
echo "$cmd" | grep -Eq "${S}truncate([[:space:]]|$)" && deny "truncate"
echo "$cmd" | grep -Eq "${S}:[[:space:]]*>"          && deny ": > truncation"

exit 0
