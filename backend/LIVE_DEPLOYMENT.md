# BEN live deployment notes

## Current transport model

BEN live currently uses WebRTC peer-to-peer fan-out: each viewer has a direct peer connection to the host. The PHP API exchanges offers, answers, and ICE candidates; it is not a media server and does not mix or relay video itself.

This is suitable for controlled tests and small audiences, but host upload and CPU/network load increase with each viewer. Do not treat this topology as a globally scalable broadcast service. For larger audiences, plan an SFU media layer (self-hosted or managed) and keep the PHP API responsible for account, room, and authorization state.

## TURN configuration

STUN alone cannot establish every network path. Configure a TURN service for production and set these server-side environment variables:

- `BEN_TURN_URLS`: comma-separated `turn:` / `turns:` URLs.
- `BEN_TURN_SHARED_SECRET`: the Coturn REST shared secret.

The secret must remain on the PHP server. The API creates short-lived per-user credentials; never add the shared secret to Flutter `--dart-define`, source control, or app configuration.

Without TURN, some mobile carrier, corporate, and restrictive NAT paths will fail.

## Session lifecycle

The host sends heartbeats every 12 seconds. The API now ends live rooms after 45 seconds without a fresh host heartbeat, removes expired peers after 90 seconds, and clears orphaned signaling records during live discovery, joins, and viewer polling. This is a recovery mechanism, not a substitute for an SFU or push delivery.

## Production checks

1. Set and rotate TURN credentials in the server environment.
2. Confirm HTTPS and valid TLS for the API and TURN/TLS endpoint.
3. Test host/viewer on separate mobile networks, not only the same Wi-Fi.
4. Test host app termination, network loss, viewer leave, and host stop.
5. Load-test audience limits before public promotion; P2P host fan-out is not designed for very large audiences.
