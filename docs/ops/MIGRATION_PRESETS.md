# Layout Presets Schema Migration

This migration adds user-owned custom presets to the Halext Org system.

## What Changed

- Added `is_system` column to distinguish system vs user presets
- Added `owner_id` column to track preset ownership
- Existing presets are marked as system presets

## How to Migrate on Ubuntu Server

### Prerequisites

1. Make sure your `.env` file has the correct `DATABASE_URL`:
   ```bash
   cat /srv/halext.org/halext-org/backend/.env | grep DATABASE_URL
   ```

2. Ensure PostgreSQL is running:
   ```bash
   sudo systemctl status postgresql
   ```

### Run Migration

```bash
cd /srv/halext.org/halext-org
sudo -u halext bash scripts/migrate-presets-schema.sh
```

The script will:
1. Check if the columns already exist
2. Add `is_system` and `owner_id` columns if needed
3. Add foreign key constraint
4. Mark existing presets as system presets

### Restart Service

After migration completes:

```bash
sudo systemctl restart halext-api.service
sudo systemctl status halext-api.service
```

### Verify

Check the logs to ensure the service started successfully:

```bash
sudo journalctl -u halext-api.service -n 50 --no-pager
```

You should see Uvicorn starting without errors.

## Troubleshooting

### Password Authentication Failed

If you see `password authentication failed for user "halext_user"`:

1. Check your `.env` file has the correct password:
   ```bash
   cat /srv/halext.org/halext-org/backend/.env
   ```

2. Test the database connection:
   ```bash
   sudo -u postgres psql -U halext_user -d halext_org -c "SELECT 1;"
   ```

3. Reset the password if needed:
   ```bash
   sudo -u postgres psql
   ALTER USER halext_user WITH PASSWORD 'your_new_password';
   \q
   ```
   Then update `DATABASE_URL` in `.env` with the new password.

### Columns Already Exist

If the migration says columns already exist, you're good! The migration is idempotent.

### Service Still Failing

Check for Python 3.8 compatibility issues in the logs. The codebase now uses `Optional[Type]` instead of `Type | None` for Python 3.8 support.
