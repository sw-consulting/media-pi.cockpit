# gateway.Dockerfile
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8

# cockpit-ws, OpenSSH server/client, jq for JSON, nc for UNIX sockets, supervisor, tini
RUN apt-get update && apt-get install -y --no-install-recommends \
      cockpit-ws \
      openssh-server openssh-client \
      jq curl netcat-openbsd \
      supervisor tini ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

# Create restricted 'tunnel' user for device reverse tunnels (no shell)
RUN useradd --system --create-home --shell /usr/sbin/nologin --user-group tunnel

# Runtime dirs
RUN mkdir -p /run/sshd /run/mediapi \
 && groupadd -f mediapi-sock \
 && usermod -a -G mediapi-sock tunnel \
 && chgrp mediapi-sock /run/mediapi \
 && chmod 0770 /run/mediapi

# Default configs baked into the image (you can override by mounting)
COPY defaults/cockpit/cockpit.conf      /etc/cockpit/cockpit.conf
COPY defaults/ssh/mediapi.conf          /etc/ssh/ssh_config.d/mediapi.conf
COPY defaults/sshd/sshd_config          /etc/ssh/sshd_config
COPY defaults/supervisor/cockpit.conf   /etc/supervisor/conf.d/cockpit.conf
COPY defaults/supervisor/sshd.conf      /etc/supervisor/conf.d/sshd.conf

# AuthorizedKeysCommand script (used by sshd to authorize device keys)
COPY ak-lookup.sh /usr/local/bin/ak-lookup
RUN chmod +x /usr/local/bin/ak-lookup

# Clean SSH client state (you can mount your own keys later)
RUN mkdir -p /root/.ssh && touch /root/.ssh/known_hosts && chmod 700 /root/.ssh && chmod 600 /root/.ssh/known_hosts

# Lightweight init wrapper: ensures /run/mediapi exists, then launches supervisord
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9090 22

# Healthcheck for cockpit-ws
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fsSL http://127.0.0.1:9090/ || exit 1

ENTRYPOINT ["tini","-g","--","/usr/local/bin/entrypoint.sh"]
