# Local Spots implementation and field setup

Open LabTrack > Home > Features > Bayugan Local Spots.

The prototype includes an interactive map, verified markers and meter-based circles, location details, current position, recenter, foreground tracking controls, entry/exit snackbars, persistent event history, clear-history confirmation, settings shortcuts, and tracking help.

## Supply field data

Edit `assets/locations.json`. The five initial records are unverified labels with null coordinates. They are intentionally excluded from the map and tracking. The initial map viewport is only an approximate city overview, not a proposed place.

For each record, personally verify eligibility and permission, supply decimal-degree `latitude` and `longitude`, update `name`, `description`, and `barangay`, and set `verified` to true. Keep all five in the same barangay. Record collection date, reported accuracy, and listing-check evidence privately with your inventory. Do not publish private coordinates in a public repository. Restart the app after editing the asset.

Tracking is available once a verified record exists so individual fences can be tested during setup. Final submission still requires at least five verified locations.

## Detection settings

- Initial radius: 50 meters per record.
- Reading freshness: no more than 15 seconds; duplicate or out-of-order timestamps are ignored.
- Accuracy limit: the smaller of 25 meters and half the radius.
- Boundary uncertainty: postpone transitions if reported accuracy overlaps the radius.
- Confirmation: three consecutive reliable readings in the changed state.
- Initial reading: establishes state silently, with no invented entry/exit.
- Stop, leaving this screen, or leaving the foreground: cancels monitoring and resets states. Resume manually; missed background movement is not reconstructed.
- History uses UTC timestamps internally and local time in the interface. No continuous route is saved.

These are initial settings requiring outdoor tuning, not guarantees of GPS accuracy.

## Map service

The prototype uses flutter_map with the OpenStreetMap standard tile endpoint, visible attribution, an application user agent, and flutter_map's default caching. No map API key is required. Ordinary interactive viewing is intended; no bulk downloads or offline-map feature is provided. Review the [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/) before distribution. Tiles need connectivity; location monitoring is independent of tile loading.

## Validation and remaining work

Run `flutter analyze` and `flutter test`. Geofence tests use synthetic coordinates only; these are not field locations.

Complete plan.md's real Android device checklist before submission: verify markers, start inside/outside, enter and exit every fence, stay near boundaries, deny/revoke permission, disable GPS, lose connectivity, pause/resume, stop tracking, restart to verify saved history, and clear history. Capture expected/actual results, device details, accuracy, and evidence privately. Background tracking and system notifications are outside this prototype.

| Location | Entry result | Exit result | Accuracy | Device / date | Notes |
| --- | --- | --- | --- | --- | --- |
| LOC01 | Pending | Pending | | | |
| LOC02 | Pending | Pending | | | |
| LOC03 | Pending | Pending | | | |
| LOC04 | Pending | Pending | | | |
| LOC05 | Pending | Pending | | | |
