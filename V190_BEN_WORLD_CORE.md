# BENApp V190 — BEN World Core

## Map foundation
- Restores the V186 Android OpenFreeMap planet source for 3D building extrusion and road layers.
- Keeps the V189 lazy MapLibre mounting that stabilized iOS.
- Resolves the initial camera before creating the native map: focused memory, current device location, first located memory, then Istanbul fallback.
- Prevents the map from initially opening at an arbitrary/sea coordinate when current location is available.
- Keeps `Konumuma gel` behavior.

## Scope
This release deliberately does not add new map features such as clustering yet. The goal is to restore and stabilize the BEN World foundation before visual upgrades.
