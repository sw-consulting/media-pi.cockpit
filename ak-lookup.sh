#!/usr/bin/env bash
# Authorize device SSH keys dynamically by consulting media-pi.core.
# If authorized, print a single authorized_keys line with strict options.
# If not, print nothing and exit non-zero (sshd will deny access).

set -Euo pipefail

USER_ARG="${1:-}"   # expected 'tunnel'
KEY_TYPE="${2:-}"   # e.g., ssh-ed25519
FPRINT="${3:-}"     # e.g., SHA256:AbCdEf...
KEY_B64="${4:-}"    # base64 public key body (no type/comment)

CORE_API="${CORE_API:-}"     # e.g., https://mediapi.sw.consulting:8085/api
CORE_TOKEN="${CORE_TOKEN:-}" # shared secret (Bearer)

[ -n "$CORE_API" ] || exit 2

# Derive deviceId from the fingerprint we were given by sshd.
# FPRINT looks like "SHA256:AbC/+=" ; make it URL-safe and strip padding.
FP_ONLY="${FPRINT#SHA256:}"
FP_URLSAFE="$(printf "%s" "$FP_ONLY" | tr '+/' '-_' | tr -d '=')"
DEVICE_ID="fp-${FP_URLSAFE}"

# Ensure sshd provided type and key body
[ -n "${KEY_TYPE}" ] && [ -n "${KEY_B64}" ] || exit 3

# Ask core if this device is allowed (and which sshUser Cockpit should use)
# Implement GET /api/ssh/authorize?deviceId=<id> in your core.
RESP="$(curl -fsS --connect-timeout 2 --max-time 5 --retry 2 \
               -H "Authorization: Bearer ${CORE_TOKEN}" \
               "${CORE_API}/ssh/authorize?deviceId=${DEVICE_ID}")" || exit 4

# Parse basic response using jq
ALLOWED="$(printf "%s" "$RESP" | jq -r '.allowed // false')"
[ "$ALLOWED" = "true" ] || exit 5

SSH_USER="$(printf "%s" "$RESP" | jq -r '.sshUser // "pi"')"

# The exact socket we will allow this device to bind on this box:
SOCK_PATH="/run/mediapi/pi-${DEVICE_ID}.ssh.sock"

# Print a STRICT authorized_keys line with this exact offered key.
# IMPORTANT: do NOT include "no-port-forwarding" (it disables streamlocal too).
printf 'no-pty,no-agent-forwarding,no-X11-forwarding,command="/bin/false",permitlisten="%s" %s %s device=%s user=%s\n' \
  "$SOCK_PATH" "$KEY_TYPE" "$KEY_B64" "$DEVICE_ID" "$SSH_USER"
