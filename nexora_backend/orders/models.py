from django.db import models
from django.conf import settings
from decimal import Decimal
from core.models import TenantModel
from products.models import Product


# ---------------- CART ----------------

class Cart(TenantModel):
    STATUS = [
        ("ACTIVE", "Active"),
        ("CONVERTED", "Converted"),
        ("ABANDONED", "Abandoned"),
    ]

    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS, default="ACTIVE")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        # Use pk instead of id to satisfy static analyzers that may not recognize
        # the implicit 'id' attribute provided by Django's Model base class.
        return f"Cart {self.pk} - {getattr(self.created_by, 'email', self.created_by)}"


class CartItem(models.Model):
    cart = models.ForeignKey(Cart, related_name="items", on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    quantity = models.PositiveIntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.product.name} x {self.quantity}"


# ---------------- ORDER ----------------

class Order(TenantModel):
    STATUS = [
        ("PENDING", "Pending"),
        ("PAID", "Paid"),
        ("FAILED", "Failed"),
        ("PROCESSING", "Processing"),
        ("SHIPPED", "Shipped"),
        ("DELIVERED", "Delivered"),
        ("CANCELLED", "Cancelled"),
        ("REFUNDED", "Refunded"),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    status = models.CharField(max_length=20, choices=STATUS, default="PENDING")
    total_price = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    currency = models.CharField(max_length=10, default="EUR")
    shipping_address = models.TextField(blank=True, null=True)
    billing_address = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Order #{self.pk} - {self.status}"


# ---------------- ORDER LINE (SNAPSHOT) ----------------

class OrderLine(models.Model):
    order = models.ForeignKey(Order, related_name="lines", on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    product_name = models.CharField(max_length=255)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    quantity = models.PositiveIntegerField()
    line_total = models.DecimalField(max_digits=12, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.product_name} x {self.quantity}"


# ---------------- PAYMENT ----------------

class Payment(models.Model):
    METHOD = [
        ("CASH", "Cash"),
        ("CARD", "Card"),
        ("PAYPAL", "PayPal"),
        ("STRIPE", "Stripe"),
        ("BANK", "Bank Transfer"),
    ]

    STATUS = [
        ("PENDING", "Pending"),
        ("AUTHORIZED", "Authorized"),
        ("PAID", "Paid"),
        ("FAILED", "Failed"),
        ("REFUNDED", "Refunded"),
    ]

    order = models.ForeignKey(Order, related_name="payments", on_delete=models.CASCADE)
    method = models.CharField(max_length=20, choices=METHOD)
    status = models.CharField(max_length=20, choices=STATUS, default="PENDING")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_id = models.CharField(max_length=255, blank=True, null=True)
    provider_response = models.JSONField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        # Use pk to avoid static analysis warnings about implicit 'id' attribute
        return f"Payment {self.pk} - {self.status}"


# ---------------- INVENTORY TRANSACTION ----------------

class InventoryTransaction(models.Model):
    shop = models.ForeignKey("shops.Shop", on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    change = models.IntegerField()
    reason = models.CharField(max_length=50)
    reference_id = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.product.name}: {self.change} ({self.reason})"