# FaithPark Public Deploy And Sharing

Use this flow if you want testers in the United States or Canada to use the app from anywhere.

## 1. What gets deployed

Only the backend gets deployed publicly.

Deploy this folder:

`backend/`

Keep these API keys on the backend only:

- `TOMTOM_API_KEY`
- `API_BIBLE_KEY`
- `API_BIBLE_BIBLE_ID`

Do not put those keys in the Flutter client.

## 2. Easiest public backend option

This repo now includes:

- `render.yaml`
- `backend/.env.example`

That makes Render the simplest path.

## 3. Put the project on GitHub

From the project root:

```powershell
cd C:\Users\Administrator\Documents\toronto_ai_parking_agent_starter\toronto_ai_parking_agent
git init
git add .
git commit -m "Prepare FaithPark for public backend deploy"
```

Then create a GitHub repo and push it.

## 4. Deploy backend on Render

1. Sign in to Render.
2. Create a new Web Service from your GitHub repo.
3. Render should detect `render.yaml` automatically.
4. Confirm the service uses:
   - Root directory: `backend`
   - Build command: `npm install`
   - Start command: `npm start`

## 5. Set Render environment variables

Add these in the Render dashboard:

```env
HOST=0.0.0.0
CORS_ORIGIN=*
TOMTOM_API_KEY=your_tomtom_api_key_here
API_BIBLE_KEY=your_api_bible_key_here
API_BIBLE_BIBLE_ID=your_chinese_bible_id_here
```

`API_BIBLE_KEY` and `API_BIBLE_BIBLE_ID` are optional.
If you leave them empty, traffic still works. Chinese daily verse fallback may be limited.

## 6. Test the public backend

After deploy, Render gives you a URL like:

`https://faithpark-backend.onrender.com`

Open:

`https://faithpark-backend.onrender.com/api/health`

You should see JSON with:

- `"ok": true`
- `"trafficConfigured": true`

## 7. Build the release APK

Replace the URL below with your real Render URL:

```powershell
cd C:\Users\Administrator\Documents\toronto_ai_parking_agent_starter\toronto_ai_parking_agent
flutter build apk --release --dart-define=TRAFFIC_API_BASE_URL=https://faithpark-backend.onrender.com
```

The APK will be created here:

`build\app\outputs\flutter-apk\app-release.apk`

## 8. Share the APK

Upload this file to Google Drive:

`build\app\outputs\flutter-apk\app-release.apk`

Tell testers to:

1. Download the APK
2. Allow install from unknown sources
3. Install the app
4. Allow:
   - location
   - notifications
   - camera
   - microphone if using the agent speech input

## 9. Important notes

- If you rebuild the APK with a different backend URL, testers need the new APK.
- Traffic depends on your backend being online.
- The Flutter app never needs the TomTom key directly.
