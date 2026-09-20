from django.contrib import admin
from .models import Inventory, InventoryMovement


@admin.register(Inventory)
class InventoryAdmin(admin.ModelAdmin):
    """Admin configuration for Inventory model."""
    
    list_display = ['product', 'quantity', 'shop']
    list_filter = ['shop']
    search_fields = ['product__name', 'product__sku']
    ordering = ['product__name']  # or ['-id']


@admin.register(InventoryMovement)
class InventoryMovementAdmin(admin.ModelAdmin):
    """Admin configuration for InventoryMovement (transaction log)."""
    
    list_display = ['product', 'change_type', 'quantity', 'shop']
    list_filter = ['change_type', 'shop']
    search_fields = ['product__name', 'product__sku', 'reference_id']
    ordering = ['-id']  # simplest ordering