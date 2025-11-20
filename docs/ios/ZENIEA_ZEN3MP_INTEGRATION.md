# Zeniea / Zen3MP Legacy Docs + Regionalization Guide

This note captures the current state of the halext.org webserver as it relates to the exported Zeniea/Zen3MP documentation, explains the new API surface that consolidates those docs behind the Halext Org backend, and outlines how to prepare the stack for regional moves or a fresh VM in another geography.

---

## 1. Inventory Of Legacy Doc Trees

| Site | Filesystem Path | Public URL Prefix | Approx. File Count | Highlights |
| --- | --- | --- | ---: | --- |
| `halext-docs` | `/www/halext.org/public/docs` | `https://halext.org/docs/` | ~45 | Course PDFs, homework sets, assorted study material referenced by halext.org. |
| `zeniea-docs` | `/www/zeniea.com/public/docs` | `https://zeniea.com/docs/` | 6 | Zen3MP recovery notes (`zen3mp-restoration.md`), resume exports, misc. reference PDFs. |
| `zen3mp-recovery` | `/www/zeniea.com/public/ZEN3MP_RECOVERY.md` | `https://zeniea.com/ZEN3MP_RECOVERY.md` | 1 | High-level Zen3MP restoration checklist that previously lived outside `/docs`. |

Observations:
- Zeniea and Zen3MP content is a subset of the Halext server but was only addressable via the legacy PHP apps. Indexing was manual and ad-hoc.
- Some Zen3MP notes (`ZEN3MP_RECOVERY.md`) lived outside the docs tree, so the new indexer explicitly tracks that file.
- All directories now respect env overrides so you can point the Halext API at a staging copy (see §3).

---

## 2. Consolidated API Surface

The backend now exposes a read-only "legacy doc" surface so modern Halext clients (React app, iOS prototype, OpenWebUI helpers) can pull Zeniea/Zen3MP material without scraping PHP pages.

**New endpoints** (all require an authenticated Halext user):

- `GET /legacy/doc-sites` → Lists every indexed doc root with path, region, file count, and health flags.
- `POST /legacy/doc-sites/refresh` → Forces a rescan (use sparingly; cache TTL defaults to 5 minutes).
- `GET /legacy/docs?site=zeniea-docs&tag=zen3mp&q=timeline` → Returns a filtered document list (filename, friendly title, checksum, tags, preview snippet, public URL) across the configured sites.

Under the hood `app/legacy_docs.py` walks the configured directories, computes SHA-256 checksums, and keeps a short-lived cache so repeated queries don't re-hash large PDFs. Tags are inferred from filenames/extensions so clients can quickly filter for `zen3mp`, `pdf`, or `resume` assets.

**Env vars for the indexer**

| Variable | Default | Purpose |
| --- | --- | --- |
| `HALX_HALEXT_DOCS_ROOT` | `/www/halext.org/public/docs` | Filesystem root for the halext.org docs tree. |
| `HALX_HALEXT_DOCS_URL` | `https://halext.org/docs` | Public URL prefix used when constructing download links. |
| `HALX_ZENIEA_DOCS_ROOT` | `/www/zeniea.com/public/docs` | Filesystem root for Zeniea/Zen3MP exports. |
| `HALX_ZENIEA_DOCS_URL` | `https://zeniea.com/docs` | URL prefix for Zeniea docs. |
| `HALX_ZEN3MP_RECOVERY_PATH` | `/www/zeniea.com/public/ZEN3MP_RECOVERY.md` | Extra file to include that sits outside `/docs`. |
| `HALX_ZEN3MP_RECOVERY_PUBLIC` | `ZEN3MP_RECOVERY.md` | Public-relative path for the extra file (used to build URLs). |
| `HALX_LEGACY_DOC_CACHE_SECONDS` | `300` | Cache window for the inventory (lower it on dev, raise it on prod if desired). |
| `HALX_PRIMARY_REGION` | `us-central` | Region label returned in the site metadata (handy when replicating the tree abroad). |

Because everything is routed through the FastAPI backend, Zeniea or Zen3MP restorations can now consume the same JSON payloads instead of hitting direct filesystem paths.

---

## 3. Security & Portability Improvements

- `scripts/server-deploy.sh` now honors `HALX_WWW_DIR`, `HALX_API_SERVICE`, `HALX_NGINX_SERVICE`, and `HALX_RSYNC_FLAGS`. This means moving the SPA to `/www/region-X/halext`, renaming the systemd unit, or using a nonstandard nginx service no longer requires editing the script. Export the env vars, run the deploy, and the right services get restarted.
- The deploy script also hardens `backend/.env` (auto-`chmod 600`) and warns if it is missing. This keeps the ACCESS_CODE/DB credentials scoped to the deploying user, which matters when staging a copy in a different region or on a multi-tenant host.
- The legacy doc index uses per-site env overrides so you can rsync a sanitized copy of the docs to another mount (`/srv/region-eu/docs`) and point Halext at it without editing code.
- Checksums plus MIME/TAG metadata give you a tamper-evident manifest—ideal for auditing before/after a move.

---

## 4. Regionalization / New-VM Runbook

Use this when bringing the stack up in another geographic region or cloning it onto a new VM:

1. **Mirror the repo + data**
   - `git clone` this repo to the new host.
   - Rsync the relevant `/www/halext.org/public/docs` and `/www/zeniea.com/public/docs` trees (or a sanitized subset) into local paths. Update env vars accordingly.
2. **Prime env + services**
   - Copy `infra/ubuntu/.env.example` to `backend/.env`, populate secrets, and let the new deploy script lock down permissions automatically.
   - Export overrides such as `HALX_WWW_DIR=/www/halext/region-eu`, `HALX_API_SERVICE=halext-api-eu`, `HALX_NGINX_SERVICE=nginx`, and custom `HALX_*_DOCS_ROOT` paths before running `./scripts/server-deploy.sh`.
3. **Deploy + verify**
   - Run `./scripts/server-deploy.sh` (or `./scripts/update-halext.sh` once the box is live) to rebuild Python/Node assets, restart the API, reload nginx, and rsync the SPA into your region-specific docroot.
   - Hit `GET /legacy/doc-sites` and ensure each path resolves from the new host. Use `POST /legacy/doc-sites/refresh` after copying docs to confirm the checksum inventory reflects the regional copies.
4. **Cut over**
   - Update DNS / Cloudflare for the subdomain once the stack passes smoke tests.
   - Optionally bump `HALX_PRIMARY_REGION` so clients know which cluster they are talking to.

Following these steps keeps the Halext API at the center of the stack, so Zeniea/Zen3MP, OpenWebUI workers, and the React/iOS clients all consume the same consolidated backend—regardless of which VM or region is serving traffic.
