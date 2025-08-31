#!/usr/bin/env bash
# tests/shunit2/ak-lookup_test.sh
# shunit2 tests for ak-lookup.sh (kward/shunit2)

set -uo pipefail

SHUNIT2=${SHUNIT2:-/opt/shunit2/shunit2}

setUp() {
  mkdir -p tests/mocks
  PATH="$(pwd)/tests/mocks:$PATH"
  export PATH
  export CORE_API="https://example.com/api"
  export CORE_TOKEN="test-token"
}

tearDown() {
  rm -rf tests/mocks
  unset CORE_API CORE_TOKEN
}

run_script() {
  OUTPUT="$(ak-lookup.sh "$@" 2>&1)"
  RC=$?
}

test_missing_CORE_TOKEN() {
  unset CORE_TOKEN
  run_script "" "ssh-ed25519" "SHA256:AbCdEf" "AAAA..."
  assertEquals 3 "$RC"
  export CORE_TOKEN="test-token"
}

test_missing_KEY_TYPE() {
  run_script "" "" "SHA256:AbCdEf" "AAAA..."
  assertEquals 3 "$RC"
}

test_missing_KEY_B64() {
  run_script "" "ssh-ed25519" "SHA256:AbCdEf" ""
  assertEquals 3 "$RC"
}

test_curl_failure_exit_code() {
  cat > tests/mocks/curl <<'EOF'
#!/bin/bash
exit 1
EOF
  chmod +x tests/mocks/curl
  run_script "" "ssh-ed25519" "SHA256:AbCdEf" "AAAA..."
  assertEquals 4 "$RC"
}

test_api_returns_not_allowed() {
  cat > tests/mocks/curl <<'EOF'
#!/bin/bash
echo '{"allowed": false}'
EOF
  chmod +x tests/mocks/curl
  run_script "" "ssh-ed25519" "SHA256:AbCdEf" "AAAA..."
  assertEquals 5 "$RC"
}

test_allowed_default_user_outputs() {
  cat > tests/mocks/curl <<'EOF'
#!/bin/bash
echo '{"allowed": true}'
EOF
  chmod +x tests/mocks/curl
  run_script "" "ssh-ed25519" "SHA256:AbCdEf" "AAAA..."
  assertEquals 0 "$RC"
  printf '%s' "$OUTPUT" | grep -F 'restrict,permitlisten="/run/mediapi/pi-fp-AbCdEf.ssh.sock"' >/dev/null
  printf '%s' "$OUTPUT" | grep -F 'ssh-ed25519 AAAA...' >/dev/null
  printf '%s' "$OUTPUT" | grep -F 'device=fp-AbCdEf' >/dev/null
  printf '%s' "$OUTPUT" | grep -F 'user=pi' >/dev/null
}

test_allowed_custom_user_outputs() {
  cat > tests/mocks/curl <<'EOF'
#!/bin/bash
echo '{"allowed": true, "sshUser": "customuser"}'
EOF
  chmod +x tests/mocks/curl
  run_script "" "ssh-ed25519" "SHA256:AbCdEf" "AAAA..."
  assertEquals 0 "$RC"
  printf '%s' "$OUTPUT" | grep -F 'user=customuser' >/dev/null
}

test_fingerprint_special_chars() {
  cat > tests/mocks/curl <<'EOF'
#!/bin/bash
echo '{"allowed": true}'
EOF
  chmod +x tests/mocks/curl
  run_script "" "ssh-ed25519" "SHA256:AbC/+==" "AAAA..."
  assertEquals 0 "$RC"
  printf '%s' "$OUTPUT" | grep -F 'device=fp-AbC_-' >/dev/null
}

test_invalid_json_from_api() {
  cat > tests/mocks/curl <<'EOF'
#!/bin/bash
echo 'not a json'
EOF
  chmod +x tests/mocks/curl
  run_script "" "ssh-ed25519" "SHA256:AbCdEf" "AAAA..."
  assertEquals 5 "$RC"
}

# run shunit2
[ -f "$SHUNIT2" ] || { echo "shunit2 not found at $SHUNIT2"; exit 1; }
. "$SHUNIT2"
