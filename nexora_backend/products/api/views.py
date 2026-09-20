from rest_framework import viewsets, permissions, filters
from rest_framework.request import Request
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.exceptions import ValidationError
from django.db import IntegrityError
from products.models import Product, Category
from .serializers import ProductSerializer, CategorySerializer
from typing import cast


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description']

    def create(self, request, *args, **kwargs):
        name = request.data.get('name', '').strip()
        if name and Category.objects.filter(name__iexact=name).exists():
            raise ValidationError({"name": "A category with this name already exists."})
        return super().create(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        name = request.data.get('name', '').strip()
        if name and Category.objects.filter(name__iexact=name).exclude(pk=instance.pk).exists():
            raise ValidationError({"name": "A category with this name already exists."})
        return super().update(request, *args, **kwargs)


class ProductViewSet(viewsets.ModelViewSet):
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]

    filterset_fields = ['category', 'status', 'is_active', 'track_inventory']
    search_fields = ['name', 'sku', 'brand', 'description', 'source']
    ordering_fields = ['name', 'sale_price', 'purchase_price', 'created_at', 'updated_at', 'total_sales', 'rating', 'minimum_stock', 'reorder_point']
    ordering = ['name']

    def get_queryset(self):  # type: ignore
        user = self.request.user
        if user.is_superuser:
            return Product.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return Product.objects.filter(shop=shop)
        return Product.objects.none()

    def create(self, request, *args, **kwargs):
        try:
            return super().create(request, *args, **kwargs)
        except IntegrityError as e:
            if 'sku' in str(e):
                raise ValidationError({"sku": "A product with this SKU already exists."})
            raise ValidationError({"detail": "Database error occurred."})

    def update(self, request, *args, **kwargs):
        try:
            return super().update(request, *args, **kwargs)
        except IntegrityError as e:
            if 'sku' in str(e):
                raise ValidationError({"sku": "A product with this SKU already exists."})
            raise ValidationError({"detail": "Database error occurred."})

    def perform_create(self, serializer):
        user = self.request.user
        if user.is_superuser:
            request = cast(Request, self.request)
            data = getattr(request, 'data', {})
            shop_id = data.get('shop')
            if shop_id:
                from shops.models import Shop
                shop = Shop.objects.get(id=shop_id)
            else:
                shop = getattr(user, 'shop', None)
                if not shop:
                    raise ValidationError("Superuser must provide a shop ID.")
        else:
            shop = getattr(user, 'shop', None)
            if not shop:
                raise ValidationError("User does not have a shop assigned.")
        serializer.save(shop=shop)