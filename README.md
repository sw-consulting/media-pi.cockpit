# media-pi.cockpit

Media PI Cockpit & sshd Container

gateway/
├─ gateway.Dockerfile
├─ entrypoint.sh
├─ defaults/
│  ├─ cockpit/cockpit.conf
│  ├─ ssh/mediapi.conf
│  ├─ sshd/sshd_config
│  └─ supervisor/
│     ├─ cockpit.conf
│     └─ sshd.conf
└─ ak-lookup.sh
