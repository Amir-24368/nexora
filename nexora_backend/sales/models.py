from django.db import models
from core.models import TenantModel  # <-- ADD THIS IMPORT
from customers.models import Customer
from products.models import Product

# Now the Sale class will work


class Sale(TenantModel):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
        ('RETURNED', 'Returned'),
    )
    PAYMENT_CHOICES = (
        ('UNPAID', 'Unpaid'),
        ('PAID', 'Paid'),
        ('PARTIAL', 'Partially Paid'),
        ('REFUNDED', 'Refunded'),
    )

    customer = models.ForeignKey(
        "customers.Customer",
        on_delete=models.CASCADE,
        related_name="sales",
        null=True,
        blank=True,
    )

    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_CHOICES, default='UNPAID')

    sale_date = models.DateTimeField(
        auto_now_add=True
    )

    class Meta(TenantModel.Meta):
        ordering = ["-sale_date"]

    def __str__(self):
        # Use pk instead of id to satisfy static analyzers and still reference the primary key
        return f"Sale {self.pk}"


class SaleItem(models.Model):
    sale = models.ForeignKey(
        Sale,
        on_delete=models.CASCADE,
        related_name="items"
    )
    product = models.ForeignKey(
        "products.Product",
        on_delete=models.CASCADE
    )
    quantity = models.PositiveIntegerField()
    price = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )

    def __str__(self):
        return f"{self.product.name}"


# ========== RFM SIGNAL ==========
# Automatically update customer RFM when a sale is completed

from django.db.models.signals import post_save
from django.dispatch import receiver


@receiver(post_save, sender=Sale)
def update_customer_rfm_on_sale(sender, instance, created, **kwargs):
    """
    Update customer's RFM metrics when a sale is created or updated.
    Only runs for completed sales. Never blocks the sale itself:
    analytics failing must not fail the transaction that recorded it.
    """
    if instance.status == 'COMPLETED' and instance.customer:
        try:
            instance.customer.update_rfm()
        except Exception:
            import logging
            logging.getLogger(__name__).exception("RFM update failed for sale %s", instance.pk)