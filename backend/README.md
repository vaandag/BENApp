# BEN API — V192

PHP + SQLite development backend for BENApp. V192 adds a production-oriented foundation while keeping the existing endpoint contract compatible with the current Flutter client.

## Local run

```bat
D:\php\php.exe -S 0.0.0.0:8080 -t D:\BENApp\mobileackend\public
```

Health:
```bat
curl http://127.0.0.1:8080/api/health
```

Expected service version: `192`.

## Environment
- `BEN_ALLOWED_ORIGIN` — production CORS origin; when unset, development remains `*`.
- `BEN_DEBUG=1` — returns the internal exception text for local debugging. Leave unset/0 outside local development.

## Production notes
PHP built-in server + SQLite are still for local development/testing. Before opening BEN to real traffic, use HTTPS, a production web server, managed database, object storage/CDN, backups, rate limiting, structured logs and an actual realtime transport for chat/live.
