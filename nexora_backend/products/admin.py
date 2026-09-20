from django.contrib import admin
from .models import Product, Category, ProductImage, ProductVariant


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'parent', 'is_active')
    search_fields = ('name',)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'sku', 'brand', 'category', 'sale_price', 'status', 'is_active')
    search_fields = ('name', 'sku', 'brand')
    list_filter = ('status', 'category', 'is_active')


@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ('product', 'is_primary')


@admin.register(ProductVariant)
class ProductVariantAdmin(admin.ModelAdmin):
    list_display = ('product', 'name', 'value', 'additional_price')