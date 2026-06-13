# Olilo Status

Olilo Status the open source status app for the Olilo ISP in the UK & Ireland. It gives the community a fast, live view of network health, active incidents, planned maintenance, historical notices, and support links across iOS and Android platforms.

## Screenshots

### iOS

<p>
  <img src="App%20Store/olilo-ios-1.png" width="180" alt="Olilo Status iOS screenshot 1">
  <img src="App%20Store/olilo-ios-2.png" width="180" alt="Olilo Status iOS screenshot 2">
</p>

### Android

<p>
  <img src="Play%20Store/olilo-android-1.png" width="180" alt="Olilo Status Android screenshot 1">
  <img src="Play%20Store/olilo-android-2.png" width="180" alt="Olilo Status Android screenshot 2">
</p>

## Features

- Live overview of the Olilo Network.
- Service and component health grouped by status.
- Active incident and maintenance cards with direct links to status updates.
- Notice history with filters for incidents and maintenance.
- Direct contact links for the Olilo Teams official Discord and Reddit channels.
- iOS & Android home screen widget showing whether the Olilo network is online (choose your network Openreach, CityFibre & Freedom Fibre).
- Native SwiftUI iOS app and native Kotlin/Jetpack Compose Android app.

## Repository

This repository contains the source for Olilo Status. The project is public so users can inspect how the app works, report issues, propose improvements, and build their own local copy.

Current app areas include:

- `iOS/Olilo Status` - SwiftUI iOS app.
- `iOS/Olilo Status Widget` - WidgetKit extension.
- `android` - Kotlin/Jetpack Compose Android app.
- `android/app/src/main/java/uk/co/olilo/status` - WidgetProvider.
- `App Store` - iOS screenshots and store assets.
- `Play Store` - Android screenshots and store assets.

## iOS Development

Requirements:

- Xcode 26.0+

To work on the iOS app:

1. Open `iOS/Olilo Status.xcodeproj` in Xcode.
2. Select the `Olilo Status` scheme.
3. Build and run the app on a simulator or device.

## Android Development

Requirements:

- Android Studio
- JDK 17
- Android SDK matching the project configuration

To work on the Android app:

1. Open the `android` directory in Android Studio.
2. Let Gradle sync the `OliloStatusAndroid` project.
3. Run the `app` configuration on an emulator or device.

From the command line, you can build a debug APK with:

```sh
cd android
./gradlew :app:assembleDebug
```

The Android app package is `uk.co.olilo.status` and uses Kotlin, Jetpack Compose, Material 3, Navigation Compose, coroutines, and Kotlin serialization.

## Contributing

Contributions are welcome. Keep changes focused, follow the existing SwiftUI structure, and include enough context in merge requests for reviewers to understand the behavior change.

Useful areas for contributions include:

- Accessibility improvements.
- Status display refinements.
- Widget improvements.
- Documentation updates.
- Bug reports with device, OS version, and reproduction steps.

## Support and Community

- GitLab: https://gitlab.com/team-olilo/status-app
- Discord: https://discord.gg/olilo
- Reddit: https://www.reddit.com/r/Olilo
- Olilo: https://olilo.co.uk

## License

Olilo Status is open source under the GNU General Public License v3.0. See `LICENSE` for the full license text.
