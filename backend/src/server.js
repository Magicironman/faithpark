const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 3002);
const host = process.env.HOST || '0.0.0.0';
const corsOrigin = process.env.CORS_ORIGIN || '*';
const tomTomApiKey = process.env.TOMTOM_API_KEY || '';
const apiBibleKey = process.env.API_BIBLE_KEY || '';
const apiBibleBibleId = process.env.API_BIBLE_BIBLE_ID || '';

app.use(cors({ origin: corsOrigin === '*' ? true : corsOrigin }));
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

app.get('/', (_req, res) => {
  res.type('html').send(`<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>FaithPark APK Download</title>
    <style>
      :root {
        color-scheme: light;
        --green: #123f29;
        --gold: #d99b36;
        --cream: #fff8ed;
        --ink: #17231b;
      }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        min-height: 100vh;
        font-family: Arial, sans-serif;
        background: linear-gradient(145deg, var(--green), #0b2417 55%, #241425);
        color: white;
        display: grid;
        place-items: center;
        padding: 24px;
      }
      main {
        width: min(720px, 100%);
        background: rgba(255, 248, 237, 0.96);
        color: var(--ink);
        border-radius: 28px;
        padding: 32px;
        box-shadow: 0 24px 80px rgba(0, 0, 0, 0.35);
      }
      .brand {
        color: var(--gold);
        font-size: 13px;
        font-weight: 800;
        letter-spacing: 0.24em;
        text-transform: uppercase;
      }
      h1 {
        margin: 8px 0 10px;
        font-size: clamp(34px, 7vw, 58px);
        line-height: 1;
      }
      p {
        font-size: 18px;
        line-height: 1.55;
      }
      .download {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        margin: 18px 0;
        min-height: 58px;
        padding: 0 28px;
        border-radius: 999px;
        background: var(--green);
        color: white;
        text-decoration: none;
        font-size: 18px;
        font-weight: 800;
      }
      .note {
        background: white;
        border-left: 5px solid var(--gold);
        border-radius: 16px;
        padding: 16px;
        color: #425247;
      }
    </style>
  </head>
  <body>
    <main>
      <div class="brand">FaithPark</div>
      <h1>Download Android APK</h1>
      <p>Install the FaithPark test app for parking reminders, parked-car photos, Cantonese voice alerts, daily Bible verses, weather, and live traffic.</p>
      <a class="download" href="/app-release.apk" download>Download FaithPark APK</a>
      <div class="note">
        After downloading, Android may ask you to allow installation from unknown sources. After install, allow location, notifications, camera, and microphone if you want to use voice features.
      </div>
    </main>
  </body>
</html>`);
});

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'toronto-ai-parking-agent-backend',
    host,
    port,
    trafficConfigured: tomTomApiKey.length > 0,
    scriptureConfigured: apiBibleKey.length > 0 && apiBibleBibleId.length > 0,
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/traffic', async (req, res) => {
  const latitude = Number(req.query.lat);
  const longitude = Number(req.query.lng);
  const radiusMiles = Number(req.query.radius || 10);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return res.status(400).json({
      error: 'lat and lng query parameters are required numbers.',
    });
  }

  if (!tomTomApiKey) {
    return res.status(503).json({
      radiusMiles,
      incidents: [],
      fetchedAt: new Date().toISOString(),
      isAvailable: false,
      error: 'Traffic API key is not configured on the server.',
    });
  }

  try {
    const bbox = buildBoundingBox({
      latitude,
      longitude,
      radiusMiles,
    });

    const tomTomUrl = new URL('https://api.tomtom.com/traffic/services/5/incidentDetails');
    tomTomUrl.searchParams.set('key', tomTomApiKey);
    tomTomUrl.searchParams.set('bbox', bbox);
    tomTomUrl.searchParams.set(
      'fields',
      '{incidents{type,geometry{type,coordinates},properties{iconCategory,events{description,code},from,to,length,delay,roadNumbers,timeValidity}}}',
    );
    tomTomUrl.searchParams.set('language', 'en-GB');
    tomTomUrl.searchParams.set('timeValidityFilter', 'present');

    const response = await fetch(tomTomUrl);
    const text = await response.text();

    if (!response.ok) {
      return res.status(response.status).json({
        error: 'TomTom traffic request failed.',
        details: text,
      });
    }

    const payload = JSON.parse(text);
    const incidents = Array.isArray(payload.incidents)
      ? payload.incidents.map(parseIncident).filter(Boolean)
      : [];

    incidents.sort((a, b) => b.delayMinutes - a.delayMinutes);

    return res.json({
      radiusMiles,
      incidents,
      fetchedAt: new Date().toISOString(),
      isAvailable: true,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Unable to load traffic data.',
      details: error instanceof Error ? error.message : String(error),
    });
  }
});

app.get('/api/scripture/lookup', async (req, res) => {
  const reference = String(req.query.reference || '').trim();
  if (!reference) {
    return res.status(400).json({
      error: 'reference query parameter is required.',
    });
  }

  if (!apiBibleKey || !apiBibleBibleId) {
    return res.status(503).json({
      reference,
      textZhHant: '',
      isAvailable: false,
      error: 'API.Bible is not configured on the server.',
    });
  }

  try {
    const textZhHant = await lookupChineseScripture(reference);
    return res.json({
      reference,
      textZhHant,
      isAvailable: textZhHant.length > 0,
      source: 'API.Bible',
    });
  } catch (error) {
    return res.status(500).json({
      reference,
      textZhHant: '',
      isAvailable: false,
      error: 'Unable to load scripture text.',
      details: error instanceof Error ? error.message : String(error),
    });
  }
});

app.listen(port, host, () => {
  console.log(`Toronto AI backend listening on http://${host}:${port}`);
  console.log(`Local browser: http://localhost:${port}`);
  console.log(`LAN / phone access: use your computer IP with port ${port}`);
});

async function lookupChineseScripture(reference) {
  const searchUrl = new URL(`https://api.scripture.api.bible/v1/bibles/${apiBibleBibleId}/search`);
  searchUrl.searchParams.set('query', reference);
  searchUrl.searchParams.set('limit', '1');
  searchUrl.searchParams.set('sort', 'relevance');

  const searchResponse = await fetch(searchUrl, {
    headers: {
      'api-key': apiBibleKey,
      accept: 'application/json',
    },
  });

  const searchText = await searchResponse.text();
  if (!searchResponse.ok) {
    throw new Error(`API.Bible search failed: ${searchResponse.status} ${searchText}`);
  }

  const searchPayload = JSON.parse(searchText);
  const passages = Array.isArray(searchPayload?.data?.passages) ? searchPayload.data.passages : [];
  if (passages.length === 0) {
    return '';
  }

  const firstPassage = passages[0];
  const content = typeof firstPassage.content === 'string' ? firstPassage.content : '';
  return stripHtml(content);
}

function parseIncident(raw) {
  if (!raw || typeof raw !== 'object') {
    return null;
  }

  const properties = raw.properties || {};
  const events = Array.isArray(properties.events) ? properties.events : [];
  const firstEvent = events.length > 0 && typeof events[0] === 'object' ? events[0] : {};
  const roadNumbers = Array.isArray(properties.roadNumbers)
    ? properties.roadNumbers.filter(Boolean).join(', ')
    : '';

  const pieces = [
    stringOrEmpty(firstEvent.description),
    roadNumbers,
    stringOrEmpty(properties.from),
    stringOrEmpty(properties.to),
  ].filter(Boolean);

  return {
    title: pieces.length > 0 ? pieces.join(' | ') : 'Traffic incident nearby',
    category: trafficCategoryLabel(Number(properties.iconCategory || 0)),
    delayMinutes: Math.round(Number(properties.delay || 0) / 60),
  };
}

function trafficCategoryLabel(iconCategory) {
  switch (iconCategory) {
    case 4:
      return 'Jam';
    case 5:
      return 'Road closed';
    case 7:
      return 'Road works';
    case 8:
      return 'Lane closed';
    case 9:
      return 'Incident';
    case 10:
      return 'Broken down vehicle';
    case 11:
      return 'Accident';
    case 14:
      return 'Weather';
    default:
      return 'Traffic';
  }
}

function buildBoundingBox({ latitude, longitude, radiusMiles }) {
  const latDelta = radiusMiles / 69.0;
  const lonDivider = 69.0 * Math.abs(Math.cos((latitude * Math.PI) / 180));
  const lonDelta = lonDivider === 0 ? latDelta : radiusMiles / lonDivider;

  const minLon = longitude - lonDelta;
  const minLat = latitude - latDelta;
  const maxLon = longitude + lonDelta;
  const maxLat = latitude + latDelta;

  return [minLon, minLat, maxLon, maxLat].map((value) => value.toFixed(5)).join(',');
}

function stripHtml(value) {
  return value
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function stringOrEmpty(value) {
  return typeof value === 'string' ? value.trim() : '';
}
