package com.godot.game;

import android.app.Activity;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.WindowInsets;
import android.widget.FrameLayout;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;

public class AdBridge {
    private static final String TAG = "AdMob";

    public static final String BANNER_UNIT = BuildConfig.ADMOB_BANNER_UNIT;
    public static final String INTERSTITIAL_UNIT = BuildConfig.ADMOB_INTERSTITIAL_UNIT;
    public static final String REWARDED_UNIT = BuildConfig.ADMOB_REWARDED_UNIT;

    private static Activity activity;
    private static AdView bannerView;
    private static InterstitialAd interstitial;
    private static RewardedAd rewarded;
    private static ConsentInformation consentInformation;
    private static boolean consentRequested = false;
    private static volatile boolean consentComplete = false;
    private static boolean mobileAdsStarted = false;
    private static volatile boolean initComplete = false;
    private static volatile boolean adsEnabled = false;
    private static volatile boolean rewardedEnabled = false;
    private static volatile boolean overlayHidden = false;
    private static volatile boolean bannerLoaded = false;
    private static volatile boolean bannerVisible = false;
    private static boolean interstitialLoading = false;
    private static boolean rewardedLoading = false;
    private static volatile boolean rewardEarned = false;
    private static String lastError = "";
    private static final Handler mainHandler = new Handler(Looper.getMainLooper());

    public static void attach(Activity value) {
        activity = value;
    }

    public static void detach(Activity value) {
        if (activity == value) {
            hideBanner();
            activity = null;
            consentRequested = false;
        }
    }

    public static void init() {
        if (activity == null || consentRequested) {
            return;
        }
        consentRequested = true;
        final Activity host = activity;
        mainHandler.post(() -> requestConsentThenInitAds(host));
    }

    private static void requestConsentThenInitAds(Activity host) {
        try {
            ConsentRequestParameters params = new ConsentRequestParameters.Builder().build();
            consentInformation = UserMessagingPlatform.getConsentInformation(host);
            consentInformation.requestConsentInfoUpdate(
                    host,
                    params,
                    () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(
                            host,
                            (FormError formError) -> {
                                if (formError != null) {
                                    lastError = "Consent form: " + formError.getMessage();
                                    Log.w(TAG, lastError);
                                }
                                onConsentFlowFinished();
                            }),
                    (FormError requestError) -> {
                        lastError = "Consent update: " + requestError.getMessage();
                        Log.w(TAG, lastError);
                        onConsentFlowFinished();
                    });
        } catch (Throwable t) {
            lastError = t.getClass().getSimpleName() + ": " + t.getMessage();
            Log.e(TAG, "UMP failed: " + lastError);
            onConsentFlowFinished();
        }
    }

    private static void onConsentFlowFinished() {
        consentComplete = true;
        if (canRequestAdsInternal()) {
            initializeMobileAds();
        } else {
            Log.i(TAG, "Ads not requested: canRequestAds() is false");
        }
    }

    private static void initializeMobileAds() {
        if (mobileAdsStarted) {
            if (initComplete && (adsEnabled || rewardedEnabled)) {
                ensureAdsLoaded();
            }
            return;
        }
        Activity host = activity;
        if (host == null) {
            return;
        }
        mobileAdsStarted = true;
        try {
            MobileAds.initialize(host, status -> {
                initComplete = true;
                if (adsEnabled || rewardedEnabled) {
                    ensureAdsLoaded();
                }
            });
        } catch (Throwable t) {
            lastError = t.getClass().getSimpleName() + ": " + t.getMessage();
            Log.e(TAG, "Initialization failed: " + lastError);
            mobileAdsStarted = false;
        }
    }

    private static void ensureAdsLoaded() {
        if (!initComplete || !canRequestAdsInternal()) {
            return;
        }
        if (adsEnabled) {
            if (bannerView == null) {
                createBanner();
            }
            loadInterstitial();
        }
        if (rewardedEnabled) {
            loadRewarded();
        }
    }

    private static boolean canRequestAdsInternal() {
        return consentInformation != null && consentInformation.canRequestAds();
    }

    private static boolean adsAllowed() {
        return initComplete && adsEnabled && canRequestAdsInternal();
    }

    public static boolean canRequestAds() {
        return canRequestAdsInternal();
    }

    public static boolean isConsentComplete() {
        return consentComplete;
    }

    public static boolean isPrivacyOptionsRequired() {
        return consentInformation != null
                && consentInformation.getPrivacyOptionsRequirementStatus()
                == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
    }

    public static void showPrivacyOptions() {
        Activity host = activity;
        if (host == null) {
            return;
        }
        mainHandler.post(() -> UserMessagingPlatform.showPrivacyOptionsForm(host, formError -> {
            if (formError != null) {
                lastError = "Privacy options: " + formError.getMessage();
                Log.w(TAG, lastError);
            }
            if (canRequestAdsInternal()) {
                initializeMobileAds();
                if (adsEnabled || rewardedEnabled) {
                    ensureAdsLoaded();
                }
            } else {
                hideBanner();
            }
        }));
    }

    public static int getBannerHeightDp() {
        return 54;
    }

    public static boolean isBannerVisible() {
        return bannerVisible && bannerLoaded && adsAllowed() && !overlayHidden;
    }

    public static boolean setAdsEnabled(boolean enabled) {
        adsEnabled = enabled;
        init();
        mainHandler.post(() -> {
            if (!enabled) {
                hideBanner();
                return;
            }
            if (!initComplete) {
                if (canRequestAdsInternal()) {
                    initializeMobileAds();
                }
                return;
            }
            if (!canRequestAdsInternal()) {
                hideBanner();
                return;
            }
            if (bannerView == null) {
                createBanner();
            } else {
                bannerView.setVisibility(overlayHidden ? View.GONE : View.VISIBLE);
                bannerVisible = !overlayHidden;
            }
            loadInterstitial();
            loadRewarded();
        });
        return true;
    }

    public static boolean setRewardedEnabled(boolean enabled) {
        rewardedEnabled = enabled;
        init();
        mainHandler.post(() -> {
            if (!enabled) {
                return;
            }
            if (!initComplete) {
                if (canRequestAdsInternal()) {
                    initializeMobileAds();
                }
                return;
            }
            if (canRequestAdsInternal()) {
                loadRewarded();
            }
        });
        return true;
    }

    public static void setOverlayHidden(boolean hidden) {
        overlayHidden = hidden;
        mainHandler.post(() -> {
            if (bannerView != null) {
                bannerView.setVisibility(hidden ? View.GONE : View.VISIBLE);
                bannerVisible = !hidden && adsAllowed();
            }
        });
    }

    private static void createBanner() {
        Activity host = activity;
        if (host == null || !adsAllowed()) {
            return;
        }
        try {
            AdView view = new AdView(host);
            view.setAdUnitId(BANNER_UNIT);
            DisplayMetrics metrics = host.getResources().getDisplayMetrics();
            int widthDp = Math.max(280, Math.round(metrics.widthPixels / metrics.density));
            AdSize size = AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(host, widthDp);
            if (size == null) {
                size = AdSize.BANNER;
            }
            view.setAdSize(size);
            view.setAdListener(new AdListener() {
                @Override
                public void onAdLoaded() {
                    bannerLoaded = true;
                    bannerVisible = adsAllowed() && !overlayHidden;
                    view.setVisibility(bannerVisible ? View.VISIBLE : View.GONE);
                }

                @Override
                public void onAdFailedToLoad(LoadAdError error) {
                    bannerLoaded = false;
                    bannerVisible = false;
                    lastError = error != null ? error.getMessage() : "Banner failed";
                    view.setVisibility(View.GONE);
                }

                @Override
                public void onAdImpression() {
                    bannerVisible = adsAllowed() && !overlayHidden;
                }
            });
            FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
            int navInsetPx = 0;
            if (Build.VERSION.SDK_INT >= 30) {
                WindowInsets insets = host.getWindow().getDecorView().getRootWindowInsets();
                if (insets != null) {
                    navInsetPx = insets.getInsets(WindowInsets.Type.navigationBars()).bottom;
                }
            } else {
                WindowInsets insets = host.getWindow().getDecorView().getRootWindowInsets();
                if (insets != null) {
                    navInsetPx = insets.getSystemWindowInsetBottom();
                }
            }
            int minGestureGap = Math.round(24f * metrics.density);
            int extraGap = Math.round(8f * metrics.density);
            params.bottomMargin = Math.max(navInsetPx, minGestureGap) + extraGap;
            view.setElevation(1000f);
            host.addContentView(view, params);
            bannerView = view;
            view.loadAd(new AdRequest.Builder().build());
        } catch (Throwable t) {
            lastError = t.getClass().getSimpleName() + ": " + t.getMessage();
            Log.e(TAG, "Banner failed: " + lastError);
        }
    }

    public static void hideBanner() {
        mainHandler.post(() -> {
            if (bannerView != null) {
                bannerView.setVisibility(View.GONE);
            }
            bannerVisible = false;
        });
    }

    public static void loadInterstitial() {
        mainHandler.post(AdBridge::loadInterstitialInternal);
    }

    private static void loadInterstitialInternal() {
        if (!adsAllowed() || interstitial != null || interstitialLoading || activity == null) {
            return;
        }
        interstitialLoading = true;
        InterstitialAd.load(activity, INTERSTITIAL_UNIT, new AdRequest.Builder().build(),
                new InterstitialAdLoadCallback() {
                    @Override
                    public void onAdLoaded(InterstitialAd ad) {
                        interstitialLoading = false;
                        interstitial = ad;
                        interstitial.setFullScreenContentCallback(new FullScreenContentCallback() {
                            @Override
                            public void onAdDismissedFullScreenContent() {
                                interstitial = null;
                                loadInterstitial();
                            }

                            @Override
                            public void onAdFailedToShowFullScreenContent(AdError error) {
                                interstitial = null;
                                loadInterstitial();
                            }
                        });
                    }

                    @Override
                    public void onAdFailedToLoad(LoadAdError error) {
                        interstitialLoading = false;
                        interstitial = null;
                        lastError = error != null ? error.getMessage() : "Interstitial failed";
                    }
                });
    }

    public static boolean isInterstitialReady() {
        return interstitial != null;
    }

    public static boolean showInterstitial() {
        if (!adsAllowed() || activity == null || interstitial == null) {
            loadInterstitial();
            return false;
        }
        final InterstitialAd ad = interstitial;
        mainHandler.post(() -> ad.show(activity));
        interstitial = null;
        return true;
    }

    public static void loadRewarded() {
        mainHandler.post(AdBridge::loadRewardedInternal);
    }

    private static void loadRewardedInternal() {
        if (!initComplete || !canRequestAdsInternal() || !rewardedEnabled || rewarded != null || rewardedLoading || activity == null) {
            return;
        }
        rewardedLoading = true;
        RewardedAd.load(activity, REWARDED_UNIT, new AdRequest.Builder().build(),
                new RewardedAdLoadCallback() {
                    @Override
                    public void onAdLoaded(RewardedAd ad) {
                        rewardedLoading = false;
                        rewarded = ad;
                        rewarded.setFullScreenContentCallback(new FullScreenContentCallback() {
                            @Override
                            public void onAdDismissedFullScreenContent() {
                                rewarded = null;
                                loadRewarded();
                            }

                            @Override
                            public void onAdFailedToShowFullScreenContent(AdError error) {
                                rewarded = null;
                                loadRewarded();
                            }
                        });
                    }

                    @Override
                    public void onAdFailedToLoad(LoadAdError error) {
                        rewardedLoading = false;
                        rewarded = null;
                        lastError = error != null ? error.getMessage() : "Rewarded ad failed";
                    }
                });
    }

    public static boolean isRewardedReady() {
        return rewarded != null;
    }

    public static boolean showRewarded() {
        if (!initComplete || !canRequestAdsInternal() || !rewardedEnabled || activity == null || rewarded == null) {
            loadRewarded();
            return false;
        }
        final RewardedAd ad = rewarded;
        rewardEarned = false;
        mainHandler.post(() -> ad.show(activity, (RewardItem reward) -> {
            rewardEarned = true;
            rewarded = null;
            loadRewarded();
        }));
        rewarded = null;
        return true;
    }

    public static boolean consumeReward() {
        boolean earned = rewardEarned;
        rewardEarned = false;
        return earned;
    }

    public static String getLastError() {
        return lastError;
    }
}
