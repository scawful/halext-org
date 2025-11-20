# Backend Access Restoration Runbook

Use this checklist when the Halext backend rejects all logins or the “session expired/invalid credentials” errors appear even after recreating users.

## 1. Confirm the service is running
```bash
sudo systemctl status halext-api --no-pager
sudo journalctl -u halext-api -n 80 -l
```
If the service fails to start, the logs will usually show `ModuleNotFoundError`. Install/update dependencies inside the backend virtualenv:
```bash
cd /srv/halext.org/halext-org/backend
source env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate
sudo systemctl restart halext-api
```

## 2. Validate configuration
- `sudo systemctl cat halext-api` should point `WorkingDirectory` and `EnvironmentFile` to `/srv/halext.org/halext-org/backend`.
- `backend/.env` must contain `DEV_MODE=false`, `DATABASE_URL=postgresql://halext_user:<password>@127.0.0.1/halext_org`, and the current `ACCESS_CODE`.
- After editing `.env`, run `sudo systemctl restart halext-api`.

## 3. Check the database
```bash
sudo -u postgres psql -d halext_org -c \
  "select id, username, email, is_admin from users order by id desc;"
```
If the expected user is missing, recreate it:
```bash
cd /srv/halext.org/halext-org/backend
source env/bin/activate
python create_dev_user.py --username NAME --password PASS --email you@example.com
deactivate
sudo systemctl restart halext-api
```
(`create_dev_user.py` now auto-loads `backend/.env`, so it always talks to Postgres.)

## 4. Test login directly
```bash
curl -s -X POST http://127.0.0.1/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=NAME&password=PASS&grant_type=password"
```
- Successful response includes `{"access_token": "...", "token_type": "bearer"}`.
- `{"detail":"Incorrect username or password"}` means the database still lacks the user or the password differs.

Keep `sudo journalctl -u halext-api -f` open while reproducing the login flow from the SPA/iOS app. The log entries clarify whether the backend rejects credentials, is missing the `X-Halext-Code` header, or can’t reach the database.

## 5. Final verification
```bash
curl -H "Host: org.halext.org" http://127.0.0.1/api/health
```
When the service returns `200 OK` and `/token` works via curl, the web and mobile clients should accept the same credentials (ensure they send the fresh `ACCESS_CODE` header).

## Optional: scripted recovery
`scripts/restore-backend-access.sh` can rotate the invite code, force `DEV_MODE=false`, seed a user, restart the service, and hit `/api/health` automatically. Run it from `/srv/halext.org/halext-org` and follow the prompts:
```bash
./scripts/restore-backend-access.sh --access-code NEWCODE \
  --username NAME --password PASS --email you@example.com
```
