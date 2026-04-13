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
until docker exec erpnext-db healthcheck.sh --connect --innodb_initialized 2>/dev/null; do
    sleep 2
done
echo "MariaDB is ready."

# Create site
echo "Creating site $SITE_NAME..."
docker exec erpnext-backend bench new-site "$SITE_NAME" \
    --mariadb-root-password="$DB_ROOT_PASSWORD" \
    --admin-password="$ADMIN_PASSWORD" \
    --no-mariadb-socket

# Install apps
echo "Installing ERPNext..."
docker exec erpnext-backend bench --site "$SITE_NAME" install-app erpnext

echo "Installing HRMS..."
docker exec erpnext-backend bench --site "$SITE_NAME" install-app hrms

# Install Aeoru custom app
echo "Installing aeoru_hr custom app..."
docker exec erpnext-backend bench get-app https://github.com/xthakila/aeoru-erp.git
docker exec erpnext-backend bench --site "$SITE_NAME" install-app aeoru_hr

# Disable telemetry
docker exec erpnext-backend bench --site "$SITE_NAME" set-config disable_telemetry 1

# Set as default site
docker exec erpnext-backend bench use "$SITE_NAME"

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
