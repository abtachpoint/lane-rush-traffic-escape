# Final setup steps

## 1. GitHub
Upload the contents of this project to a new GitHub repository. Do **not** upload any `.jks`, keystore info, `key.properties`, or secrets.

## 2. Codemagic signing
In Codemagic, add the supplied `LaneRush_Upload_Keystore.jks` as an Android keystore with reference name:

`lane_rush_upload`

Use the alias/passwords from the separate `LaneRush_Keystore_Info.txt` file.

The included `codemagic.yaml` builds both:
- `app-release.apk`
- `app-release.aab`

## 3. First test build
Run workflow: `android-release`.

The starter project uses Google test ads, so the APK is safe for ad testing.

## 4. AdMob production setup
Before uploading a production-ready AAB:
- Create the app in AdMob using package `com.lanerush.trafficescape`.
- Create one Rewarded ad unit and one Interstitial ad unit.
- Replace the sample App ID in AndroidManifest.
- Replace the production IDs in `lib/services/ad_service.dart`.
- Change `AdConfig.useTestAds = false`.
- Add consent/privacy handling required for the countries and audience you serve.

Do not test your own live ads by repeatedly viewing/clicking them. Keep test ads enabled during development.

## 5. Play Console IAP
Create the exact product IDs listed in `PLAY_CONSOLE_PRODUCTS.md` as one-time products. The game queries prices from Google Play; fallback USD labels are only visible before products are active.

Play Points coupons, when available, are applied by Google Play checkout. No coupon code logic is needed inside the game.

## 6. Store listing / policy
- Category: Game / Racing or Arcade
- Ads: Yes
- In-app purchases: Yes
- Login/account: No
- Privacy policy: upload `docs/privacy-policy.html` to your GitHub Pages site and use the public URL in Play Console.

## 7. Update rule
For every future Play update, increase the version code in `pubspec.yaml`, for example:

`version: 1.0.1+2`
