# BENApp V199 — Live Connection Reliability

Base branch: `ui/ben-design-system-v1`

## Included

- Live discovery no longer disguises an API/network failure as an empty live list. It shows the connection error and an explicit retry action.
- The viewer now listens to WebRTC connection and ICE state changes and displays the real connection stage.
- If the media stream does not arrive within 25 seconds, the viewer shows a useful explanation and a retry control.
- Viewer retry leaves the previous peer, disposes its peer connection, clears queued ICE candidates and joins with a fresh peer ID.
- A failed viewer setup now removes its just-registered peer from the server so abandoned peer rows do not wait for the stale-peer cleanup window.
- The host tracks connected viewers separately from registered viewers and displays both counts.
- Host-side peer setup failures and failed WebRTC connections are cleaned up and retried with a short backoff. This prevents one half-created peer connection from permanently blocking future setup attempts.
- The host now checks whether an offer was accepted by the signaling API instead of silently treating a failed offer POST as success.
- App version and API health version are advanced to `1.0.0+199` / `199`.

## Known deployment dependency

- Live uses peer-to-peer WebRTC fan-out. It is currently intended for small controlled tests, not internet-scale broadcasts.
- Without configured TURN credentials (`BEN_TURN_URLS` and `BEN_TURN_SHARED_SECRET`), some mobile carrier and restrictive NAT paths will not establish a media connection. The app now makes this condition and the connection stage clearer, but does not fabricate a TURN service.
- Production scale requires a TURN service and, for larger audiences, an SFU media layer.

## Validation

- GitHub Actions runs PHP syntax and backend tests, Flutter analyze and Flutter tests.
- A two-device real-world check is still required: one device starts a live stream, the other joins; then test viewer retry, host ending the stream, and both devices switching Wi-Fi/mobile networks.
