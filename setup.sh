#!/bin/bash
# ERPNext one-time setup — run after `docker compose up -d`
#
# Usage: bash setup.sh
#
# This creates the site, installs apps, and sets up the admin user.

set -e

SITE_NAME="${SITE_NAME:-aeoru.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
DB_ROOT_PASSWORD="${ERPNEXT_DB_ROOT_PASSWORD:-erpnext_root_pass}"

echo "=== ERPNext Initial Setup ==="
echo "Site: $SITE_NAME"
echo ""

# Wait for MariaDB
echo "Waiting for MariaDB..."
until docker compose exec erpnext-db healthcheck.sh --connect --innodb_initialized 2>/dev/null; do
    sleep 2
done
echo "MariaDB is ready."

# Configure DB host before creating site
echo "Configuring database connection..."
docker compose exec erpnext-backend bench set-config -g db_host erpnext-db
docker compose exec erpnext-backend bench set-config -g redis_cache redis://redis-cache:6379
docker compose exec erpnext-backend bench set-config -g redis_queue redis://redis-queue:6379

# Create site
echo "Creating site $SITE_NAME..."
docker compose exec erpnext-backend bench new-site "$SITE_NAME" \
    --mariadb-root-password="$DB_ROOT_PASSWORD" \
    --admin-password="$ADMIN_PASSWORD" \
    --mariadb-user-host-login-scope='%' \
    --force

# Install apps
echo "Installing ERPNext..."
docker compose exec erpnext-backend bench --site "$SITE_NAME" install-app erpnext

echo "Installing HRMS..."
docker compose exec erpnext-backend bench --site "$SITE_NAME" install-app hrms

# Install Aeoru custom apps (skip-assets for apps without frontend assets)
echo "Installing aeoru_hr custom app..."
docker compose exec erpnext-backend bench get-app --skip-assets https://github.com/xthakila/aeoru-erp.git
docker compose exec erpnext-backend bench --site "$SITE_NAME" install-app aeoru_hr

# Install Aeoru AI assistant
echo "Installing aeoru_ai app..."
docker compose exec erpnext-backend bench get-app https://github.com/xthakila/erpnext-aeoru-erp-assistant.git
docker compose exec erpnext-backend pip install -r apps/aeoru_ai/requirements.txt
docker compose exec erpnext-backend bench --site "$SITE_NAME" install-app aeoru_ai
docker compose exec erpnext-backend bench build --app aeoru_ai

# Fix .claude directory permissions for Claude Code auth
docker compose exec erpnext-backend sudo chown -R frappe:frappe /home/frappe/.claude 2>/dev/null || true

# Start ttyd web terminal
docker compose exec -d erpnext-backend ttyd --port 7681 --writable bash

# Disable telemetry
docker compose exec erpnext-backend bench --site "$SITE_NAME" set-config disable_telemetry 1

# Set as default site
docker compose exec erpnext-backend bench use "$SITE_NAME"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Admin login: Administrator / $ADMIN_PASSWORD"
echo "Access Frappe Desk at: http://localhost:${ERPNEXT_PORT:-8000}"
echo ""
echo "Next steps:"
echo "  1. Log into Frappe Desk"
echo "  2. Run Setup Wizard (Company, Chart of Accounts, etc.)"
echo "  3. Go to Settings > User > API Access — generate API key + secret"
echo "  4. In the Aeoru assessment app, go to /admin/erpnext and enter:"
echo "     - URL: http://<this-server-ip>:${ERPNEXT_PORT:-8000}"
echo "     - API Key + Secret from step 3"
