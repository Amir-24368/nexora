#!/usr/bin/env bash
# Render build script -- runs on every deploy.
set -o errexit

pip install --upgrade pip
pip install -r requirements.txt

python manage.py collectstatic --no-input
python manage.py migrate

# One-time convenience: create the owner/superuser if none exists.
# Credentials come from env vars set in the Render dashboard.
python - <<'EOF'
import os
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
