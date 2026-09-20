from django.contrib import admin

from .models import (
    Supplier,
    PurchaseOrder,
    PurchaseOrderLine,
)


# ==========================================================
# Purchase Order Lines
# ==========================================================

class PurchaseOrderLineInline(admin.TabularInline):
    model = PurchaseOrderLine
    extra = 1


# ==========================================================
# Supplier Admin
# ==========================================================

@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):

    list_display = (
        "name",
        "company_name",
        "phone",
        "email",
        "country",
        "city",
        "rating",
        "delivery_days",
        "is_active",
    )

    search_fields = (
        "name",
        "company_name",
        "email",
        "phone",
        "contact_person",
    )

    list_filter = (
        "country",
        "city",
        "is_active",
    )

    ordering = (
        "name",
    )


# ==========================================================
# Purchase Order Admin
# ==========================================================

@admin.register(PurchaseOrder)
class PurchaseOrderAdmin(admin.ModelAdmin):

    inlines = [
        PurchaseOrderLineInline,
    ]

    list_display = (
        "id",
        "supplier",
        "status",
        "total",
        "expected_delivery",
        "received_date",
        "created_by",
        "created_at",
    )

    search_fields = (
        "id",
        "supplier__name",
    )

    list_filter = (
        "status",
        "supplier",
        "created_at",
    )

    readonly_fields = (
        "created_at",
        "updated_at",
    )

    date_hierarchy = "created_at"


# ==========================================================
# Purchase Order Line Admin
# ==========================================================

@admin.register(PurchaseOrderLine)
class PurchaseOrderLineAdmin(admin.ModelAdmin):

    list_display = (
        "purchase_order",
        "product",
        "ordered_quantity",
        "received_quantity",
        "purchase_price",
        "subtotal",
    )

    search_fields = (
        "purchase_order__id",
        "product__name",
    )

    list_filter = (
        "purchase_order",
    )