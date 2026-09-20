from decimal import Decimal
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from core.models import TenantModel
from suppliers.models import Supplier


class Category(models.Model):
    name = models.CharField(max_length=150, unique=True)
    description = models.TextField(blank=True)
    parent = models.ForeignKey('self', null=True, blank=True, on_delete=models.SET_NULL, related_name='children')
    image = models.ImageField(upload_to='categories/', null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class Product(TenantModel):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('INACTIVE', 'Inactive'),
        ('DISCONTINUED', 'Discontinued'),
    ]

    name = models.CharField(max_length=255)
    sku = models.CharField(max_length=100, unique=True)
    brand = models.CharField(max_length=255, blank=True, null=True)   # <-- brand as simple text
    description = models.TextField(blank=True)

    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')

    purchase_price = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    sale_price = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0')), MaxValueValidator(Decimal('100'))],
        help_text="Discount as a percentage of the sale price (0-100).",
    )
    tax_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'))

    volume_from = models.CharField(max_length=50, blank=True, null=True)
    volume_to = models.CharField(max_length=50, blank=True, null=True)
    date_from = models.DateField(null=True, blank=True)
    date_to = models.DateField(null=True, blank=True)
    source = models.CharField(max_length=255, blank=True, null=True)

    weight = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    length = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    width = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    height = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    track_inventory = models.BooleanField(default=True)
    minimum_stock = models.PositiveIntegerField(default=0)
    maximum_stock = models.PositiveIntegerField(default=0)
    reorder_point = models.PositiveIntegerField(default=0)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    is_active = models.BooleanField(default=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=Decimal('0.00'))
    total_sales = models.PositiveIntegerField(default=0)
    views_count = models.PositiveIntegerField(default=0)
    ai_tags = models.JSONField(default=dict, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta(TenantModel.Meta):
        ordering = ['name']
        unique_together = ('shop', 'sku')

    def __str__(self):
        return f'{self.name} ({self.sku})'


class ProductImage(models.Model):
    product = models.ForeignKey(Product, related_name='images', on_delete=models.CASCADE)
    image = models.ImageField(upload_to='products/')
    alt_text = models.CharField(max_length=255, blank=True)
    is_primary = models.BooleanField(default=False)

    def __str__(self):
        return f'Image for {self.product.name}'


class ProductVariant(models.Model):
    product = models.ForeignKey(Product, related_name='variants', on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    value = models.CharField(max_length=100)
    additional_price = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))

    def __str__(self):
        return f'{self.product.name} - {self.name}'