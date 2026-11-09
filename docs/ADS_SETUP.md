# AdMob, UMP consent, and Remove Ads

Version **3.3.0** (versionCode **6**) ships with real Google Mobile Ads + User Messaging
Platform code. Debug builds default to Google's official **test IDs**. A **release**
Gradle build **fails** if those test IDs are still in use.

Package name stays `com.fajar.ultimatecanvas3d`.

## 1. Production IDs (do not hardcode)

Create an AdMob app for `com.fajar.ultimatecanvas3d`, then a banner, interstitial and
rewarded unit. Pass the four IDs at build time — they are **not** stored in git.

### Option A — gitignored `admob.properties` (recommended for Godot export)

Copy [`admob.properties.example`](../admob.properties.example) to **`admob.properties`**
at the Godot project root (or `android/build/admob.properties`):

```
admobAppId=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
admobBanner=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz
admobInterstitial=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz
admobRewarded=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz
```

`admob.properties` is gitignored. Gradle reads it during the Godot Android export.

### Option B — Gradle `-P` flags

```text
-PadmobAppId=ca-app-pub-xxxx~yyyy
-PadmobBanner=ca-app-pub-xxxx/yyyy
-PadmobInterstitial=ca-app-pub-xxxx/yyyy
-PadmobRewarded=ca-app-pub-xxxx/yyyy
```

### Option C — environment variables

`ADMOB_APP_ID`, `ADMOB_BANNER`, `ADMOB_INTERSTITIAL`, `ADMOB_REWARDED`.

Resolution order: Gradle `-P` / `gradle.properties` → `admob.properties` → env vars →
Google test IDs (debug only).

### How IDs are applied

| ID | Injected as |
|---|---|
| App ID | AndroidManifest placeholder `${admobAppId}` (`com.google.android.gms.ads.APPLICATION_ID`) |
| Banner / interstitial / rewarded | `BuildConfig.ADMOB_*_UNIT` read by `AdBridge` |

Debug builds without real IDs use:

- App: `ca-app-pub-3940256099942544~3347511713`
- Banner: `ca-app-pub-3940256099942544/6300978111`
- Interstitial: `ca-app-pub-3940256099942544/1033173712`
- Rewarded: `ca-app-pub-3940256099942544/5224354917`

Release builds that still resolve to those test IDs **fail** with a Gradle error.
Internal-only exception: `-PadmobAllowTestIds=true`.

## 2. Release AAB on Windows (Godot 4.7.2)

Godot: `C:\dev\godot\Godot_v4.7.2-stable_win64_console.exe`  
Preset: **Android AAB**  
Output: `build/InfiniteCanvas3D-v3.3.0-release.aab`

1. Put real IDs in `admob.properties` (project root).
2. From the project root:

```bat
"C:\dev\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "Android AAB" build/InfiniteCanvas3D-v3.3.0-release.aab
```

3. Sign with the existing release keystore (password lives in a **local untracked**
   file such as `build/SIGNING-KEY.txt` — never commit it):

```bat
jarsigner -sigalg SHA256withRSA -digestalg SHA-256 ^
  -keystore build/ultimatecanvas-release.keystore ^
  build/InfiniteCanvas3D-v3.3.0-release.aab ultimatecanvas
```

Keystore: `build/ultimatecanvas-release.keystore` · alias `ultimatecanvas`.
The keystore, password file, AABs and APKs are gitignored.

If Godot is configured to sign during export (`export_credentials.cfg`, also
gitignored), you can skip the `jarsigner` step. Do not commit signing secrets.

## 3. Debug APK (test ads)

```bash
godot --headless --path . --export-debug "Android Gradle APK" build/InfiniteCanvas3D-gradle.apk
```

No `admob.properties` needed; Google's test IDs are used.

## 4. Consent (UMP)

On launch `AdBridge` calls `requestConsentInfoUpdate`, then
`loadAndShowConsentFormIfRequired`. **Mobile Ads is initialized and ads are loaded
only when `canRequestAds()` is true.**

If `privacyOptionsRequirementStatus` is `REQUIRED`, Settings shows **Privacy options**,
which calls `UserMessagingPlatform.showPrivacyOptionsForm`.

SDK: `com.google.android.ump:user-messaging-platform:3.2.0` with
`com.google.android.gms:play-services-ads:23.6.0`.

Configure GDPR/IDFA messages in AdMob → Privacy & messaging. Point AdMob at
https://fareza777.github.io/infinitecanvas3d/privacy-policy.html

## 5. Ad formats

| Format | Placement | Behaviour |
|---|---|---|
| Anchored adaptive banner | Bottom of the board | Native view over the Godot surface; hidden while sheets/onboarding/splash are open; off after Remove Ads or a 24-hour reward |
| Interstitial | After applying a template, plus Settings → "Watch a short ad" | Preloaded; 90-second cooldown; never shown when ad-free |
| Rewarded | Settings → "Watch a rewarded ad" | **Optional** (user-initiated only). Grants a 24-hour ad-free window for banner/interstitial. Still offered during that window. Hidden after Remove Ads |

`remove_ads` (Play Billing, $4.99) permanently disables banner, interstitial **and**
rewarded. Banner/interstitial requests are not made when ads are off.

## 6. Remove Ads product

Create a **one-time in-app product** in Play Console:

| Field | Value |
|---|---|
| Product ID | `remove_ads` |
| Type | One-time product (not a subscription) |
| Price | **$4.99** USD |
| Status | Active |

The app queries `remove_ads`, acknowledges purchases and restores the entitlement. A
sideloaded APK correctly reports Billing unavailable.

## 7. Policy notes

- Test with test IDs / test devices. Never click your own live ads.
- Declare ads and in-app purchases in Play Console Data safety.
- Hosted privacy policy: https://fareza777.github.io/infinitecanvas3d/privacy-policy.html
