# Multi-Provider DNS/CDN Strategy

Cloudflare’s outages have shown we need a fallback so halext.org, zeniea.com, and the other legacy sites stay reachable even when the primary CDN is down. This note compares options and proposes a phased rollout that keeps the origin locked down.

## Goals
- Keep Cloudflare’s WAF/DDoS protection most of the time, but fail over automatically (or quickly) to another provider.
- Preserve security controls: TLS certificates, HTTP/2/3, bot filtering, origin IP masking.
- Avoid manual DNS edits in the middle of an incident.

## Recommended Approach – Hybrid Multi-CDN
1. **Authoritative DNS split**
   - Move the apex domains (halext.org, zeniea.com, etc.) to a provider that supports DNS failover/health checks. Route53, NS1, or DNSMadeEasy are solid options.
   - Keep Cloudflare’s proxy records as the primary “pool,” but add a secondary pool that points to another CDN (e.g., Fastly, Bunny, or CloudFront) or to the origin directly.

2. **Secondary CDN / direct origin**
   - Mirror the static assets + TLS certs to the secondary provider. For halext.org you can serve the PHP/legacy content through their “origin pull” just like Cloudflare does; for the FastAPI/React app, reuse the existing TLS cert + Nginx.
   - Alternatively, expose a “direct” DNS target (e.g., `direct.halext.org`) that bypasses any CDN and only allow the secondary DNS pool to reference it during failover. Protect it with fail2ban/WAF rules so it’s not a soft target.

3. **Health checks + automation**
   - Use Route53/NS1 health checks that hit `/healthz` on `org.halext.org` and `halext.org`. When Cloudflare reports a 5xx or times out, the DNS provider automatically shifts to the backup pool.
   - Keep TTLs low (60–120 seconds) so failover is quick but not thrashy.

4. **Certificates & security**
   - Terminate TLS at each CDN separately (upload the Let’s Encrypt cert or use their managed certs). Keep ACME automation on the origin so you can reissue quickly.
   - Enforce mutual auth between CDN and origin with an allowlist of reverse-proxy IPs plus a shared header (e.g., `X-Edge-Key`). Reject traffic that lacks the header to prevent direct origin abuse.
   - Maintain WAF rules both on Cloudflare and the secondary CDN; if the backup is a “direct” origin, use Nginx’s `modsecurity`/Fail2ban.

5. **Operational playbook**
   - Document how to force traffic to the backup pool manually (CLI/API) for planned maintenance.
   - Add a cron/monitor that runs `scripts/site-health-check.sh --public` against both CDN endpoints and alerts if the HTTP codes diverge.

## Alternatives
- **Cloudflare for DNS only**: You could drop the proxy but keep their DNS. Lower effort but loses WAF/caching entirely.
- **Self-hosted reverse proxies**: Stand up HAProxy/Traefik nodes in two regions fronting the origin. Gives you full control but shifts DDoS responsibility to you.

## Next Steps
1. Pick the secondary DNS/CDN provider and provision credentials.
2. Script the DNS pools + health checks (Terraform or provider CLI).
3. Add origin header enforcement in `/etc/nginx/sites/*.conf` so only known proxies reach PHP/FastAPI.
4. Run drills: simulate Cloudflare outage by disabling the primary pool and verify clients fall back cleanly.

This setup keeps Cloudflare’s strengths but gives us a safety net when they have a bad day.
