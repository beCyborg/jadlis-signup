#!/usr/bin/env bash
# preflight.sh — check that everything the signup skill needs is installed and configured.
# No network, no secrets: reads only whether agent.conf keys are set (values are never printed) and file/PATH presence.
# Exit 0 = ready, 1 = something is missing (the checklist says what), 64 = bad usage.
#
# Overrides (for tests): JADLIS_AGENT_CONF (default ~/.config/jadlis/agent.conf),
#                        JADLIS_SCRIPTS_DIR (default ~/.claude/scripts).
set -u

case "${1:-}" in
  -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) echo "usage: preflight.sh [--help]" >&2; exit 64 ;;
esac

conf="${JADLIS_AGENT_CONF:-$HOME/.config/jadlis/agent.conf}"
sdir="${JADLIS_SCRIPTS_DIR:-$HOME/.claude/scripts}"
fail=0

ok()   { printf '  [ok]      %s\n' "$1"; }
miss() { printf '  [missing] %s\n' "$1"; fail=1; }
note() { printf '  [note]    %s\n' "$1"; }

# value of KEY in agent.conf (last assignment wins), quotes stripped; never printed
conf_value() {
  grep -E "^[[:space:]]*(export[[:space:]]+)?$1=" "$conf" 2>/dev/null | tail -1 \
    | sed -E "s/^[[:space:]]*(export[[:space:]]+)?$1=//; s/[[:space:]]+#.*$//; s/^[\"']//; s/[\"']$//"
}
conf_has() { grep -qE "^[[:space:]]*(export[[:space:]]+)?$1=" "$conf" 2>/dev/null; }

echo "jadlis-signup preflight"

echo "Config: $conf"
if [[ -f "$conf" ]]; then
  ok "agent.conf exists"
  for k in OP_VAULT ALIAS_PREFIX BROWSER_PROFILE; do
    if [[ -n "$(conf_value "$k")" ]]; then ok "$k is set"
    elif conf_has "$k"; then miss "$k is empty (required)"
    else miss "$k is absent (required)"; fi
  done
  for k in MAIL_ACCOUNT MAIL_FOLDER SIGNUP_NAME ALLOW_OAUTH; do
    if [[ -n "$(conf_value "$k")" ]]; then ok "$k is set"
    else
      case "$k" in
        MAIL_ACCOUNT) note "$k empty: mail-wait.sh uses the jm default account" ;;
        MAIL_FOLDER)  note "$k empty: defaults to \"All Mail\"" ;;
        SIGNUP_NAME)  note "$k empty: the skill asks for a name each time" ;;
        ALLOW_OAUTH)  note "$k empty: OAuth sign-in stays a human step" ;;
      esac
    fi
  done
else
  miss "agent.conf (copy agent.conf.example from jadlis-secrets and fill it)"
fi

echo "Scripts: $sdir"
for s in op-agent.sh secret-relay.py proton-alias.sh:jadlis-secrets mail-wait.sh:jadlis-mail agent-chrome.sh:jadlis-browser; do
  name="${s%%:*}"; from="${s#*:}"
  [[ "$from" == "$s" ]] && from="jadlis-secrets"
  if [[ -x "$sdir/$name" ]]; then ok "$name"
  elif [[ -e "$sdir/$name" ]]; then miss "$name exists but is not executable (chmod +x)"
  else miss "$name (install step of $from)"; fi
done

echo "Commands on PATH"
for c in op pass-cli himalaya jq python3; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c"; else miss "$c"; fi
done

echo "Agent"
agent_found=""
for d in "${CLAUDE_CONFIG_DIR:-}" "$HOME/.claude"; do
  [[ -n "$d" && -f "$d/agents/browser-operator.md" ]] && { agent_found="$d/agents/browser-operator.md"; break; }
done
if [[ -n "$agent_found" ]]; then ok "browser-operator ($agent_found)"
else miss "browser-operator agent (install it from the jadlis-browser template)"; fi

echo
if [[ $fail -eq 0 ]]; then echo "READY"; else echo "NOT READY: fix the [missing] items above"; fi
exit $fail
