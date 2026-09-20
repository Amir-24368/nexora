from django.db import models
from core.models import TenantModel


class AnalyticsEvent(TenantModel):
    EVENT_TYPES = [
        ('page_view', 'Page View'),
        ('product_view', 'Product View'),
        ('add_to_cart', 'Add to Cart'),
        ('purchase', 'Purchase'),
        ('search', 'Search'),
    ]

    event_type = models.CharField(max_length=50, choices=EVENT_TYPES)
    customer = models.ForeignKey('customers.Customer', on_delete=models.SET_NULL, null=True, blank=True)
    product = models.ForeignKey('products.Product', on_delete=models.SET_NULL, null=True, blank=True)
    session_id = models.CharField(max_length=100, blank=True, null=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True, null=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta(TenantModel.Meta):
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.event_type} - {self.created_at}"