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

public class AdBridge {
    // Google's official test IDs. Replace all four with your AdMob production IDs before publishing.
    public static final String BANNER_UNIT = "ca-app-pub-3940256099942544/6300978111";
    public static final String INTERSTITIAL_UNIT = "ca-app-pub-3940256099942544/1033173712";
    public static final String REWARDED_UNIT = "ca-app-pub-3940256099942544/5224354917";

    private static Activity activity;
    private static AdView bannerView;
    private static InterstitialAd interstitial;
    private static RewardedAd rewarded;
    private static boolean initialized = false;
    private static volatile boolean initComplete = false;
    private static volatile boolean adsEnabled = false;
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
        if (activity != null) {
            initialized = false;
        }
    }

    public static void detach(Activity value) {
        if (activity == value) {
            hideBanner();
            activity = null;
            initialized = false;
        }
    }

    public static void init() {
        if (activity == null || initialized) {
            return;
        }
        initialized = true;
        final Activity host = activity;
        mainHandler.post(() -> {
            try {
                MobileAds.initialize(host, status -> {
                    initComplete = true;
                    if (adsEnabled) {
                        if (bannerView == null) {
                            createBanner();
                        }
                        loadInterstitial();
                        loadRewarded();
                    }
                });
            } catch (Throwable t) {
                lastError = t.getClass().getSimpleName() + ": " + t.getMessage();
                Log.e("AdMob", "Initialization failed: " + lastError);
            }
        });
    }

    public static int getBannerHeightDp() {
        return 54;
    }

    public static boolean isBannerVisible() {
        return bannerVisible && bannerLoaded && adsEnabled && !overlayHidden;
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

    public static void setOverlayHidden(boolean hidden) {
        overlayHidden = hidden;
        mainHandler.post(() -> {
            if (bannerView != null) {
                bannerView.setVisibility(hidden ? View.GONE : View.VISIBLE);
                bannerVisible = !hidden && adsEnabled;
            }
        });
    }

    private static void createBanner() {
        Activity host = activity;
        if (host == null) {
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
                    bannerVisible = adsEnabled && !overlayHidden;
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
                    bannerVisible = adsEnabled && !overlayHidden;
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
            Log.e("AdMob", "Banner failed: " + lastError);
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
        if (!initComplete || !adsEnabled || interstitial != null || interstitialLoading || activity == null) {
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
        if (!adsEnabled || activity == null || interstitial == null) {
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
        if (!initComplete || !adsEnabled || rewarded != null || rewardedLoading || activity == null) {
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
        if (!adsEnabled || activity == null || rewarded == null) {
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
