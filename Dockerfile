# ERPNext v16 — built from GitHub branches
#
# Includes: Frappe v16, ERPNext v16, HRMS v16
# Custom apps (aeoru_hr, aeoru_ai) installed at runtime via setup.sh
#
# Build:  docker compose build
# Start:  docker compose up -d
# Setup:  bash setup.sh

# ─── Stage 1: Build bench + install apps from GitHub ─────────────────────────
FROM frappe/bench:v5.29.1 AS builder

USER frappe

RUN bench init \
  --frappe-branch version-16 \
  --skip-redis-config-generation \
  /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

RUN bench get-app --branch version-16 erpnext
RUN bench get-app --branch version-16 hrms

RUN bench build --production

# ─── Stage 2: Production image ───────────────────────────────────────────────
FROM frappe/bench:v5.29.1 AS production

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
