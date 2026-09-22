# BENApp V106 — Android LAN HTTP Fix

- Enabled Android cleartext HTTP for the development LAN API (`http://192.168.x.x:8080/api`).
- Kept existing V105 profile edit and demo removal changes.
- Version: 5.1.5+106.

Run on Redmi 8:
`flutter run --dart-define=BEN_API_URL=http://192.168.1.24:8080/api`
