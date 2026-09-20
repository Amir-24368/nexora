from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):

    list_display = (
        "username",
        "email",
        "first_name",
        "last_name",
        "role",
        "shop",
        "is_active",
    )

    # Ensure we produce a list (not a tuple) to satisfy type checkers when
    # concatenating with UserAdmin.fieldsets
    fieldsets = list(UserAdmin.fieldsets or []) + [
        (
            "Nexora Information",
            {
                "fields": (
                    "role",
                    "shop",
                )
            }
        ),
    ]