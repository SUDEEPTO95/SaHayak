# SaHayak

Folders match the three tiers so you always know where to look:

| Folder | What you will find |
|---|---|
| **frontend/** | Flutter app, website. Screens, icons, maps UI. **No** matching, **no** database. |
| **middleware/** | Public **`/v1` API** (auth, DTO, rate limits). The only thing frontend calls. |
| **backend/** | Laravel domain, AI/LangGraph, later Postgres. **Not** called from Flutter. |

Also at root: `config/` (product JSON), `infra/` (Docker). Partner brief: `G:\SaHayak_Partnership_Brief.docx` (and `.pdf`).

Citizen home is only **Need blood** and **I can donate**. Line under the name: **blood help nearby** (like a bank’s “net banking” line).

Website: http://127.0.0.1:8080/app/ · Console: /console · Family guest: /guest/&lt;token&gt; · Privacy: /privacy

Sign-in lasts across refresh (web localStorage / app saved token). Data is saved in `middleware/data/store.json` so a restart does not wipe the demo.

## Quick start (middleware)

```text
cd middleware
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8080
```

- API docs: http://127.0.0.1:8080/docs  
- Citizen web: http://127.0.0.1:8080/app/  
- Org console + OSM: http://127.0.0.1:8080/console  

Owner login: `owner@sahayak.local` (dev OTP is returned in JSON). Donors never pay for SOS.

Flutter SDK (this machine): `G:\tools\flutter`. App: `frontend/mobile`. PHP: `G:\tools\php\php.exe`.
