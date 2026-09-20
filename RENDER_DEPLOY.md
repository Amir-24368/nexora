# Deploy Nexora to Render (Free) — Step by Step

Zero-cost test deployment: **Render free web service + free Postgres**.
Takes ~15 minutes. The URL you get is real HTTPS, reachable from anywhere —
your Flutter app just points at it.

What free gets you (and its catches):
- Web service: free forever, but **sleeps after 15 min idle** and takes ~1 min
  to wake on the next request (first login of the day feels slow — that's it).
- Postgres: free, 1 GB, **expires after 30 days** — for a test, just create a
  new one when it expires (or upgrade to the $6/mo plan for persistence).

---

## Step 0 — Push this repo to GitHub

Render pulls your code from GitHub. From the project root:

```bash
git remote add origin https://github.com/<your-username>/nexora.git
git push -u origin main
```

(The repo is already initialized and committed.)

## Step 1 — Create the Render account + Postgres

1. Sign up at https://render.com (GitHub login is easiest).
2. Dashboard → **New +** → **Postgres**.
3. Name: `nexora-db`, Region: pick the closest to you (e.g. Frankfurt), Plan: **Free**.
4. Click **Create Database**. Wait for it to go live (~1 min).
5. Open the database page → copy the **Internal Database URL** (starts with
   `postgres://`, contains `sslmode=require`). Keep this tab open.

## Step 2 — Create the web service

1. Dashboard → **New +** → **Web Service**.
2. Connect your GitHub account when prompted, then pick the `nexora` repo.
3. Fill in:
   - **Name**: `nexora-api`
   - **Region**: same as the database
   - **Root Directory**: `nexora_backend`
   - **Runtime**: Python 3
   - **Build Command**: `bash build.sh`
   - **Start Command**: `gunicorn core.wsgi:application --chdir . --bind 0.0.0.0:$PORT`
4. Choose instance type **Free**.

## Step 3 — Environment variables (the important part)

On the web service page → **Environment** → add these:

| Key | Value |
|---|---|
| `DATABASE_URL` | the Internal Database URL from Step 1 |
| `DJANGO_DEBUG` | `False` |
| `DJANGO_SECRET_KEY` | any long random string (e.g. from `python -c "import secrets; print(secrets.token_urlsafe(64))"`) |
| `DJANGO_ALLOWED_HOSTS` | `nexora-api.onrender.com` (your service's URL; add `.onrender.com` to allow previews too) |
| `DJANGO_CORS_ORIGINS` | (optional now — the desktop app isn't a browser) |
| `RENDER_SUPERUSER_EMAIL` | your email |
| `RENDER_SUPERUSER_PASSWORD` | a strong password |

Click **Save Changes** → Render redeploys automatically.

## Step 4 — First deploy

Watch the **Events / Logs** tab. `build.sh` runs:
`pip install → collectstatic → migrate → creates your superuser`.

When the log says `Your service is live`, open `https://nexora-api.onrender.com/admin/`
and log in with the superuser email/password from Step 3. Then smoke-test:

```
https://nexora-api.onrender.com/api/auth/login/   (POST from the app)
```

## Step 5 — Point the Flutter app at it

```bash
flutter run --dart-define=API_BASE_URL=https://nexora-api.onrender.com/api
```

Or for a release build:

```bash
flutter build windows --dart-define=API_BASE_URL=https://nexora-api.onrender.com/api
```

Log in with the superuser account (or create users in Django admin first).

---

## Notes & gotchas

- **Cold starts**: after 15 min idle the service sleeps; the next request
  waits ~50s. Ping it once before demoing, or use a free uptime pinger.
- **Free Postgres expires after 30 days**: data is deleted. For a test,
  recreate + redeploy (migrations rebuild the schema). Real fix: $6/mo.
- **Every push to `main` auto-deploys** — change code, `git push`, done.
- **`db.sqlite3`, `media/`, and `venv/` are gitignored** — the cloud DB starts
  empty (no shop, no products). Create the shop + a OWNER-role user in the
  Django admin first, or the API returns "User does not have a shop assigned"
  for non-superuser logins. Superuser logins can pass `shop` id in payloads.
- **Profile pictures** upload to the service's disk, which resets on each
  deploy — acceptable for a test.
- **Secrets stay out of git**: they live only in Render's env vars.
