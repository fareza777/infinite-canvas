# Test & QA Log

## 3.3.0 Play-release notes

- Version **3.3.0**, versionCode **6**. Package still `com.fajar.ultimatecanvas3d`.
- UMP consent runs before Mobile Ads init. Settings shows Privacy options when required.
- Release AAB requires real AdMob IDs (`docs/ADS_SETUP.md`). Debug keeps Google test IDs.
- Hosted privacy policy: https://fareza777.github.io/infinitecanvas3d/privacy-policy.html
- Historical device QA below is from v3.2.0; re-verify ads, consent, Remove Ads and the
  privacy-policy link on a Play track build before production rollout.

## Automated tests

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

**Final result: 92 passed, 0 failed** on Godot 4.7.2.stable headless (`--script res://tests/test_runner.gd`).

Coverage: project model/layers/CRUD/connectors/storyboard/serialisation, undo, Smart Engine,
storage/backup/export, restore points, PDF guards, project validation.

## Desktop visual QA — 3.2.0

Captured at Android's logical 432×960 in both **Light** and **Dark/AMOLED**:

- Onboarding (enlarged text, Start/Explore, privacy line; fits both themes).
- Canvas, dark chrome, empty-state card, Settings, About.
- Create, Templates, Projects, Export, Layers, Smart Studio, Idea graph, Storyboard,
  Navigation, View & lighting, Help, Primitive, Inspector and layer options.
- Settings top/Appearance, scrolled Tools/Editor and the **Ads & support** section.

Text/layout defects found and fixed in this pass:

| Page | Defect | Fix |
|---|---|---|
| Export | Two-line format subtitles clipped by 60 px rows | 88 px rows, 14 px subtitles |
| Templates | Third subtitle line cut off | 170 px cards, 3-line subtitle |
| Projects | 12 px project title/stats | 14 px, 64 px row, ellipsis guard |
| Layers | 8 px type tags / 38 px hierarchy rows | 12 px tags, 46 px rows |
| Graph | Node labels ran past the panel edges | Labels clamped inside the panel |
| Help | Header title truncated ("Gestures & shortc…") | Header renamed to "Help" |
| Primitive | 82 px cards clipped after the type increase | 130 px cards |
| Settings | Small 11–12 px labels/subtitles | 13–14 px subs, 17–18 px titles, 100 px rows |
| Onboarding | Privacy line forced content wider than screen | Wrapped privacy line; all small copy enlarged |
| Theme | Hard-coded white graph labels in dark mode | Theme-aware surface/text colors |

The active segmented control in Dark/AMOLED uses dark ink on the brighter accent to keep
contrast when the primary buttons are pastel.

## Android / AdMob verification

- Gradle compiled the real Google Mobile Ads SDK (`play-services-ads:23.6.0`) and the
  `AdBridge` Java class for both x86_64 debug and arm64 release.
- The emulator log confirmed AdMob initialization and the Google Play services ad service
  loading during the 3.2.0 run.
- The final 3.2.0 UI smoke test on the emulator and physical phone could not be completed:
  both devices dropped offline repeatedly during install (emulator `device offline`) and the
  phone never reappeared after the final build.
- Therefore banner/interstitial/rewarded **display and click-through have not been visually
  confirmed on a device**, and the Remove Ads purchase has not been completed. The ad units
  in this build are Google's official **test IDs**, not production monetisation.
- The release APK/AAB are signed and ready; install the APK and open Settings → Ads & support
  to verify banners/rewarded ads on a connected device.

## Physical phone (v3.1.0 baseline)

The signed arm64 v3.1.0 build was installed over 3.0.0 on the Xiaomi 2201117TY (Android 13,
Adreno 610, 1080×2400) and the existing board survived. Verified: native splash, light board,
topbar/rail/dock, More/Settings, Compact/Large/XL live rebuild, Settings scrolling, About device
facts, native Android share sheet and the Play/GetApps rate chooser.

MIUI later rejected the ADB update with `INSTALL_FAILED_USER_RESTRICTED`; the v3.2.0 APK must be
opened manually from the phone's Download folder (or install after enabling Developer options →
Install via USB). Do **not** uninstall the existing app; install as an update to keep boards.

## Device checklist for v3.2.0

1. Install v3.2.0 over v3.1.0; confirm existing boards survive.
2. Launch; verify splash → board. On the first board screen the adaptive banner should load at
   the bottom and the floating dock should sit above it (Settings → Ads status).
3. Open a sheet: banner hides; close: banner returns.
4. Settings → UI theme: Light, Dark, AMOLED; verify the whole UI re-themes and the choice
   persists after relaunch.
5. Settings → Ads & support: confirm the `$4.99` Remove Ads row, test the rewarded ad, confirm
   the 24-hour ad-free state hides the banner. On a Play-installed build, complete the
   `remove_ads` purchase and verify permanent removal/restore.
6. Template → confirm the occasional interstitial is a real test ad and respects the cooldown.
7. Re-check Export, Templates, Layers, Graph, Help, Settings and onboarding at Large and XL.
8. Verify all earlier features (ink, 3D, PDF/image/GLB import, storyboard, backup, share/rate).

## Known limits

- Debug builds use test AdMob IDs (no revenue). Release builds fail unless real IDs are passed
  via `admob.properties` or Gradle `-P` flags. UMP consent runs before any ad request
  (see `docs/ADS_SETUP.md`).
- Sideloaded APKs correctly report Play Billing unavailable; Remove Ads cannot be purchased.
- PDF rasterisation uses Android `PdfRenderer` and is unavailable on desktop.
- glTF external `.bin`/texture dependencies need to be embedded in a GLB for reliable import.
- Photo-real large boards may stress low-end GPUs; Performance mode helps.
