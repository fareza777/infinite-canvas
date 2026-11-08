# Google Play Console Setup — v3.2.0

This checklist turns the source into a live, monetised Play Store app.

## 1. App identity

| Field | Value |
|---|---|
| Package name | `com.fajar.ultimatecanvas3d` |
| App name | Ultimate Infinite Canvas 3D Pro |
| Category | Art & Design |
| Pricing | Free, contains ads, one-time in-app purchase |
| Ads | **Yes** (AdMob banner, interstitial, rewarded) |
| In-app purchases | **Yes** — Remove Ads |

## 2. Create the app

1. Play Console → **All apps → Create app**.
2. Complete **Dashboard → Set up your app**: privacy policy, **ads declaration = Yes**,
   content rating, target audience and Data safety.
3. Host `docs/PRIVACY_POLICY.md` at a public URL and use it as the privacy policy.

## 3. Billing product — Remove Ads only

There is **no Pro product or subscription** in this version. Delete/deactivate any old
`ultimate_pro_lifetime` / `ultimate_pro_monthly` products if this is an existing listing.

Create in **Monetise → Products → In-app products**:

| Field | Value |
|---|---|
| Product ID | `remove_ads` |
| Type | One-time product |
| Price | **$4.99** USD (or local equivalent) |
| Status | Active |
| Description | Permanently remove banner, interstitial and rewarded ads. |

The app queries `remove_ads`, acknowledges purchases and restores the entitlement. It displays
Google's formatted price when Billing is available, otherwise the fallback **$4.99**.

## 4. AdMob

The build ships with Google's official test IDs. Before publishing:

1. Create an AdMob app for `com.fajar.ultimatecanvas3d`.
2. Create a banner, an interstitial and a rewarded ad unit.
3. Replace the AdMob app ID in `android/build/src/main/AndroidManifest.xml`.
4. Replace the three unit IDs in `android/build/src/main/java/com/godot/game/AdBridge.java`.
5. Add the AdMob privacy policy URL and complete any consent requirements (EEA/UK UMP).
6. Rebuild and sign the AAB; confirm live test ads on a test device with test IDs first.

Full details: `docs/ADS_SETUP.md`.

## 5. Build and sign

```bash
godot --headless --path . --export-debug "Android Gradle APK" build/adtest.apk
```

Release artifacts for this version:

- `build/UltimateInfiniteCanvas3D-v3.2.0-release-signed.apk` (arm64)
- `build/UltimateInfiniteCanvas3D-v3.2.0-release.aab` (signed)
- Version name **3.2.0**, version code **5**

Sign the AAB:

```bash
jarsigner -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore build/ultimatecanvas-release.keystore \
  build/UltimateInfiniteCanvas3D-v3.2.0-release.aab ultimatecanvas
```

Upload the signed AAB. Keep the keystore and password safe; losing it blocks future updates.

## 6. Test purchases and ads

1. Upload the AAB to **Testing → Closed testing** and publish.
2. Add your account under **Setup → License testing**.
3. Install from the Play track (not a sideloaded APK).
4. Settings → Ads & support → Remove Ads; complete the `$4.99` purchase.
5. Confirm the banner disappears immediately and remains gone after relaunch.
6. Use **Restore purchase** on a reinstalled build.
7. Test the rewarded ad on a non-purchased install; confirm the 24-hour ad-free state and that
   it expires.
8. Sideloaded APKs correctly report Billing unavailable and never fake a purchase.

## 7. Data safety

Declare:

- **Ads:** Google Mobile Ads may collect device/ad identifiers and ad interactions under
  Google's policies.
- **Purchases:** Google Play processes the Remove Ads purchase; the app stores a purchase
  token locally to restore entitlement.
- Boards, media, PDFs and restore points stay on-device and are not uploaded.
- No account, no analytics, no developer-operated cloud sync.
- Users can delete data by uninstalling or by deleting boards/exports in the app.

## 8. Permissions

- `com.android.vending.BILLING` — Remove Ads.
- `android.permission.INTERNET` / network state — AdMob and Billing.
- `android.permission.VIBRATE` — haptics.
- File access uses the Android system document picker (SAF).

## 9. Store listing

Use `docs/STORE_LISTING.md`. Update the ads declaration to **Yes**, make the Remove Ads feature
clear, and use light + dark screenshots. Recommended assets:

- App icon: `assets/icon_512.png`
- Feature graphic: porcelain/cobalt with the app icon and "Think in space."
- Phone screenshots: onboarding (light + dark), canvas, 3D, create, Smart Studio, Settings,
  Ads & Remove Ads, About, templates, export.

## 10. Release checklist

- [ ] Signed AAB v3.2.0 (code 5) uploaded
- [ ] `remove_ads` one-time product active at $4.99
- [ ] Old Pro products deactivated
- [ ] Production AdMob IDs replace the test IDs (or confirm test build only)
- [ ] Ads declaration = Yes; Data safety completed
- [ ] Privacy policy URL live
- [ ] License testers added
- [ ] Purchase/restore/entitlement verified from Play
- [ ] Banner/interstitial/rewarded verified on device
- [ ] Screenshots and feature graphic uploaded
- [ ] Closed test completed if required for a new account

## 11. Updates

Increase `version/code` in every export preset and `config/version` in `project.godot`, rebuild,
sign and upload. Never change the package name or release keystore after the first release.
