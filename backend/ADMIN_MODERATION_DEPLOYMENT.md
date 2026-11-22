# BEN moderation admin setup

The moderation screen is intentionally hidden unless the authenticated user ID is allowlisted on the server. A Flutter-side flag cannot grant administrator access.

## Local Windows testing

1. Find the user ID in the local SQLite database at `backend/public/data/ben.sqlite`. Open the database with DB Browser for SQLite and run:

   ```sql
   SELECT id, username, email FROM users ORDER BY id;
   ```

2. Start `backend/start_ben_server.bat`. When prompted, enter the numeric ID of the account that should be an administrator. Multiple IDs can be comma-separated. Press Enter without a value to keep moderation disabled.

3. Restart the app session so the Trust & Safety screen checks the updated server setting.

4. In BEN, open **Profil → Ayarlar → Güvenlik ve gizlilik**. The **Şikâyet yönetimi** entry appears only for an allowlisted account.

## Production hosting

Set the environment variable `BEN_ADMIN_USER_IDS` on the PHP application/worker, for example:

```text
BEN_ADMIN_USER_IDS=12
```

Multiple positive numeric IDs may be separated by commas:

```text
BEN_ADMIN_USER_IDS=12,34
```

Restart PHP-FPM/Apache workers or redeploy the app after changing the variable. Do not put the value in Flutter code, a public config file, or a committed secret. Leave it unset to disable administrator access.

## Security behavior

- `GET admin/status` reports whether the authenticated user is allowlisted.
- `GET admin/reports` and `POST admin/reports/{id}/resolve` independently enforce the same server-side allowlist.
- The server helper ignores invalid, zero and negative IDs and de-duplicates valid IDs.
- Store only trusted administrator account IDs. Removing an ID from the environment variable revokes access after the server worker is restarted.
