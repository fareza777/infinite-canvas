# AdMob + Remove Ads setup

Version 3.2.0 ships with real Google Mobile Ads code and Google's official **test IDs**.
Test ads are served by the live SDK (so the integration is real), but they do not earn
revenue and must not be published as production monetisation.

## 1. Replace the test IDs

### AdMob application ID

`android/build/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713" />
```

Replace with the App ID from **AdMob → Apps → your app → App settings**.

### Ad unit IDs

`android/build/src/main/java/com/godot/game/AdBridge.java`:

```java
public static final String BANNER_UNIT = ".../6300978111";
public static final String INTERSTITIAL_UNIT = ".../1033173712";
public static final String REWARDED_UNIT = ".../5224354917";
```

Replace all three with your own ad-unit IDs. They must belong to the same AdMob app.

## 2. Ad formats in this build

| Format | Placement | Behaviour |
|---|---|---|
| Anchored adaptive banner | Bottom of the board | Native view over the Godot surface; the UI reserves its height so the dock moves above it; hidden while sheets/onboarding/splash are open |
| Interstitial | After applying a template, plus the manual "Watch a short ad" action in Settings | Preloaded; 90-second in-app cooldown; never shown when ad-free |
| Rewarded | Settings → "Watch a rewarded ad" | Grants a real 24-hour ad-free window; banner/interstitial are then disabled until it expires |

Remove Ads (`remove_ads`, $4.99) permanently disables all three formats. Banner requests
are not made when ads are off. The ad-free reward is stored in `user://app_config.json`;
the permanent entitlement is stored in `user://entitlement.json`.

## 3. Remove Ads product

Create a **one-time in-app product** in Play Console:

| Field | Value |
|---|---|
| Product ID | `remove_ads` |
| Type | One-time product (not a subscription) |
| Price | **$4.99** USD (set in Play Console; the app displays Google's formatted price) |
| Status | Active |

The app queries `remove_ads`, acknowledges purchases and restores the entitlement. It
does **not** ship Pro subscriptions or fake a successful purchase. A sideloaded APK
correctly reports Billing unavailable.

## 4. Consent and policy

- Test with the test IDs before switching to production.
- Set an AdMob privacy policy URL in AdMob and declare ads/in-app purchases in Play
  Console's Data safety and ads declarations.
- If you serve ads in the EEA/UK/Switzerland, add an IAB TCF/GDPR consent flow (Google
  UMP SDK) before requesting ads. This build requests the SDK defaults; it does not
  include a consent management form.
- Never click your own live ads. Use test devices/test IDs while developing.

## 5. Rebuild after changing IDs

```bash
godot --headless --path . --export-debug "Android Gradle APK" build/adtest.apk
```

For release, rebuild the signed APK/AAB as described in the README. The Gradle build
pulls `com.google.android.gms:play-services-ads:23.6.0` and the AdMob application ID
metadata is merged into the final manifest.
