# Release checklist

## Before building

- [ ] Version bumped in `pubspec.yaml` (`version: 0.1.0+1`; the number after `+` must increase for every Play upload)
- [ ] `CHANGELOG.md` updated, date added
- [ ] `PRIVACY.md` date filled in
- [ ] Android app label is `ServerDr` (`android/app/src/main/AndroidManifest.xml`)
- [ ] `INTERNET` permission present in the main manifest
- [ ] `applicationId` decided. It can't be changed after a Play release without creating a different app
- [ ] `flutter analyze` and `flutter test` pass
- [ ] Tested on a real device against a real server: password auth, key auth, host verification, SFTP, terminal, health, security

## Signing (one-time)

Generate an upload keystore and **keep it out of git**:

```bash
keytool -genkey -v -keystore ~/serverdr-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (already in `.gitignore`):

```properties
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=upload
storeFile=<absolute path to serverdr-upload.jks>
```

Then wire it into `android/app/build.gradle(.kts)` by following Flutter's official guide: https://docs.flutter.dev/deployment/android#sign-the-app

Back up the keystore and passwords somewhere safe. Losing them can lock you out of updating the app.

## Build

```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons

# APK for direct distribution / GitHub release
flutter build apk --release

# App Bundle for Google Play
flutter build appbundle --release
```

Outputs:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## Publish on GitHub

```bash
git tag v0.1.0
git push origin v0.1.0
```

Then on GitHub: **Releases → Draft a new release**, pick the tag, paste the changelog entry, mark it as a **pre-release** (it's a beta), and attach the APK.

## After release

- [ ] Install the release APK on a clean device and check the launcher shows "ServerDr"
- [ ] Confirm saved data survives an upgrade install from the previous beta