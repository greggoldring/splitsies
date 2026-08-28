# Splitsies: Track Cycling Splits

A SwiftUI stopwatch for track cycling. Time a race, tap out lap splits, and have each split
stamped with the air pressure at the moment it was recorded — so you can compare a ride at
sea level against the same effort in thin air at altitude.

iPhone and iPad, iOS 17.0+. No account, no sign-in. Race history lives in on-device SwiftData.

## What it does

- **Stopwatch with laps.** Start / split / stop, with the display driven by a `@Observable`
  view model. The idle timer is disabled while a race is running so the screen stays awake.
- **Pressure stamped per split.** Every lap records station pressure in hPa alongside the
  time. On a device with a barometer this comes straight off `CMAltimeter`; the reading is
  cached continuously and stamped at the instant of the split, so capturing never blocks.
- **Weather backfill for splits with no barometer reading.** iPads and older devices have no
  barometer. For those splits, Splitsies can look up hourly pressure for the venue from
  Open-Meteo and fill it in after the fact, using coordinates coarsened to ~11 km. Optional and
  switchable off — see [Privacy and network use](#privacy-and-network-use).
- **Venue catalog.** 128 bundled velodromes (`Splitsies/Resources/velodromes.json`) with
  coordinates and elevation, searchable and grouped by country. You can add custom venues
  by hand. Demolished venues stay in the dataset so historical splits keep resolving.
- **Derived atmospherics.** Sea-level-reduced pressure and moist-air density are computed
  from the captured values (`Models/PressureMath.swift`). Raw captured readings remain the
  source of truth; nothing derived is written back.
- **History and CSV export.** Browse past races, rename them, and share a CSV of races,
  laps, and split times.
- **Pressure unit preference.** hPa, inHg, or mmHg for display. Storage is always hPa.

## Requirements

| | |
|---|---|
| Xcode | 16 or newer (project `objectVersion = 77`; developed against Xcode 26.6) |
| iOS deployment target | 17.0 |
| Devices | iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| Swift language mode | 5 |
| Dependencies | None — no SPM, CocoaPods, or Carthage. Apple frameworks only. |

Frameworks used: SwiftUI, SwiftData, CoreMotion (barometer), UIKit (share sheet, idle timer).

**Signing.** Automatic, team `69KF2FSA88`, bundle ID `com.greggoldring.Splitsies`. Simulator
builds need no signing at all. To run on a physical device you need your own signing identity:
open the **Splitsies** target → **Signing & Capabilities**, and set Team to your own (and the
bundle ID to something unique to you if you are not on that team).

## Build and run

```bash
open Splitsies.xcodeproj
```

Select the **Splitsies** scheme and press ⌘R. There is no generated project step and nothing
to install first.

From the command line:

```bash
xcodebuild build -project Splitsies.xcodeproj -scheme Splitsies -destination 'platform=iOS Simulator,name=iPhone 17'
```

Any available simulator works — list them with `xcrun simctl list devices available`.

Note that the barometer does not exist on the Simulator, so simulator splits record no
pressure from the sensor. To exercise the barometer path you need a physical iPhone; to
exercise the backfill path, a device or simulator with no barometer reading and a venue
selected.

## Tests

Unit tests use **Swift Testing** (`import Testing`); the UI tests are XCUITest.

```bash
xcodebuild test -project Splitsies.xcodeproj -scheme Splitsies -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SplitsiesTests
```

Or ⌘U in Xcode, which runs the UI tests as well.

- `SplitsiesTests` — 26 tests (33 cases; one is parameterized over eight coordinate inputs)
  covering the pressure math, the velodrome catalog, the barometer stamp-at-split flow, the
  backfill grouping/never-overwrite rules, and the coordinate coarsening described below.
  These are hermetic: the backfill tests inject a `MockWeatherProvider` and the provider tests
  assert on built URLs, so **no test hits the network**.
- `SplitsiesUITests` — launch and smoke tests.

## Project layout

Sources sit in top-level folders next to the `.xcodeproj` rather than all inside the
`Splitsies/` app folder:

```
Splitsies/          App entry point, ContentView (TabView), assets, fonts, velodromes.json
Models/             SwiftData models (Race, Split, CustomVenue), value types, PressureMath
Services/           Barometer, Open-Meteo client, backfill, venue catalog, formatting
ViewModels/         StopwatchViewModel — timing, split capture, save
Views/              Stopwatch, History, RaceDetail, Settings, Credits, venue picker/form
SplitsiesTests/     Swift Testing unit tests
SplitsiesUITests/   XCUITest
docs/               Privacy policy, served via GitHub Pages
```

Points worth knowing before changing things:

- **`Splitsies/Item.swift`** is the leftover Xcode template model. It is still in the
  SwiftData schema but is otherwise unused.
- **`SplitsiesApp.swift`** deletes and recreates the store if `ModelContainer` creation
  fails, as lightweight recovery for a store that predates the pressure/venue fields. Adding
  a non-optional model property without a migration will wipe users' history.
- **`Race`** keeps denormalized copies of venue name/city/country/coordinates so history
  still renders after a custom venue is deleted.
- **`Split.stationPressureHPa`** is write-once. Backfill skips any split whose
  `pressureSource` is not `.none`, so barometer data is never overwritten.
- Backfill failures are **silent by design** — a failed lookup leaves the split pending and
  it is retried on a later pass.

## Privacy and network use

The one and only network call in the app is the optional Open-Meteo weather lookup
(`Services/OpenMeteoWeatherProvider.swift`). Everything else — timing, history, barometer
readings, the venue catalog — is entirely local. The app does not link CoreLocation and never
reads the device's GPS location; the coordinates it sends belong to the *venue* you picked.

The lookup is controlled by **Settings → Privacy & Offline → Weather API lookups**, which is
**on by default**. With it off, no network request is made at all.

Coordinates are coarsened to **one decimal place** (~11 km, less at high latitudes) by
`OpenMeteoWeatherProvider.coarsenedCoordinate` before the request is built. That is the single
point where coordinates leave the device, so the bound holds for custom venues too — their
lat/lon are typed by hand and are not rounded anywhere else.

The archive endpoint also carries the session's UTC date (`start_date`/`end_date`). The hour is
not transmitted; it is used locally to pick from the returned hourly array.

> The privacy policy in [`docs/index.html`](docs/index.html) describes this lookup, and the
> one-decimal-place bound is stated there. **If you widen that precision, update the policy in
> the same change** — `OpenMeteoWeatherProviderTests` will fail if the bound changes, which is
> deliberate.

## Releasing

See **[DEPLOY.md](DEPLOY.md)** for the full manual App Store process: versioning rules,
preflight checklist, archive and upload, TestFlight, and the App Privacy answers. Releases are
built and uploaded from Xcode by hand — there is no Fastlane, Xcode Cloud, or CI pipeline.

## Credits

Space Mono by Colophon Foundry, licensed under the SIL Open Font License 1.1
(`Splitsies/Fonts/SpaceMono/OFL.txt`). Attributed in the app's Credits tab.

Weather data by [Open-Meteo](https://open-meteo.com). Note that Open-Meteo's free tier is
non-commercial; `WeatherAPIConfiguration` keeps the endpoints swappable for that reason.

© 2026 Gregg Goldring.
