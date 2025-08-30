#!/usr/bin/env bash
set -Eeuo pipefail

: "${COCKPIT_ADDRESS:=0.0.0.0}"
: "${COCKPIT_PORT:=9090}"
: "${COCKPIT_LOGIN_TITLE:=Media Pi Cockpit Gateway}"

# Required for ak-lookup.sh (fail fast if missing in prod)
: "${CORE_API:?Set CORE_API to your media-pi.core base URL, e.g. https://.../api}"
: "${CORE_TOKEN:?Set CORE_TOKEN (shared secret)}"

# Sockets dir for reverse UNIX forwards
install -d -m 0770 -g mediapi-sock /run/mediapi

# Persisted host keys may be absent on first run → generate
if ! ls /etc/ssh/ssh_host_* >/dev/null 2>&1; then
  ssh-keygen -A
fi

# Export cockpit address/port for the supervisor command (optional)
export COCKPIT_ADDRESS COCKPIT_PORT

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

