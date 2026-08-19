# Deploy Splitsies

Manual App Store release. There is no Fastlane, Xcode Cloud, or GitHub Actions iOS pipeline. Build and upload from Xcode, then finish the release in App Store Connect.

## Identity

| Field | Value |
|---|---|
| Display name | Splitsies: Track Cycling Splits |
| Bundle ID | `com.greggoldring.Splitsies` |
| Team | `69KF2FSA88` |
| Scheme / target | `Splitsies` |
| Platforms | iPhone + iPad |
| Deployment target | iOS 17.0 |
| Signing | Automatic |
| Privacy policy | https://greggoldring.github.io/splitsies/ |

Version and build live in `Splitsies.xcodeproj/project.pbxproj` as `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` (Debug and Release for the Splitsies target). The Credits screen reads those values at runtime.

## Versioning

App Store Connect rejects a re-upload of the same **build number**. The marketing version is what users see.

1. Open the Splitsies target in Xcode → **General** → **Identity**.
2. Or edit both Debug and Release entries in `project.pbxproj`:
   - `CURRENT_PROJECT_VERSION` — increment for **every** upload (1 → 2 → 3).
   - `MARKETING_VERSION` — bump only for a new user-facing store version (1.0 → 1.1).

If **1.0 (1)** has never been uploaded, keep it. If it is already in App Store Connect, increment the build (and the marketing version if this is a new store version).

## Preflight

- [ ] Signed into Xcode with the Apple ID for team `69KF2FSA88` (**Xcode → Settings → Accounts**).
- [ ] Latest code you intend to ship is checked out (usually `main`).
- [ ] Version / build is correct (see above).
- [ ] Run the app on a device or simulator and smoke-test start/split/stop, history, and Settings.
- [ ] Destination for Archive is **Any iOS Device (arm64)**, not a simulator.
- [ ] App icon is present (`Splitsies/Assets.xcassets/AppIcon.appiconset`).
- [ ] Privacy policy is live at https://greggoldring.github.io/splitsies/ (GitHub Pages from `docs/` on `main`).

### Privacy answers (review risk)

`docs/index.html` says the app never transmits data off-device. Optional **Open-Meteo** weather lookups send **venue coordinates** (not GPS) when Weather API lookups are on in Settings. App Privacy in App Store Connect should mention this third-party request. Update the privacy page before submit if you want the listing and the policy to match.

Motion / barometer: `NSMotionUsageDescription` is already in `Info.plist`.

## Archive and upload

1. Open `Splitsies.xcodeproj` in Xcode.
2. Select the **Splitsies** scheme.
3. In the destination menu, choose **Any iOS Device (arm64)**.
4. **Product → Archive**. Wait for the Organizer to open.
5. Select the new archive → **Distribute App**.
6. **App Store Connect** → **Upload** → Next.
7. Leave automatically manage signing selected.
8. Confirm export compliance when asked: the app uses HTTPS only and has no `ITSAppUsesNonExemptEncryption` key. Choose that you use encryption **and** that it is **exempt** (standard HTTPS).
9. Upload. Wait until Organizer reports success.

Processing in App Store Connect usually takes a few minutes to an hour. The build appears under the app → **TestFlight**.

## TestFlight

1. Open [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → **Splitsies: Track Cycling Splits** (or create the app if this is the first upload: bundle ID `com.greggoldring.Splitsies`).
2. **TestFlight** → wait until the build status is **Ready to Test**.
3. Complete export compliance if the build is waiting on it (HTTPS / exempt, as above).
4. Add yourself (and any testers) under Internal Testing.
5. Install from the TestFlight app on a physical iPhone or iPad.
6. Smoke-test the same flows as preflight.

## App Store listing and submit

Do this once for the first release; for later versions, add a new version and attach the new build.

1. **App Store** tab → the **1.0** version (or **+** version if 1.0 already shipped).
2. Select the processed build.
3. Fill required metadata:
   - Name: `Splitsies: Track Cycling Splits`
   - Privacy Policy URL: `https://greggoldring.github.io/splitsies/`
   - Category (suggested): Sports or Health & Fitness
   - Age rating
   - Screenshots for the device sizes Apple requires (iPhone; iPad if you keep iPad as a supported destination)
   - Description, keywords, support URL, and a support email
4. **App Privacy**: declare that optional weather lookups send venue coordinates to Open-Meteo. Race history and barometer readings stay on device.
5. **Pricing and Availability**.
6. **Add for Review** → **Submit to App Review**.

Review notes worth including: barometer is used only to record air pressure with splits (`NSMotionUsageDescription`); Open-Meteo is optional and can be turned off in Settings; Space Mono is OFL-licensed and attributed in Credits.

## After approval

In App Store Connect, release **1.0** (manual or automatic, depending on what you chose at submit). Confirm the live listing and the privacy URL.

## Later releases

1. Land work on `main`.
2. Increment `CURRENT_PROJECT_VERSION`. Bump `MARKETING_VERSION` if users should see a new version number.
3. Archive → Upload → TestFlight → attach the build to the store version → Submit.
