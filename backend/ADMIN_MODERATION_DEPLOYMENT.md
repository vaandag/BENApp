# BEN administration setup

The administration entry is visible only when the authenticated user ID is allowlisted on the PHP server. A Flutter-side flag cannot grant administrator access.

## Local Windows testing

1. Find the account ID in the local SQLite database at `backend/public/data/ben.sqlite`. Open the database with DB Browser for SQLite and run:

   ```sql
   SELECT id, username, email FROM users ORDER BY id;
   ```

2. Start `backend/start_ben_server.bat`. When prompted, enter the numeric ID of the account that should be an administrator. Multiple IDs can be comma-separated. Press Enter without a value to keep administration disabled.

3. Sign in with that account and open **Profil → Profil ayarları → Yönetim paneli**.

## Production hosting

Set `BEN_ADMIN_USER_IDS` in the PHP application/worker environment, for example:

```text
BEN_ADMIN_USER_IDS=12
```

Multiple positive numeric IDs may be separated by commas:

```text
BEN_ADMIN_USER_IDS=12,34
```

Restart PHP-FPM/Apache workers or redeploy the app after changing the variable. Do not put the value in Flutter code, a public config file, or a committed secret. Leave it unset to disable administrator access.

## Administration capabilities

- **Şikâyet yönetimi:** review open, resolved, and rejected reports; inspect bounded target previews and content-owner context.
- **User announcements:** send a titled in-app announcement to every account or search for and select one account. The screen shows a final recipient/message confirmation before sending.
- **Announcement history:** inspect the latest 50 sends, audience, selected recipient, administrator, send time, and recipient count.
- **Recipient search:** matches account usernames and returns a bounded result set.

## Server-side routes and safeguards

- `GET admin/status` reports whether the authenticated account is allowlisted.
- `GET admin/reports` and `POST admin/reports/{id}/resolve` enforce the allowlist.
- `GET admin/users?q=...`, `POST admin/notifications`, and `GET admin/notifications` enforce the same server-side allowlist independently.
- Announcement fan-out and its audit record are committed in one database transaction. A failed send does not leave partial notification rows or a false history entry.
- Announcement sending is rate-limited to 20 requests per administrator per hour. User search and history reads also have bounded rate limits.
- The server helper ignores invalid, zero and negative IDs and de-duplicates valid administrator IDs. Removing an ID revokes access after the server worker is restarted.

## Notification delivery scope

Announcements are currently stored as **in-app notifications** and appear in the BEN Notifications screen. The in-app unread badge is updated while the app is open. This does not yet send operating-system push notifications while the app is closed; that requires separate Firebase Cloud Messaging / Apple Push Notification service credentials and device-token registration.
