# Making the Nexora Server Public

Right now Django only listens on your own machine (`127.0.0.1:8000`). Here are your
options, from easiest to most production-grade.

---

## Option 0 — LAN only (test from your phone, same Wi-Fi)

```
python manage.py runserver 0.0.0.0:8000
```

Allow port 8000 through Windows Firewall (first launch will prompt — click Allow),
then any device on your Wi-Fi can reach `http://<your-pc-ip>:8000/api/`
(find the IP with `ipconfig`).

Point the app at it:

```
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
```

Nothing about this is secure — LAN testing only.

---

## Option 1 — Free public tunnel (fastest way to go truly public, no deploy)

Run the tunnel and get a real HTTPS URL that forwards to your local Django:

- **cloudflared** (no signup): `cloudflared tunnel --url http://localhost:8000`
- **ngrok** (free account): `ngrok http 8000`

You get something like `https://abc123.trycloudflare.com`. Then:

```
flutter run --dart-define=API_BASE_URL=https://abc123.trycloudflare.com/api
```

Notes:
- No Django settings changes needed — the tunnel preserves the Host header.
- The URL changes on restart (free tier). The Flutter `--dart-define` makes switching painless.
- Your PC must stay on and running for the server to be reachable.

---

## Option 2 — Real deployment on a VPS (Hetzner/DigitalOcean/AWS, ~$4–6/mo)

For 24/7 uptime on a proper domain:

1. Rent a small Linux VPS, install Python, Nginx, and (recommended) PostgreSQL.
2. Copy the project over, create a virtualenv, `pip install -r requirements.txt`.
3. Set production environment variables (never keep the dev defaults):

   ```
   export DJANGO_SECRET_KEY="<long random string>"
   export DJANGO_DEBUG=False
   export DJANGO_ALLOWED_HOSTS=api.yourdomain.com
   export DJANGO_CORS_ORIGINS=https://your-frontend-domain.com
   ```

   The settings file now reads all of these from the environment — `DEBUG=False`
   is what stops Django from leaking error pages to strangers.
4. Collect static files and migrate:

   ```
   python manage.py migrate
   python manage.py collectstatic
   ```
5. Run the app with **Gunicorn** behind **Nginx**
   (Nginx also serves `/media/` — profile pictures — and `/static/`).
6. HTTPS via **Let's Encrypt / certbot** — mandatory; tokens must never travel over plain HTTP.

Install `gunicorn` and `whitenoise` (`pip install gunicorn whitenoise`) — they're not
in requirements.txt yet.

---

## Option 3 — Managed platforms (zero server babysitting)

- **Render / Railway / Fly.io**: point them at the repo, set the env vars above,
  add a persistent disk for `db.sqlite3` + `media/` (or switch to their managed
  Postgres), deploy. Free tiers exist but sleep when idle.
- **PythonAnywhere**: simplest Django hosting; free tier can't do custom domains.

---

## Hardening checklist before strangers can reach it

| Setting | Dev | Public |
|---|---|---|
| `DEBUG` | True | **False** (error pages leak source paths) |
| `SECRET_KEY` | hardcoded fallback | **env var** — it signs all auth tokens |
| `ALLOWED_HOSTS` | `[]` | **your domain** (blocks Host-header attacks) |
| CORS | allow all | **your frontend origin(s) only** |
| Database | sqlite | Postgres for any real traffic |
| Admin page | open | strong password + HTTPS only |
| Backups | none | daily copy of the DB file / managed DB |

## The one thing to remember

The Flutter side now reads the server address at build time:

```
flutter build windows --dart-define=API_BASE_URL=https://your-domain.com/api
flutter run --dart-define=API_BASE_URL=https://abc123.trycloudflare.com/api
```

No `--dart-define` → defaults to `http://127.0.0.1:8000/api` → your own machine.
