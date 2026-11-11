# BENApp production hardening and deployment checklist

This branch keeps the existing five-item navigation and BEN visual system. The following server and platform settings are intentionally supplied by the deployment owner; credentials and private keys must not be committed to Git.

## Public API

Set the GitHub repository Actions secret:

- `BEN_API_URL`: the public HTTPS API root, for example `https://api.example.com/api`.
- `BEN_MAPTILER_KEY`: the MapTiler key used by the map build, when MapTiler is enabled.

The iOS IPA workflow is started manually after the CI analysis and tests pass. It stops before building when `BEN_API_URL` is missing or is not HTTPS. Release builds no longer fall back to a private LAN address.

For local Android development, the debug build uses the emulator URL `http://10.0.2.2:8080/api`; the iOS simulator uses `http://127.0.0.1:8080/api`. Set `BEN_API_URL` explicitly to your computer's LAN address when testing on a physical Android or iPhone device.

## PHP storage permissions

The PHP process must be able to write to:

- `backend/data/` for the SQLite database and its WAL/SHM files.
- `backend/storage/media/` for uploaded photo and video files.

Keep `backend/storage/` outside the public web root. The API now serves media from the authenticated `/api/media/{filename}` route and checks the associated memory's public/follower/private visibility before streaming the file. Video byte-range requests are supported.

The API migrates files from the legacy `backend/public/uploads/media/` directory when it next receives a request and rewrites the existing database URLs. Apache deployments also have a deny rule in `backend/public/uploads/media/.htaccess`. For Nginx or another web server, configure a matching deny rule for the legacy public upload path and move any remaining files to `backend/storage/media/` before exposing the new build.

Avatar images remain public profile assets; memory media does not.

## Live streaming relay (TURN)

The app fetches ICE server configuration from the authenticated `GET /api/live/ice-servers` endpoint. STUN fallback is always returned. A TURN relay is added only when both server environment variables are set:

- `BEN_TURN_URLS`: comma-separated TURN/TURNS URLs, including the transport options supported by your TURN provider, for example `turn:turn.example.com:3478?transport=udp,turns:turn.example.com:5349?transport=tcp`.
- `BEN_TURN_SHARED_SECRET`: the shared secret configured on the TURN service for REST-style, time-limited credentials.

The API creates a one-hour username/credential pair per authenticated user using HMAC-SHA1. Configure your TURN service (for example coturn) to use the same shared secret and REST authentication. Do not put the shared secret in Flutter code, a Dart define, or a public repository. Open the required UDP/TCP relay ports in your server firewall.

Without a TURN service, some mobile networks and symmetric NATs may still prevent direct peer-to-peer calls; the client will continue to try STUN but cannot guarantee connection.

## Android release signing

The Android release build no longer uses the debug signing key. Create a private upload keystore, copy `android/key.properties.example` to `android/key.properties`, then replace the placeholders with the keystore's values. Set `storeFile` to the path of your own keystore. Both `key.properties` and keystore files are ignored by Git.

Do not share the keystore or its passwords. Release build tasks intentionally stop until a complete signing configuration is present. Debug builds remain unaffected.

## Local verification

Run from the `mobile` project directory:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
```

The CI branch workflow runs analysis and tests on each push to `ui/ben-design-system-v1`. The iOS IPA workflow is manual and runs after the tests.

## Rate limits

The API stores only hashed rate-limit bucket keys and counters in SQLite. The current fixed windows are:

- Login: 80 attempts per IP per hour and 10 attempts per account/email per 15 minutes.
- Registration: 10 attempts per IP per hour and 3 attempts per email per day.
- Avatar uploads: 12 per user per hour; memory media uploads: 20 per user per hour.
- Comments: 80 per user per hour; messages: 120 per user per hour.

The PHP rate limiter uses `REMOTE_ADDR`. When running behind a reverse proxy or load balancer, configure the web server's trusted client-IP handling so PHP receives the real client address. Do not blindly trust arbitrary `X-Forwarded-For` headers.
