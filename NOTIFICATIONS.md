# Notifications - Developer Guide

Push notifications for Olilo Status: a Node.js backend watches the Olilo status
page and pushes alerts to the iOS and Android apps. **Start here** to find your
way around; the deep detail lives in the linked docs.

## How it fits together

```
status.olilo.co.uk            Backend (Node.js)              Apps
  v3/summary.json    --poll-->  diff vs. Postgres  --push-->  APNs -> iOS
  v3/components.json            detect changes               FCM  -> Android
                                target by preference
```

The backend polls the status page every minute, diffs each poll against state in
PostgreSQL, and sends targeted pushes for new incidents, status updates,
resolutions, scheduled maintenance, and component health changes. Devices
register a push token and their preferences; the backend handles delivery and
prunes dead tokens automatically.

## Where everything lives

| Area | Path | Docs |
| --- | --- | --- |
| Backend service | [`Backend/`](Backend/) | [`Backend/README.md`](Backend/README.md) |
| Client integration (both platforms) | - | [`Backend/CLIENTS.md`](Backend/CLIENTS.md) |
| iOS client code | `iOS/Olilo Status/Notifications/` | see below |
| Android client code | `android/app/src/main/java/uk/co/olilo/status/notifications/` | see below |

**iOS files** (add both to the `Olilo Status` target):
- `OliloNotifications.swift` - API client, preferences, `PushManager`, app delegate.
- `NotificationSettingsView.swift` - optional ready-made settings screen.

**Android files** (package `uk.co.olilo.status.notifications`):
- `NotificationPreferences.kt` - preferences model + storage.
- `OliloNotifications.kt` - opt-in/out + backend client.
- `OliloMessagingService.kt` - FCM service (token rotation + incoming pushes).

## Quick start

### Run the backend locally

```sh
cd Backend
cp .env.example .env          # fill in APNs + FCM credentials
docker compose up --build     # starts Postgres + the app, runs migrations
```

Full setup, configuration, and credential instructions:
[`Backend/README.md`](Backend/README.md).

### Wire up the apps

The integration steps - capabilities, Gradle/manifest changes, entry-point
wiring, and the opt-in calls - are in [`Backend/CLIENTS.md`](Backend/CLIENTS.md).
The short version:

- **iOS:** add the 2 files, enable the Push Notifications capability, attach
  `@UIApplicationDelegateAdaptor(PushAppDelegate.self)`, and link
  `NotificationSettingsView` from Settings.
- **Android:** add Firebase (`google-services.json` + 2 Gradle lines + a manifest
  `<service>`), then call `OliloNotifications.enable(context)` after the user
  grants the notification permission.

Set the backend URL (and optional API key) in `OliloNotificationConfig` (iOS) and
`OliloNotifications` (Android).

## API summary

All `/api/*` routes require the `x-api-key` header when `API_KEY` is set.

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/api/devices/register` | Register/refresh a device token + preferences |
| `PATCH` | `/api/devices/:token/preferences` | Update preferences |
| `DELETE` | `/api/devices/:token` | Stop delivery to a device |
| `POST` | `/api/poll` | Force an immediate poll (testing/webhooks) |
| `GET` | `/health` | Liveness probe (no auth) |

Request/response shapes: [`Backend/README.md`](Backend/README.md#api).

## Preferences

Each device stores the same preference shape on every platform:

```jsonc
{
  "incidents": true,        // new incidents + updates + resolutions
  "maintenance": true,      // scheduled maintenance
  "componentAlerts": false, // per-component status changes
  "networks": ["Openreach", "CityFibre", "Freedom Fibre"] // filters incident, maintenance and component alerts; empty = all
}
```

## Notification payload

Pushes carry a `data` block for deep-linking:

| Key | Values |
| --- | --- |
| `type` | `incident` \| `maintenance` \| `component` |
| `incidentId` | upstream id |
| `url` | status-page URL to open (when available) |

Both client handlers open `url` on tap by default - swap in in-app routing when
ready.

## Testing tips

- **APNs needs a real device** - the iOS Simulator does not receive push. Use the
  sandbox backend (`APNS_PRODUCTION=false`) for development/TestFlight builds.
- Hit `POST /api/poll` to trigger a poll immediately instead of waiting for the
  interval.
- The first poll against an empty database seeds state silently, so a fresh
  deploy never sends a backlog of pre-existing incidents.
