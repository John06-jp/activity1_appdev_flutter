# Bayugan Local Spots: Custom Map with Geofencing Tracker

## 1. Project overview

Develop an Android application that displays at least five custom locations within one barangay in Bayugan City, Agusan del Sur. The app will show the user's current position and issue entry and exit alerts for circular geofences around these locations.

The locations must have no existing Google Maps place listing or custom place marker. They may still be visible in satellite imagery. Their eligibility and coordinates must be verified personally before implementation.

## 2. Area and local background

Bayugan City belongs to Agusan del Sur in Caraga (Region XIII). It has 43 barangays and a population of 110,313 in the 2024 Census of Population. Poblacion and Taglatawan are identified by the city government as commercial centers.

**Working area:** One accessible neighborhood in Barangay Poblacion, Bayugan City. This is a provisional choice; replace it with the barangay where the student can personally identify and visit five eligible locations. Keep all five locations in the selected barangay.

## 3. Objectives

- Display at least five verified custom markers within the selected area.
- Show a name, description, and geofence boundary for each location.
- Display the user's current position while tracking is enabled.
- Detect entry into and exit from each geofence.
- Record entry and exit events with timestamps.
- Demonstrate the tracker through actual outdoor testing.

## 4. Proposed marker inventory

These are planning placeholders, not confirmed Bayugan locations. Do not invent coordinates or present these names as verified places.

| ID | Proposed label | Location to identify | Latitude | Longitude | Initial radius |
| --- | --- | --- | --- | --- | --- |
| LOC01 | My Home | Student's home, with household permission | To collect | To collect | 50 m |
| LOC02 | Friend's Home | Friend's home, with permission | To collect | To collect | 50 m |
| LOC03 | Family Garden | Garden or small farm without a place listing | To collect | To collect | 50 m |
| LOC04 | Neighborhood Rest Spot | Safe, unnamed local gathering or resting place | To collect | To collect | 50 m |
| LOC05 | Local Scenic Spot | Safe, accessible, unnamed viewpoint or open space | To collect | To collect | 50 m |

Prefer locations more than 100 meters apart for the initial 50-meter circles. Overlapping geofences are allowed, but alerts must identify the correct location. Adjust radii using field results; 50 meters is a starting setting, not a guarantee of detection accuracy.

## 5. Field data collection

1. Confirm the selected barangay and visit five candidate places.
2. Search each candidate on Google Maps, inspect the surrounding map, and document the absence of a place listing at the time of checking.
3. Obtain permission before including private property.
4. Capture the latitude and longitude at the intended geofence center using a GPS-enabled phone. Wait for a stable outdoor reading and record the reported accuracy.
5. Record a short description, collection date, and optional photo for each location.
6. Replace unsuitable or already-listed locations, then finalize the inventory.

## 6. Scope and features

### Required version

- Map centered on the selected neighborhood.
- Five distinct custom markers and visible geofence circles.
- Marker details when tapped.
- Current-location indicator and recenter button.
- Start and stop tracking controls.
- Inside/outside status and distance for each location.
- In-app entry and exit alerts.
- Local event history and a clear-history control.
- Helpful messages for denied permission, disabled GPS, unavailable map tiles, or stale location readings.

Tracking operates while the app is open. Background tracking and operating-system notifications are optional additions if the instructor requires them. Accounts, cloud databases, route navigation, and tracking other people are outside the initial scope.

## 7. Proposed implementation

| Component | Proposed choice | Purpose |
| --- | --- | --- |
| Platform | Flutter and Dart, Android first | Build the app |
| Map | Flutter-compatible map component and a suitable map provider | Display map, markers, and circles |
| Positioning | Flutter-compatible device-location package | Read location, accuracy, and timestamps |
| Location data | Local JSON asset | Store the five approved locations |
| Event storage | Local persistent storage | Retain entry and exit history |
| Test device | Android smartphone with location services | Verify real movement |

Confirm package compatibility, provider terms, attribution, credentials, and any usage charges before coding. No backend is required for the basic activity.

### Location record

Each record contains: `id`, `name`, `description`, `barangay`, `latitude`, `longitude`, and `radiusMeters`. Keep coordinates as decimal degrees and radii as meters.

### Event record

Each event contains: `locationId`, `locationName`, `eventType` (`entry` or `exit`), and `timestamp`. Store event history locally and avoid retaining a continuous route by default.

## 8. Geofencing behavior

1. Request location permission when the user starts tracking.
2. Check whether device location services are enabled.
3. Receive a fresh position and calculate its distance from each marker using a geographic distance function.
4. On the first reliable reading, establish the current inside/outside state without claiming an entry or exit occurred.
5. For each subsequent reading, compare the distance with the configured radius and previous state.
6. Trigger one entry event when a confirmed state changes from outside to inside, or one exit event when it changes from inside to outside.
7. Show the location name and event time, then save the event.
8. Stop location updates when tracking is stopped.

To reduce repeated alerts near a boundary, require multiple consecutive reliable readings before confirming a transition. Show the reported GPS accuracy and postpone transitions when readings are stale or too inaccurate for the configured radius. Tune these settings during field testing and document the final values.

## 9. Screens

| Screen | Main content |
| --- | --- |
| Map | Five markers, circles, current location, tracking control, recenter button |
| Locations | Five places, distance, and inside/outside status |
| Location details | Name, description, radius, and map focus action |
| Event history | Entries and exits with date and time |
| Help | Permission guidance, tracking scope, and GPS limitations |

## 10. Development schedule

| Day | Work | Deliverable |
| --- | --- | --- |
| 1 | Confirm barangay, inspect locations, collect coordinates and permissions | Verified five-location inventory |
| 2 | Set up project, map, markers, and detail views | Working custom map |
| 3 | Add current location, tracking controls, and geofence calculations | Working foreground tracker |
| 4 | Add alerts, persistent event history, and error handling | Complete activity prototype |
| 5 | Conduct field tests, fix issues, capture evidence, and prepare submission | Tested app and documentation |

## 11. Test and acceptance checklist

| Test | Expected result |
| --- | --- |
| Open the map | All five verified locations appear in the selected barangay |
| Tap each marker | Correct name and description appear |
| Start tracking outside all circles | Current position and initial statuses appear without false transition alerts |
| Start tracking inside a circle | Inside status appears without a fabricated entry event |
| Enter each geofence | One entry alert and one matching history record appear |
| Remain inside | No repeated entry alerts occur |
| Exit each geofence | One exit alert and one matching history record appear |
| Move near a boundary | Confirmation logic reduces rapid repeated alerts |
| Deny permission or disable GPS | Clear recovery guidance appears without crashing |
| Receive poor or stale GPS readings | Uncertainty is shown and transitions are postponed |
| Stop tracking | Position monitoring and new transition alerts stop |
| Restart the app | Saved event history remains available |
| Lose map connectivity | A clear map-loading message appears; GPS status remains understandable |

Complete at least one successful entry and exit test for every location. Record expected and actual results, device details, GPS accuracy, and any limitations. Emulator coordinates may help debugging, but final evidence should include real-device field tests.

## 12. Privacy and practical limits

- Use only locations that can be visited safely and legally.
- Obtain permission for houses and other private property.
- Use neutral labels and omit exact home coordinates from publicly shared screenshots or reports.
- Explain that location readings may drift and alerts may be delayed.
- Keep the activity focused on tracking the consenting device user's position.

## 13. Final deliverables

- Android app or APK, according to the instructor's submission instructions.
- Source code and this project plan.
- Completed inventory of five eligible locations with privately submitted coordinates.
- Screenshots showing markers, circles, and location details.
- Screenshots or a demonstration video showing entry and exit alerts.
- Test-results table covering all five locations.
- Brief explanation of how geofencing works and its observed limitations.

## 14. Background sources

- [Bayugan City Government — City profile](https://bayugancity.gov.ph/the-city/)
- [Philippine Statistics Authority — City of Bayugan and barangays](https://psa.gov.ph/classification/psgc/barangays/1600301000)
- [Agusan del Sur Provincial Government — Bayugan City](https://agusandelsur.gov.ph/municipalities/bayugan-city/)

These sources support the city background. They do not verify the five proposed custom locations or their absence from Google Maps.

## 15. Implementation progress (October 26, 2026)

The tracker is integrated into LabTrack under Home > Features > Bayugan Local Spots. The initial prototype implements the map, verified-location filtering, details, foreground GPS, geofence confirmation, in-app alerts, and persistent local history. See [LOCAL_SPOTS.md](LOCAL_SPOTS.md) for setup and detection settings.

Field collection remains pending. The five asset records contain null coordinates and `verified: false`; no invented place coordinates are used. Personal verification, final inventory, real-device testing, and submission evidence remain required.
