#!/usr/bin/env bash
# Render build script -- runs on every deploy.
set -o errexit

python -m pip install --upgrade pip
pip install -r requirements.txt

python manage.py collectstatic --no-input
python manage.py migrate

# One-time convenience: create the owner/superuser if none exists.
# Credentials come from env vars set in the Render dashboard.
# NOTE: a bare `python -` script must point Django at its settings module
# (manage.py does this automatically; a heredoc does not).
python - <<'EOF' || echo "WARNING: superuser step failed (see traceback above) - create the superuser via the Django admin shell instead; deploy continues."
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
import django

django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()
if not User.objects.filter(is_superuser=True).exists():
    User.objects.create_superuser(
        email=os.environ.get('RENDER_SUPERUSER_EMAIL', 'admin@example.com'),
        username=os.environ.get('RENDER_SUPERUSER_EMAIL', 'admin'),
        password=os.environ.get('RENDER_SUPERUSER_PASSWORD', 'changeme123'),
    )
    print('Superuser created.')
else:
    print('Superuser already exists.')
EOF
