# Lane Rush: Traffic Escape

Package ID: `com.lanerush.trafficescape`

A polished 2D Flutter + Flame arcade traffic game with no login system.

## Included gameplay
- 3 modes: Same Direction, Oncoming Traffic, Mixed Traffic
- 12 garage cars with different top speed and acceleration
- Live km/h speed meter
- Instant LEFT/RIGHT lane buttons + Brake + Nitro controls
- Traffic variety from the full garage car pool with rarity weighting and repeat cooldown
- Coins, Shield, Magnet, 2x Coin, Slow Motion and Nitro pickups
- Score multipliers by mode
- Daily rewards, missions and local progress
- Rewarded ad revive and +500 coin reward
- Limited interstitial ads every few completed runs
- Google Play Billing coin packs + Remove Ads
- Local/offline save; no user account or login
- Custom launcher icon, car art and sound effects
- Codemagic workflow for signed APK + AAB

## Technical
- Flutter + Flame
- compileSdk 36
- targetSdk 36
- minSdk 24
- Java 17
- Package: `com.lanerush.trafficescape`
- Version: `1.0.1+2`

## Important before publishing
This starter build intentionally uses Google's official **test AdMob IDs**. Before publishing:
1. Create Lane Rush in AdMob.
2. Create Rewarded and Interstitial ad units.
3. Replace the sample AdMob App ID in `android/app/src/main/AndroidManifest.xml`.
4. Put your ad unit IDs in `lib/services/ad_service.dart`.
5. Change `AdConfig.useTestAds` to `false`.
6. Complete Google Play Data Safety / Ads declarations and consent setup appropriate to your audience and countries.

The in-app purchase product IDs are already coded, but they are hidden from the shop UI. Create/activate matching one-time products in Play Console; the app shows only the actual localized Google Play price when available.

See `FINAL_SETUP_STEPS.md` and `PLAY_CONSOLE_PRODUCTS.md`.


## v1.0.2+3
Production AdMob App ID, Rewarded Ad Unit ID, and Interstitial Ad Unit ID are configured for the Closed Testing release.
