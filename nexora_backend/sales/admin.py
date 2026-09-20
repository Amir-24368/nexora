from django.contrib import admin

from .models import Sale, SaleItem


class SaleItemInline(admin.TabularInline):
    model = SaleItem
    extra = 1


@admin.register(Sale)
class SaleAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "customer",
        "total_amount",
        "sale_date",
    )

    list_filter = (
        "sale_date",
    )

    search_fields = (
        "customer__name",
        "customer__email",
    )

    inlines = [
        SaleItemInline,
    ]


@admin.register(SaleItem)
class SaleItemAdmin(admin.ModelAdmin):

    list_display = (
        "sale",
        "product",
        "quantity",
        "price",
    )

    search_fields = (
        "product__name",
    )