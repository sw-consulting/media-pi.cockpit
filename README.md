# media-pi.cockpit

Media PI Cockpit & sshd container that exposes Cockpit Web UI and a restricted SSH endpoint for reverse UNIX socket tunnels from devices. Dynamic SSH key authorization is delegated to the Media Pi Core API.

Project layout
├─ gateway.Dockerfile
├─ entrypoint.sh
├─ ak-lookup.sh
└─ defaults/
   ├─ cockpit/cockpit.conf
   ├─ ssh/mediapi.conf
   ├─ sshd/sshd_config
   └─ supervisor/
      ├─ cockpit.conf
      └─ sshd.conf

Requirements
- CORE_API: Base URL to core API, e.g. https://core.example.com/api
- CORE_TOKEN: Shared secret (Bearer token) for ak-lookup

Build
docker build -f gateway.Dockerfile -t mediapi/gateway .

Run (example)
- Persist host keys so device fingerprints remain stable:
  -v mediapi-sshd:/etc/ssh 
- Expose Cockpit (HTTP) and sshd:
  -p 9090:9090 -p 22:22

docker run --name mediapi-gateway --rm \
  -e CORE_API=https://core.example.com/api \
  -e CORE_TOKEN=REDACTED \
  -e COCKPIT_ADDRESS=0.0.0.0 \
  -e COCKPIT_PORT=9090 \
  -v mediapi-sshd:/etc/ssh \
  -v mediapi-run:/run/mediapi \
  -p 9090:9090 -p 22:22 \
  mediapi/gateway

Notes
- Cockpit runs with --no-tls; front this with a TLS reverse proxy in production.
- sshd accepts only reverse UNIX socket binds; no TCP forwarding.
- Devices do not need to use -N; the server forces a long-running no-op for the tunnel user so the SSH session stays open while reverse sockets are active.
- Device sockets appear as /run/mediapi/pi-<deviceId>.ssh.sock and are mapped by SSH config in defaults/ssh/mediapi.conf.

Testing
- Unit tests for `ak-lookup.sh` are implemented with `kward/shunit2` and live under `tests/shunit2/ak-lookup_test.sh`.
- CI: GitHub Actions workflow `.github/workflows/shunit2-test.yml` builds a test image (contains shunit2) and runs the tests inside the container.

Run tests locally (Linux / WSL):
1. Build the test image:
```bash
docker build -f test.Dockerfile -t media-pi-cockpit-test:test .
```
2. Run tests inside the image:
```bash
docker run --rm -v "$(pwd):/workspace" --entrypoint /bin/bash media-pi-cockpit-test:test -c "cd /workspace && ./tests/shunit2/ak-lookup_test.sh"
```

Notes
- The tests mock `curl` by adding `tests/mocks/curl` to `PATH` inside the container. Ensure the `ak-lookup.sh` script is executable (`chmod +x ak-lookup.sh`) before running tests.
- The repository no longer contains Bats artifacts; testing uses shunit2 exclusively.
