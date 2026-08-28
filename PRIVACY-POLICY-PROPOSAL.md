# Proposed privacy policy revision — NEEDS GREGG'S REVIEW

> **Status: draft. Not published, and not a decision.**
>
> This file is deliberately **outside `docs/`** so that merging it does not publish anything.
> `docs/` is served as GitHub Pages, so an edit to `docs/index.html` on `main` goes live
> immediately. Nothing here changes the live policy at
> https://greggoldring.github.io/splitsies/ until you copy it into `docs/index.html` yourself.
>
> I am not a lawyer and this is not legal advice. Please read this before using it, and
> delete this file once the question is settled either way.

## The problem in one line

The published policy says the app "does not transmit data off your device." The app sends
venue coordinates to Open-Meteo, by default. Both cannot be true.

Full factual findings — what is sent, when, and to whom — are in the pull request description.

## Two ways to resolve it, and they differ in product terms

**Option A — amend the policy to describe the weather lookup.** Keeps the feature working as
built, including on iPads, which have no barometer and so depend entirely on the lookup for
any pressure data at all. Cost: the policy is no longer a flat "nothing leaves the device,"
and App Store Connect's App Privacy section needs to declare the third-party request.
Draft text for this option is below.

**Option B — change the app so the current claim stays true.** No policy edit needed, and the
strongest privacy story. Cost: it degrades or removes a real feature. Sub-options, roughly in
order of how much they cost:

- **B1 — default the toggle to off.** One-line change to `AppSettings.weatherAPIEnabled`.
  The policy would still need a sentence about what happens when a user turns it *on*, so
  this is really "Option A with a better default," not a fix on its own.
- **B2 — coarsen the coordinates.** Round to 1 decimal place (~11 km) before the request.
  Weather-model pressure varies little over that distance, so accuracy loss is likely
  negligible. This does not make the policy's claim true — data still leaves the device —
  but it shrinks what is disclosed. Mainly useful *with* Option A.
- **B3 — drop the lookup entirely.** The claim becomes true with no caveats. Barometer-less
  devices (all iPads) would then never record pressure, which removes the feature's value
  for those users.

Note that B2 also fixes a real inconsistency: bundled venue coordinates are capped at 3
decimals, but **custom venue coordinates are sent at whatever precision the user typed**,
because `CustomVenueFormView` parses the text field with `Double(latitudeText)` and applies
no rounding. A user who pastes a full-precision coordinate for their local track sends it
verbatim. Rounding at the request boundary would make precision uniform regardless of source.

My suggestion, for what it is worth: **A + B2**, and consider B1. That keeps the feature,
makes the disclosure honest, and reduces what is actually disclosed. But the trade-off between
"flat no-transmission promise" and "pressure data on iPad" is yours to make, not mine.

---

## Draft replacement text for Option A

Two edits to `docs/index.html`: replace the **Data collection** and **Data stored on your
device** sections, and add a **Weather lookups** section after them. Bump the "Last updated"
date at the same time.

Wording assumes coordinates stay as they are. If you take B2 as well, change "the venue's
approximate coordinates (rounded to about 100 m)" to match whatever rounding you apply.

```html
  <p class="updated">Last updated: August 2026</p>

  <h2>Data collection</h2>
  <p>We do <strong>not</strong> collect, store, or share any personal data about you. The App
  has no accounts, no servers, and no analytics or advertising. We never see your race times,
  and there is nothing in the App that identifies you.</p>

  <h2>Data stored on your device</h2>
  <p>Stopwatch times, race history, air pressure readings, and any custom venues you create
  are stored only on your device, using the App's local storage. This data is never uploaded
  anywhere.</p>

  <h2>Weather lookups</h2>
  <p>The App records the air pressure at each lap. On devices with a barometer, this is read
  from the device's own sensor and requires no internet connection. Devices without a
  barometer — including all iPads — cannot do this, so the App can instead look up the
  historical air pressure for the venue you selected.</p>
  <p>These lookups are requested from <a href="https://open-meteo.com">Open-Meteo</a>, a
  third-party weather service. Each request contains only the venue's approximate coordinates
  (rounded to about 100 m) and the date and hour of your session. It does <strong>not</strong>
  contain your name, your device's location, your race times, or any identifier for you or
  your device. The App does not use your device's GPS or location services at all, and does
  not ask for location permission — the coordinates sent are those of the velodrome you chose
  from the venue list.</p>
  <p>As with any internet request, Open-Meteo can see the IP address it came from. Their
  privacy terms are at <a href="https://open-meteo.com/en/terms">open-meteo.com/en/terms</a>.</p>
  <p>You can turn these lookups off completely in <strong>Settings &rarr; Privacy &amp;
  Offline &rarr; Weather API lookups</strong>. With them off, the App makes no internet
  requests of any kind. The barometer continues to work offline on devices that have one.</p>
```

### Also needs updating if you take Option A

- **`DEPLOY.md`** — the "Privacy answers (review risk)" section and the App Privacy step
  already describe this correctly, so they should need no change beyond dropping the
  "update the privacy page before submit" warning once the page is updated.
- **App Store Connect → App Privacy** — declare the Open-Meteo request. Coarse location is
  arguably not the right category here, since the coordinates are a venue's and not the
  user's; "Other Data" or a "Not Linked to You / Not Used for Tracking" diagnostic entry may
  fit better. Worth confirming against Apple's current definitions at submit time.
- **`README.md`** — remove the "Known discrepancy" callout in the *Privacy and network use*
  section once this is resolved.
