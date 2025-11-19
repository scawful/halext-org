# Server Monitoring & Troubleshooting

The legacy PHP properties (halext.org, zeniea.com, etc.) share the same Ubuntu host as the Halext Org API. This guide shows how to verify origin health even when Cloudflare or DNS is misbehaving, and how to pull the right logs when something returns a 5xx.

## 1. Run the bundled health check

```
cd /srv/halext/halext-org
./scripts/site-health-check.sh           # origin mode, bypasses Cloudflare
./scripts/site-health-check.sh --public  # optional: hit the public DNS entries
```

What it does:
- Probes each vhost via HTTP (Host header + `http://127.0.0.1`) so you know whether the origin is healthy during a Cloudflare incident.
- Checks representative endpoints (landing pages, PHP forms, docs downloads, Symfony API).
- Summarizes nginx/mysql/php-fpm service status.

Use `--timeout 3` (or `HALX_HEALTH_ORIGIN=http://10.0.0.5`) if you’re testing a remote replica.

## 2. Interpreting results

- `OK` vs `WARN` is a simple status mismatch against the expected HTTP code. If halext.org `/` shows `200` locally but visitors still see 5xx, the issue is at the edge (Cloudflare, DNS, TLS cert, etc.).
- A `WARN` from `/api/premia_core/...` usually means the Symfony install or PHP-FPM socket is unhealthy.
- A `WARN` on `freeforyallclt.com` is expected if you decide to sunset that site—adjust the `HOST_CHECKS` list if behavior changes.

## 3. Log collection (requires sudo or adm group)

| Component | Log Command | Notes |
| --- | --- | --- |
| nginx | `sudo tail -f /var/log/nginx/error.log` | Add your user to the `adm` group for read-only access. |
| PHP-FPM 7.2/7.4 | `sudo tail -f /var/log/php7.2-fpm.log` | Zeniea/halext PHP apps use these pools. |
| MySQL | `sudo journalctl -u mysql -n 100` | Confirms DB availability when PHP errors mention credentials. |
| System services | `sudo systemctl status php7.2-fpm` | Combine with the health script to catch restarts/crashes. |

If you can’t read `/var/log/nginx/error.log`, either run the commands with sudo or add the `halext` account to `adm`:

```
sudo usermod -aG adm halext
newgrp adm
```

(requires logout/login to persist.)

## 4. Handling Cloudflare outages

- Use `./scripts/site-health-check.sh` (default mode) to prove the origin is serving 200s.
- If the origin is healthy but the public site isn’t, temporarily switch DNS to “DNS only” or disable the proxy in Cloudflare until the incident clears.
- When testing TLS locally, `curl -k -H "Host: halext.org" https://127.0.0.1/` confirms nginx cert paths without depending on Cloudflare’s edge certs.

## 5. Related tools

- `scripts/ubuntu-diagnose-performance.sh` — higher-level CPU/memory/disk check plus Docker/Ollama status.
- `docs/ZENIEA_ZEN3MP_INTEGRATION.md` — inventory of doc trees and API endpoints driving Zeniea/Zen3MP content.

Keeping these scripts handy reduces the time-to-diagnose and avoids misattributing Cloudflare/Middlebox issues to the origin stack.

## 6. User/permission hygiene

Run `scripts/promote-halext-user.sh` (with sudo) to migrate ownership from the legacy `justin` account, add `halext` to `adm`/`www-data`, and lock the deprecated user. The script reuses `sync-halext-perms.sh` so Git stops warning about “dubious ownership” after the switchover. Confirm you have backups before removing the old account entirely.
