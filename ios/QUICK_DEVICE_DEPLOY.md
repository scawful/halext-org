# Quick Device Deploy (Chris + You)

Fastest ways to get a build onto two phones without waiting for full App Store review. Pick the path that matches your time window.

## TL;DR Checklist
- ✅ Add both UDIDs to the Halext dev team profile (Xcode > Settings > Accounts > Manage Certificates > download profiles). Grab UDIDs via Finder (click serial number) or Settings > General > About > Copy Identifier.
- ✅ Bump build if shipping over TestFlight: `./scripts/increment-build.sh`
- ✅ Use the **Any iOS Device (arm64)** destination (never a simulator) for archives.

## Path A: Plug In and Run (fastest, no IPA)
1) Plug in your phone, trust the Mac. In Xcode, open `Cafe.xcodeproj`, pick your device from the toolbar.
2) Ensure Signing Team is your shared Halext team; let automatic signing create a development profile.
3) `Cmd+B` then `Cmd+R` to install. Repeat with Chris’s phone (switch destination to his device). This uses dev provisioning; expires after 7 days unless reopened.

## Path B: Ad-hoc / AltStore IPA (fast share, no App Store)
1) From `ios/`, run the unsigned AltStore build (keeps DerivedData local to repo to avoid permission issues):
   ```bash
   ./build-for-altstore.sh
   ```
   or produce a release IPA without signing:
   ```bash
   ./build-ipa.sh
   ```
   The IPA lands in `ios/build/Cafe.ipa`.
2) AirDrop `Cafe.ipa` to each phone. In Files, tap → **Share** → **Open in AltStore** (AltStore signs with the device owner’s Apple ID).
3) If you have an Ad-hoc signing profile installed locally, you can export a signed IPA instead: archive in Xcode (Product > Archive) and Distribute > Ad Hoc, then AirDrop that IPA directly.

## Path C: TestFlight (if you need OTA + crash symbols)
1) Bump build (optional but recommended): `./scripts/increment-build.sh`
2) Quick archive + upload:
   ```bash
   ./scripts/archive-for-testflight.sh
   ./scripts/upload-to-testflight.sh
   ```
3) Add Chris as an internal tester in App Store Connect (TestFlight tab). Invites land in his email; installs via the TestFlight app.
4) Refer to `QUICK_TESTFLIGHT.md` for screenshots and troubleshooting.

## Notes
- Keep a shared note with the current dev profile + the two UDIDs so you can refresh signing in one shot.
- If Xcode complains about missing simulators, ignore—archives should target **Any iOS Device**.
- Device deploy is fastest right after a code change; avoid waiting for CI if the change is UI-only and you’re sharing via AltStore/ad-hoc.
