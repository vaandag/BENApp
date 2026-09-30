# V194 Architecture Notes

## Primary map path
`MainScreen` -> `MapScreen` -> `flutter_map`

The native MapLibre screen is intentionally no longer instantiated from the primary Harita tab. The stable pure-Flutter map owns clustering and exploration state.

## Exploration
- `grid cell` changes with zoom.
- Cluster nodes expose only center/count; no radial fan.
- Individual memory selection marks an item as seen.
- Candidate ordering is deterministic from proximity, seen state, recency and social signal.
- History allows previous/next navigation without requiring another API request.

## Live transport
Publisher:
`LiveStudioScreen -> POST live -> peers poll -> create RTCPeerConnection -> SDP/ICE signal`

Viewer:
`LiveViewerScreen -> POST join -> signal poll -> setRemoteDescription -> answer -> remote RTCVideoView`

PHP signaling is intentionally transport-only. It does not inspect media bytes. STUN is used for connection discovery; production internet-scale deployment should add TURN and a media/SFU layer.
