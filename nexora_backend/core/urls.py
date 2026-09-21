from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static


def health(request):
    """Root endpoint so visiting the server in a browser shows a friendly
    confirmation instead of a 404 -- also handy for uptime pings."""
    return JsonResponse({"status": "ok", "service": "Nexora API", "endpoints": ["/admin/", "/api/"]})


urlpatterns = [
    path("", health),
    path("admin/", admin.site.urls),
    path("api/auth/", include("users.api.urls")),
    path("api/", include("products.api.urls")),
    path("api/", include("sales.api.urls")),
    path("api/", include("customers.api.urls")),
    path("api/", include("suppliers.api.urls")),
    path("api/", include("inventory.api.urls")),
    path("api/", include("shops.api.urls")),   # <-- ADD THIS
    path("api/orders/", include("orders.api.urls")),
]

# Serve uploaded media (avatars etc.). Also on the public server (DEBUG=False)
# so profile pictures keep working -- fine for a test deployment; a real
# production setup would serve media from object storage or a CDN instead.
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)