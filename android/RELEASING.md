# Releasing the Android app (GitLab CI/CD to Google Play)

The GitLab pipeline (`.gitlab-ci.yml` at the repo root) builds a signed Android
App Bundle and uploads it to the Google Play **internal testing** track using
[Gradle Play Publisher](https://github.com/Triple-T/gradle-play-publisher).

- Push to any branch or open a merge request: the `build` job compiles and
  produces a signed `.aab` artifact (no upload).
- Push to the default branch (`main`): the `publish` job builds and uploads to
  internal testing.

The version code for each build is the GitLab pipeline IID
(`CI_PIPELINE_IID`), so it always increases. The version name stays whatever is
set in `app/build.gradle.kts` (`versionName`).

## One-time setup

You only do this once. After that, every push to `main` ships to internal
testing automatically.

### 1. Create the app in the Play Console

Google Play will not accept an API upload until the app exists. In the
[Play Console](https://play.google.com/console): create the app with package
name `uk.co.olilo.status`, and complete the initial setup (app content, data
safety, content rating, target audience). Historically the very first bundle
also had to be uploaded manually before the API would accept uploads; if the
first pipeline upload is rejected, upload one bundle by hand and then let CI take
over.

### 2. Generate an upload keystore

This key signs the bundle. Keep it safe and back it up; losing it means you
cannot ship updates (unless you use Play App Signing key reset).

```sh
keytool -genkeypair -v \
  -keystore upload.keystore \
  -alias olilo-upload \
  -keyalg RSA -keysize 2048 -validity 9125 \
  -storetype JKS
```

Enable **Play App Signing** for the app (Play Console -> Setup -> App signing)
and register this keystore as the upload key. Google then re-signs with the app
signing key it holds.

### 3. Create a Play publishing service account

1. In the Play Console: **Users and permissions -> Invite new users**, or use
   **Setup -> API access** to link a Google Cloud project.
2. In Google Cloud, create a service account and a JSON key for it.
3. Back in the Play Console, grant that service account access with at least
   **Release to testing tracks** (and **Manage production releases** later if you
   promote to production). Account permissions can take a little while to apply.

Download the service-account JSON; you will paste it into a GitLab variable.

### 4. Add the GitLab CI/CD variables

Project **Settings -> CI/CD -> Variables**. Mark them **Protected** (so they are
only exposed on protected branches like `main`) and **Masked** where allowed.

| Variable | Type | Value |
| --- | --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Variable, protected | `base64 -i upload.keystore` output (one line) |
| `ANDROID_KEYSTORE_PASSWORD` | Variable, masked, protected | keystore password |
| `ANDROID_KEY_ALIAS` | Variable, protected | e.g. `olilo-upload` |
| `ANDROID_KEY_PASSWORD` | Variable, masked, protected | key password |
| `PLAY_SERVICE_ACCOUNT_JSON_BASE64` | Variable, masked and hidden, protected | base64 of the service-account JSON |

The credentials are stored base64-encoded (single line) so GitLab can mask and
hide them; the pipeline decodes them back to files at runtime. Produce the values
(macOS shown; on Linux use `base64 -w0 <file>`):

```sh
base64 -i upload.keystore | tr -d '\n'                  # ANDROID_KEYSTORE_BASE64
base64 -i app/play-service-account.json | tr -d '\n'    # PLAY_SERVICE_ACCOUNT_JSON_BASE64
```

> Make sure `main` is a **protected branch** (Settings -> Repository -> Protected
> branches) so the protected variables are available to the `publish` job.

### 5. Push

Push to `main`. Watch the pipeline under **Build -> Pipelines**. On success the
build appears in Play Console -> Testing -> Internal testing.

## Changing the release track

The track is set in `app/build.gradle.kts` in the `play { }` block
(`track.set("internal")`). Valid values: `internal`, `alpha` (closed testing),
`beta` (open testing), `production`. To roll out gradually to production, also
set a staged rollout, for example:

```kotlin
play {
    track.set("production")
    releaseStatus.set(ReleaseStatus.IN_PROGRESS)
    userFraction.set(0.1) // 10 percent
}
```

## Local builds

Local builds keep working without any of the above. With none of the signing
env vars set, `./gradlew bundleRelease` produces an unsigned release bundle and
the publish tasks do nothing. To test signing locally, export
`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and
`ANDROID_KEY_PASSWORD` before running Gradle.

## Notes

- The pipeline installs the Android SDK (`platforms;android-37`,
  `build-tools;37.0.0`) into the build image on first run and caches it. If you
  bump `compileSdk` or build-tools in `app/build.gradle.kts`, update the matching
  variables at the top of `.gitlab-ci.yml`.
- `google-services.json` is committed (it is app configuration, not a secret), so
  the FCM build wiring works in CI without extra variables.
