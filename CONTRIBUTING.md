# Contributing to Olilo Status

Thanks for helping improve Olilo Status. This repository contains the iOS app,
Android app, widgets, store assets, and the notifications backend, so the best
contributions are focused, easy to review, and clear about which part of the
project they affect.

## Ways to contribute

- Report bugs with the device, OS version, app version, and reproduction steps.
- Improve accessibility, reliability, performance, and documentation.
- Propose small feature changes that fit the app's status-first purpose.
- Help test iOS, Android, widgets, and push notifications on real devices.

If you want to work on a larger change, open an issue or merge request early so
the approach can be discussed before a lot of code is written.

## Repository layout

- `iOS/Olilo Status` - SwiftUI iOS app.
- `iOS/Olilo Status Widget` - WidgetKit extension.
- `android` - Kotlin and Jetpack Compose Android app.
- `android/app/src/main/java/uk/co/olilo/status/widget` - Android widgets.
- `Backend` - Node.js notifications service for APNs and FCM.
- `App Store` - iOS store screenshots and assets.
- `Play Store` - Android store screenshots and assets.

## Getting started

Clone the repository, create a branch from the default branch, and keep your
change scoped to one concern.

```sh
git clone https://gitlab.com/team-olilo/status-app.git
cd status-app
git checkout -b your-change-name
```

Do not commit local credentials, signing keys, provisioning profiles, generated
build output, or editor state.

## iOS development

Requirements:

- Xcode 26.0+

Setup:

1. Open `iOS/Olilo Status.xcodeproj` in Xcode.
2. Select the `Olilo Status` scheme for the app or the widget scheme for widget
   work.
3. Build and run on a simulator or device.

Before submitting iOS changes, build the affected scheme in Xcode and manually
check the relevant screens, notification settings, widgets, or support links.

## Android development

Requirements:

- Android Studio
- JDK 17
- Android SDK matching the project configuration

Setup:

1. Open the `android` directory in Android Studio.
2. Let Gradle sync the `OliloStatusAndroid` project.
3. Run the `app` configuration on an emulator or device.

Useful command-line checks:

```sh
cd android
./gradlew :app:assembleDebug
./gradlew lintDebug
```

The Android package is `uk.co.olilo.status`. Release signing and Google Play
publishing are driven by environment variables; see `android/RELEASING.md` for
release details.

## Backend development

Requirements:

- Node.js 20+
- PostgreSQL, or Docker for the bundled compose setup

Local setup:

```sh
cd Backend
npm install
cp .env.example .env
npm run migrate
npm run dev
```

Docker setup:

```sh
cd Backend
cp .env.example .env
mkdir -p secrets
docker compose up --build
```

Useful backend commands:

```sh
npm run migrate
npm run cli -- devices
npm run cli -- stats
```

The backend uses environment variables for APNs, FCM, database, and API key
configuration. Keep real `.env` files, APNs keys, Firebase service-account JSON,
and other secrets out of commits.

## Coding guidelines

- Follow the style and structure already used in the area you are changing.
- Keep user-facing copy concise and consistent with the existing app tone.
- Prefer native platform patterns for SwiftUI, WidgetKit, Jetpack Compose, and
  Android widgets.
- Keep backend changes explicit and easy to trace through routes, services,
  repositories, and migrations.
- Add or update documentation when behavior, setup, configuration, or release
  steps change.
- Avoid unrelated formatting or refactors in feature and bug-fix merge requests.

## Testing expectations

Run the checks that match the part of the project you changed:

- iOS: build the affected Xcode scheme and manually verify the changed flow.
- Android: run `./gradlew :app:assembleDebug` and `./gradlew lintDebug` from
  `android`.
- Backend: run migrations and exercise the changed route, CLI command, poller,
  or push-notification path locally.
- Documentation/assets: preview Markdown or generated assets before submitting.

If a check cannot be run, mention that in the merge request along with the
reason.

## Merge request checklist

Before opening a merge request:

- Rebase or merge the latest default branch.
- Make sure the change is limited to the intended files.
- Confirm no secrets or local machine files are included.
- Run the relevant checks listed above.
- Describe what changed, why it changed, and how it was tested.
- Include screenshots or screen recordings for visible UI changes.

## Security and privacy

Please do not open public issues or merge requests containing secrets, private
tokens, signing keys, user data, or operational credentials. If you discover a
security issue, contact the maintainers privately before sharing details.

## Contributor credits

The app includes a contributors list. After contributing a meaningful amount to
the project, you can ask to be added. This is opt-in for privacy reasons.

