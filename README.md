# Infinite Canvas 3D: Whiteboard

**Version 3.3.0** · A **2D + 3D infinite whiteboard** for Android (`com.fajar.ultimatecanvas3d`) with **Light / Dark / AMOLED** themes, built with **Godot 4.7.2** and inspired by [Lorien](https://github.com/mbrlabs/Lorien) (MIT).

Launcher label: **Infinite Canvas 3D**. Store / About name: **Infinite Canvas 3D: Whiteboard**.

One spatial surface for notes, freehand ink, mind maps, storyboards, PDFs, images and real 3D objects. Switch between a crisp 2D canvas and a perspective 3D workspace without losing context.

> **3.3.0 — First Play release prep.**
> User-facing rename, Google UMP consent before any ad request, release-configurable AdMob IDs, hosted privacy policy, versionCode 6.

---

## What is real in this build

| Area | Implementation |
|---|---|
| Themes | **Light porcelain (default), Dark, AMOLED**; the UI rebuilds live from a theme token system; selection persists |
| Typography | Enlarged onboarding/chrome/rows/cards; minimum type floor + Compact/Large/XL scale; text-wrapped rows, taller cards and clamped graph labels to stop clipped copy |
| Infinite canvas | Unbounded coordinates, GPU grid with line/dot/off styles, logarithmic zoom |
| Camera | Six-direction navigation, presets, bookmarks, reduced-motion option |
| 2D ↔ 3D | One scene, animated or instant camera morph |
| Drawing | Pressure-aware 3D ribbon strokes, highlighter, eraser; pressure can be disabled |
| Notes, media, PDF | Live notes, images, Android `PdfRenderer` pages, GLB/glTF imports, PBR primitives and materials |
| Story / structure | Storyboard frames + playback, Smart Studio, knowledge graph, templates, layers, hierarchy, connectors, undo/autosave/restore points |
| Settings | **Theme, text scale, atmosphere, accent, grid/snap, tools, editor, ads/Remove Ads, privacy options, data, support** – all wired |
| Ads | Real **Google Mobile Ads** SDK: anchored adaptive **banner**, preloaded **interstitial**, and an **optional rewarded ad** that removes ads for 24 hours. **UMP consent** runs before any ad request |
| Remove Ads | Real Google Play Billing one-time product **`remove_ads`** (set it to **$4.99** in Play Console). Permanent entitlement; banner + interstitial off after purchase; rewarded stays optional until purchase, then it is also removed |
| About / Share / Rate | Device facts, licence, native Android share sheet via `ShareBridge`, Play Store rating intent, privacy policy link |
| No Pro mode | Pro gates/subscriptions/free-board limits removed; every template/atmosphere/accent is available |
| Offline-first | Boards stay on device; network is used only by UMP, AdMob and Play Billing |

> **Ads use Google’s official AdMob TEST app/ad-unit IDs out of the box for debug.** Release builds fail unless you pass real IDs via `admob.properties` or Gradle `-P` flags (see [`docs/ADS_SETUP.md`](docs/ADS_SETUP.md)). Test ads do not earn revenue.

Privacy policy: https://fareza777.github.io/infinitecanvas3d/privacy-policy.html

### 3.3.0 build status

- **Automated tests:** run `godot --headless --path . --script res://tests/test_runner.gd` (92 cases).
- **AdMob / UMP:** Gradle compiles `play-services-ads:23.6.0`, `user-messaging-platform:3.2.0` and `AdBridge`. Consent is requested on launch; ads load only after `canRequestAds()`.
- **Billing:** Remove Ads purchase requires the APK from a Play track and the `remove_ads` product configured at $4.99. Sideloaded builds correctly report Billing unavailable and never fake a purchase.

---

## Screens

| | |
|---|---|
| ![Onboarding](docs/screenshots/onboarding.png) | ![Canvas](docs/screenshots/canvas.png) |
| ![Settings](docs/screenshots/settings.png) | ![Dark onboarding](docs/screenshots/onboarding-dark.png) |
| ![Dark canvas](docs/screenshots/dark-canvas.png) | ![Dark settings](docs/screenshots/settings-dark.png) |
| ![Ads & Remove Ads](docs/screenshots/settings-ads.png) | ![About](docs/screenshots/about.png) |

Additional light/dark captures live in `docs/screenshots/`.

---

## Build & artifacts

### Debug APK with ads + Billing (test AdMob IDs)

```bash
godot --headless --path . --export-debug "Android Gradle APK" build/InfiniteCanvas3D-gradle.apk
```

### Signed release AAB — v3.3.0, versionCode 6

Windows, Godot 4.7.2 (put real IDs in gitignored `admob.properties` first):

```bat
"C:\dev\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "Android AAB" build/InfiniteCanvas3D-v3.3.0-release.aab
```

Sign with the existing keystore (`build/ultimatecanvas-release.keystore`, alias `ultimatecanvas`). The password lives in a local untracked file (for example `build/SIGNING-KEY.txt`). Never commit secrets.

```bat
jarsigner -sigalg SHA256withRSA -digestalg SHA-256 ^
  -keystore build/ultimatecanvas-release.keystore ^
  build/InfiniteCanvas3D-v3.3.0-release.aab ultimatecanvas
```

The APK/AAB include the arm64 Godot runtime, Google Mobile Ads, UMP, Play Billing, the native PDF bridge and the Share bridge. `minSdk 24`, `targetSdk 36`.

How to pass real AdMob IDs: [`docs/ADS_SETUP.md`](docs/ADS_SETUP.md).

---

## Testing

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

The suite covers the project model, undo, Smart Engine, storage, backups, exports and PDF guards. Desktop QA, the Android ad verification status and the physical-device checklist are in [`docs/TESTING.md`](docs/TESTING.md).

---

## Monetisation setup

1. Create **`remove_ads`** as a one-time in-app product in Play Console, priced at **$4.99** (or your local equivalent).
2. Upload the signed AAB to a Play track and install from Play; Billing is not usable in a sideloaded APK.
3. Create an AdMob app + banner/interstitial/rewarded units and pass IDs via `admob.properties` or `-PadmobAppId` / `-PadmobBanner` / `-PadmobInterstitial` / `-PadmobRewarded`.
4. Follow [`docs/ADS_SETUP.md`](docs/ADS_SETUP.md) and [`docs/PLAY_CONSOLE_SETUP.md`](docs/PLAY_CONSOLE_SETUP.md).

The rewarded ad is optional and grants a real 24-hour ad-free window for banner/interstitial. Remove Ads is permanent. No Pro products/subscriptions remain.

---

## Data & privacy

Projects, media, PDFs, autosaves and exports remain in the app’s private storage. AdMob/Google and Google Play process ad delivery, consent and purchases under their own policies. The app itself has no account, analytics, cloud sync or ad-targeting profile.

- Hosted policy: https://fareza777.github.io/infinitecanvas3d/privacy-policy.html
- Source: [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md)

---

## Project layout

```
scripts/
  app.gd                     orchestrator, ads/theme/remove-ads wiring, input, files
  ads_service.gd             AdMob bridge lifecycle, UMP polling, banner reserve, reward polling
  billing.gd                 Play Billing remove_ads purchase/entitlement
  ui/
    ui.gd                    chrome, sheets, onboarding, splash, ad overlay rules
    panels.gd                create, templates, layers, smart, graph, storyboard,
                             projects, export, inspector, nav, look, help, about
    settings_panel.gd        complete Settings + Ads/Remove Ads + privacy options
    kit.gd                   Light/Dark/AMOLED theme tokens and components
  core/                      project, undo, storage, smart engine, PDF bridge
  world/                     camera, grid, notes/frames/media/models/ink/connectors
android/build/               Godot Gradle template + AdMob/UMP/PDF/Share Java bridges
addons/GodotGooglePlayBilling/ Play Billing plugin
tests/test_runner.gd         92 headless tests
docs/                        ADS_SETUP, TESTING, PLAY_CONSOLE_SETUP, STORE_LISTING, PRIVACY_POLICY
assets/                      icon, splash, fonts, shaders, icon subset
```

---

## Attribution

Inspired by [Lorien](https://github.com/mbrlabs/Lorien) by Marcus Brummer (MIT). Built with [Godot Engine](https://godotengine.org) (MIT). Fonts: Sora, Inter, JetBrains Mono (SIL OFL). Icons: Material Symbols Rounded (Apache 2.0). See `THIRD_PARTY_NOTICES.md` and the in-app About screen.

This project is an independent implementation. It does not copy Lorien's source code.
