# BEN API — Windows local development server

The local PHP + SQLite server is a development environment for BENApp.

Start with `backend/start_ben_server.bat`, then verify:

```bat
curl http://127.0.0.1:8080/api/health
```

The Flutter app should point `BEN_API_URL` to `http://<PC-IP>:8080/api` on the same Wi-Fi network.

V192 adds server-side session authorization for critical write operations, SQLite WAL/busy-timeout settings, migrations and request IDs. It is still not a public production server.
