from decimal import Decimal

from django.db import models
from django.conf import settings

from core.models import TenantModel


# ==========================================================
# SUPPLIER
# ==========================================================

class Supplier(TenantModel):
    name = models.CharField(max_length=200)

    company_name = models.CharField(
        max_length=255,
        blank=True
    )

    email = models.EmailField(blank=True)

    phone = models.CharField(
        max_length=30,
        blank=True
    )

    website = models.URLField(blank=True)

    tax_number = models.CharField(
        max_length=100,
        blank=True
    )

    bank_account = models.CharField(
        max_length=100,
        blank=True
    )

    country = models.CharField(
        max_length=100,
        blank=True
    )

    city = models.CharField(
        max_length=100,
        blank=True
    )

    state = models.CharField(
        max_length=100,
        blank=True
    )

    postal_code = models.CharField(
        max_length=20,
        blank=True
    )

    address = models.TextField(blank=True)

    contact_person = models.CharField(
        max_length=150,
        blank=True
    )

    contact_position = models.CharField(
        max_length=150,
        blank=True
    )

    contact_phone = models.CharField(
        max_length=30,
        blank=True
    )

    contact_email = models.EmailField(blank=True)

    payment_terms = models.CharField(
        max_length=100,
        default="30 Days"
    )

    delivery_days = models.PositiveIntegerField(default=7)

    minimum_order_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00")
    )

    rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal(5.00)
    )

    notes = models.TextField(blank=True)

    is_active = models.BooleanField(default=True)

    class Meta(TenantModel.Meta):
        ordering = ["name"]

    def __str__(self):
        return self.name


# ==========================================================
# PURCHASE ORDER
# ==========================================================

class PurchaseOrder(TenantModel):

    STATUS_CHOICES = [
        ("DRAFT", "Draft"),
        ("SUBMITTED", "Submitted"),
        ("APPROVED", "Approved"),
        ("ORDERED", "Ordered"),
        ("PARTIALLY_RECEIVED", "Partially Received"),
        ("RECEIVED", "Received"),
        ("CANCELLED", "Cancelled"),
    ]

    supplier = models.ForeignKey(
        Supplier,
        on_delete=models.CASCADE,
        related_name="purchase_orders"
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_purchase_orders"
    )

    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_purchase_orders"
    )

    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default="DRAFT"
    )

    expected_delivery = models.DateField(
        null=True,
        blank=True
    )

    received_date = models.DateField(
        null=True,
        blank=True
    )

    subtotal = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00")
    )

    tax = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00")
    )

    shipping_cost = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00")
    )

    discount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00")
    )

    total = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00")
    )

    notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta(TenantModel.Meta):
        ordering = ["-created_at"]

    def __str__(self):
        return f"PO-{self.pk}"


# ==========================================================
# PURCHASE ORDER LINE
# ==========================================================

class PurchaseOrderLine(models.Model):

    purchase_order = models.ForeignKey(
        PurchaseOrder,
        related_name="lines",
        on_delete=models.CASCADE
    )

    product = models.ForeignKey(
        "products.Product",
        on_delete=models.CASCADE
    )

    ordered_quantity = models.PositiveIntegerField()

    received_quantity = models.PositiveIntegerField(default=0)

    purchase_price = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )

    subtotal = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00")
    )

    notes = models.TextField(blank=True)

    def save(self, *args, **kwargs):
        self.subtotal = self.purchase_price * self.ordered_quantity
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.product.name} ({self.ordered_quantity})"


# ==========================================================
# GOODS RECEIPT
# ==========================================================

class GoodsReceipt(TenantModel):

    STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("RECEIVED", "Received"),
        ("CANCELLED", "Cancelled"),
    ]

    purchase_order = models.ForeignKey(
        PurchaseOrder,
        on_delete=models.CASCADE,
        related_name="receipts"
    )

    received_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="PENDING"
    )

    supplier_invoice = models.CharField(
        max_length=100,
        blank=True
    )

    delivery_note = models.CharField(
        max_length=100,
        blank=True
    )

    received_date = models.DateTimeField(
        auto_now_add=True
    )

    notes = models.TextField(blank=True)

    class Meta(TenantModel.Meta):
        ordering = ["-received_date"]

    def __str__(self):
        return f"GR-{self.pk}"


# ==========================================================
# GOODS RECEIPT LINE
# ==========================================================

class GoodsReceiptLine(models.Model):

    receipt = models.ForeignKey(
        GoodsReceipt,
        related_name="lines",
        on_delete=models.CASCADE
    )

    product = models.ForeignKey(
        "products.Product",
        on_delete=models.CASCADE
    )

    quantity_received = models.PositiveIntegerField()

    purchase_price = models.DecimalField(
        max_digits=12,
        decimal_places=2
    )

    batch_number = models.CharField(
        max_length=100,
        blank=True
    )

    expiry_date = models.DateField(
        null=True,
        blank=True
    )

    notes = models.TextField(
        blank=True
    )

    def __str__(self):
        return f"{self.product.name} x {self.quantity_received}"