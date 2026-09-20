from django.contrib import admin
from .models import Customer


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = [
        'full_name',
        'phone',
        'email',
        'total_spent',
        'recency_days',
        'frequency',
        'rfm_segment',
        'shop',
    ]
    list_filter = ['rfm_segment', 'shop']
    search_fields = ['full_name', 'phone', 'email']
    readonly_fields = [
        'recency_days',
        'frequency',
        'monetary',
        'rfm_score',
        'rfm_segment',
        'last_purchase_date',
        'created_at',
        'updated_at',
    ]
    fieldsets = (
        (None, {
            'fields': ('full_name', 'phone', 'email', 'address', 'shop')
        }),
        ('Analytics', {
            'fields': ('total_purchases', 'total_spent', 'last_purchase_date')
        }),
        ('RFM', {
            'fields': ('recency_days', 'frequency', 'monetary', 'rfm_score', 'rfm_segment')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )