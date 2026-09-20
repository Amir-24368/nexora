from django.db import models
from core.models import TenantModel


class AIPrediction(TenantModel):
    PREDICTION_TYPES = [
        ('restock', 'Restock Recommendation'),
        ('sales_forecast', 'Sales Forecast'),
        ('price_suggestion', 'Price Suggestion'),
        ('dead_stock', 'Dead Stock Detection'),
        ('demand_forecast', 'Demand Forecast'),
        ('customer_segment', 'Customer Segmentation'),
    ]

    product = models.ForeignKey('products.Product', on_delete=models.CASCADE, null=True, blank=True)
    prediction_type = models.CharField(max_length=50, choices=PREDICTION_TYPES)
    value = models.JSONField()
    confidence_score = models.DecimalField(max_digits=4, decimal_places=2, default=0)
    is_applied = models.BooleanField(default=False)
    generated_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-generated_at']

    def __str__(self):
        return f"{self.prediction_type} - {self.generated_at}"