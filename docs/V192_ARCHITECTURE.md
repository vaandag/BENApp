# BENApp V192 Architecture

## Flutter boundary

```text
UI / Screens
   ↓
Feature application logic
   ↓
Repositories / Services
   ↓
ApiClient / local storage
   ↓
BEN PHP API
```

`AppDependencies` is the composition root. Long-lived API/auth/repository instances are created once and passed into the application. New screens should depend on interfaces/repositories rather than constructing HTTP clients directly.

## Authentication rule

The client stores a short opaque bearer token locally. The server resolves the authenticated user from that token. Client-supplied `user_id` fields are accepted only for temporary backwards compatibility and are not trusted for critical writes.

## Data rule

The server is authoritative for synchronized memory metadata, ownership, likes/saves, comments, messages, notifications and account state. Local storage is a cache/offline hydration layer, not an authorization source.

## Backend boundary

`public/index.php` is the HTTP front controller. Cross-cutting HTTP/auth/schema behavior lives in `public/lib/`; schema changes are tracked in a migration table.

## Next production layers

The next structural steps after V192 are: route/controller separation, service/repository classes on PHP, cursor pagination, Redis/object storage/CDN, realtime transport, push notifications, rate limiting/moderation, structured logs/metrics and automated CI.
