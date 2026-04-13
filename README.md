# Aeoru ERPNext Deployment

Pinned ERPNext v16 deployment for use with the [Aeoru Assessment App](https://github.com/xthakila/task_accountability_management).

## What's Included

| Component | Version | Source |
|-----------|---------|--------|
| Frappe Framework | v16.9.0 | `frappe/` |
| ERPNext | v16.9.1 | `erpnext/` |
| HRMS | v16.4.8 | `hrms/` |
| Aeoru Custom App | v0.1.0 | Installed from [aeoru-erp](https://github.com/xthakila/aeoru-erp) |

All source is pinned at specific tags — no random upstream updates.

## Quick Start

```bash
# 1. Build the image
docker compose build

# 2. Start services
docker compose up -d

# 3. Run one-time setup
bash setup.sh

# 4. Access Frappe Desk
open http://localhost:8000
# Login: Administrator / admin
```

## Connect to Aeoru Assessment App

1. In Frappe Desk: **Settings > User > API Access** — generate API key + secret
2. In Aeoru app: go to `/admin/erpnext` and enter the ERPNext URL + credentials

## Upgrading

Check `VERSIONS` for current pinned versions. To upgrade:

```bash
# Example: upgrade ERPNext to v16.10.0
rm -rf erpnext
git clone --branch v16.10.0 --depth 1 https://github.com/frappe/erpnext.git erpnext
rm -rf erpnext/.git erpnext/.github

# Rebuild and migrate
docker compose build
docker compose up -d
docker exec erpnext-backend bench --site aeoru.local migrate
```

## Architecture

This repo is deployed **separately** from the Aeoru assessment app. The assessment app connects to this ERPNext instance via REST API.

```
Aeoru Assessment App          This Repo (ERPNext)
(Server 1)                    (Server 2 or same server, different port)
┌──────────────────┐          ┌──────────────────────────────┐
│ React + Go + PG  │──REST──▶│ ERPNext + HRMS + aeoru_hr    │
│ Port 80          │          │ MariaDB + Redis              │
└──────────────────┘          │ Port 8000                    │
                              └──────────────────────────────┘
```
