# ERPNext v16 — built from pinned local source
#
# Includes: Frappe v16.9.0, ERPNext v16.9.1, HRMS v16.4.8
# Custom app (aeoru_hr) is installed at runtime via bench get-app
#
# Build:  docker compose build
# Start:  docker compose up -d

# ─── Stage 1: Build bench + install apps from local source ───────────────────
FROM frappe/bench:latest AS builder

USER frappe

COPY --chown=frappe:frappe frappe /tmp/frappe-src
RUN bench init \
  --frappe-path /tmp/frappe-src \
  --skip-redis-config-generation \
  /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

COPY --chown=frappe:frappe erpnext /tmp/erpnext-src
RUN bench get-app file:///tmp/erpnext-src

COPY --chown=frappe:frappe hrms /tmp/hrms-src
RUN bench get-app file:///tmp/hrms-src

RUN bench build --production
RUN rm -rf /tmp/frappe-src /tmp/erpnext-src /tmp/hrms-src

# ─── Stage 2: Production image ───────────────────────────────────────────────
FROM frappe/bench:latest AS production

USER root

# Install Claude Code CLI and ttyd web terminal
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm \
    && npm install -g @anthropic-ai/claude-code \
    && curl -sL https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER frappe

COPY --from=builder --chown=frappe:frappe \
  /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 7681
CMD ["bench", "serve", "--port", "8000"]
