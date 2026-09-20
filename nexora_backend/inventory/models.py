from django.db import models
from core.models import TenantModel
from products.models import Product


class Inventory(TenantModel):
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=0)
    reserved_quantity = models.PositiveIntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.product.name} - {self.quantity}"

    class Meta(TenantModel.Meta):
        unique_together = ('shop', 'product')


class InventoryMovement(TenantModel):
    CHANGE_TYPE = (
        ("IN", "Stock In"),
        ("OUT", "Stock Out"),
        ("ADJUST", "Adjustment"),
        ("RETURN", "Return"),
        ("TRANSFER", "Transfer"),
    )

    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    change_type = models.CharField(max_length=10, choices=CHANGE_TYPE)
    quantity = models.PositiveIntegerField()
    reference_id = models.CharField(max_length=50, blank=True, null=True)
    reference_type = models.CharField(max_length=20, blank=True, null=True)
    note = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.change_type} - {self.product.name} ({self.quantity})"