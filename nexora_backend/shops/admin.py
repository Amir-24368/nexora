from django.contrib import admin
from .models import Shop


@admin.register(Shop)
class ShopAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "name",
        "owner",
        "created_at",
    )

    search_fields = (
        "name",
        "owner__username",
    )

    list_filter = (
        "created_at",
    )

    ordering = (
        "-created_at",
    )