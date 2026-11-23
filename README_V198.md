# BENApp V198 — iPhone Local API HTTP Policy

Base branch: `ui/ben-design-system-v1`

## Included

- Keeps the existing iOS local-network usage description and local-network ATS setting.
- Adds a narrowly scoped App Transport Security exception for the local development API host `192.168.1.24`.
- The exception allows HTTP only to that exact host; it does not globally disable ATS or allow arbitrary insecure hosts.
- App version and API health version are advanced to `1.0.0+198` / `198`.

## Why this is needed

- The V197 iOS IPA build log confirms `BEN_API_URL_INPUT` was `http://192.168.1.24:8080/api` and the build received it through `--dart-define`.
- The iOS app already had `NSLocalNetworkUsageDescription` and `NSAllowsLocalNetworking`, but Flutter's iOS HTTP network policy also supports host-specific exceptions through `NSExceptionDomains`.
- The exception is intentionally limited to the current development PC IP. If that IP changes, update the exception and rebuild the iOS app.
- This is a local development HTTP allowance, not a recommended production API setup. Use HTTPS for a deployed backend.

## iPhone test checklist

1. Install V198 on iPhone.
2. Open iPhone **Settings → Privacy & Security → Local Network** and make sure **BEN** is enabled (if listed).
3. Keep the PC PHP server running; confirm the server console says administrator user IDs are `1`.
4. Keep iPhone and PC on the same Wi-Fi network.
5. Open BEN and sign in. Confirm the PHP server console receives the login request.
