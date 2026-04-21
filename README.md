# Toronto AI Parking Agent Starter

A Flutter starter app for:
- save parking location
- parking countdown reminders
- daily reminders
- Toronto + Canada news spoken in Cantonese or English
- simple smart assistant command routing

## Quick start

```bash
flutter pub get
flutter run
```

## Traffic backend

TomTom is used for traffic only, and should live on the server side.
Parking location retrieval in the app uses device geolocation, while map viewing and walking directions open in Google Maps.

Backend setup:

```bash
cd backend
npm install
cp .env.example .env
```

Set your server environment variable:

```env
TOMTOM_API_KEY=your_tomtom_api_key_here
```

Run backend locally:

```bash
cd backend
npm run dev
```

Run Flutter web against that backend:

```bash
flutter run -d chrome --dart-define=TRAFFIC_API_BASE_URL=http://localhost:3002
```

Run Flutter on an Android phone over USB:

```bash
adb reverse tcp:3002 tcp:3002
flutter run -d <your-device-id> --dart-define=TRAFFIC_API_BASE_URL=http://localhost:3002
```

If you want phone testing over Wi-Fi instead of USB:

```bash
ipconfig
flutter run -d <your-device-id> --dart-define=TRAFFIC_API_BASE_URL=http://YOUR_COMPUTER_IP:3002
```

Notes for mobile traffic:
- the backend now listens on `0.0.0.0` by default, so LAN devices can reach it
- USB testing is easiest with `adb reverse`
- if live traffic works in Chrome but not on phone, the most common cause is the phone pointing at its own `localhost` instead of your computer

For deployed testing:
- put `TOMTOM_API_KEY` only on the backend host
- point the Flutter app to your deployed backend URL with `TRAFFIC_API_BASE_URL`
- do not expose the TomTom key in the client

## Public sharing

If you want testers in other US or Canada regions to use the app:

1. deploy the backend publicly
2. build a release APK against that public backend URL
3. share the release APK

Files prepared for that flow:

- `render.yaml`
- `backend/.env.example`
- `DEPLOY_AND_SHARE.md`

## Notes

This starter is intentionally lightweight:
- uses `SharedPreferences` for easy setup
- uses live RSS/API-ready news service
- uses `speech_to_text` for short commands
- uses `flutter_tts` for spoken output
- uses `flutter_local_notifications` for local reminders

## Recommended next upgrades
- replace `SharedPreferences` with Isar
- add RSS parser package or backend summarizer
- add background refresh worker
- add real Toronto parking feed integration
