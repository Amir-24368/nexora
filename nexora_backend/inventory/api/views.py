from rest_framework import viewsets, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import F
from inventory.models import Inventory, InventoryMovement
from .serializers import InventorySerializer, InventoryMovementSerializer


class InventoryViewSet(viewsets.ModelViewSet):
    serializer_class = InventorySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['product__category', 'product__brand']
    search_fields = ['product__name', 'product__sku']
    ordering_fields = ['quantity', 'last_updated']
    ordering = ['-last_updated']

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Inventory.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return Inventory.objects.filter(shop=shop)
        return Inventory.objects.none()

    def perform_create(self, serializer):
        # 'shop' is read-only in the serializer, so without this the POST
        # would try to save an Inventory row with no shop and crash with a
        # NOT NULL 500. Assign the creator's shop (superusers may pass one).
        user = self.request.user
        if user.is_superuser:
            data = self.request.data if isinstance(self.request.data, dict) else {}
            shop_id = data.get('shop')
            if shop_id:
                from shops.models import Shop
                try:
                    shop = Shop.objects.get(id=shop_id)
                except Shop.DoesNotExist:
                    raise ValidationError(f"Shop {shop_id} not found")
            else:
                shop = getattr(user, 'shop', None)
                if not shop:
                    raise ValidationError("Superuser must provide a shop ID or have a shop assigned.")
        else:
            shop = getattr(user, 'shop', None)
            if not shop:
                raise ValidationError("User does not have a shop assigned.")
        serializer.save(shop=shop)

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Return products that are below their reorder_point or minimum_stock."""
        queryset = self.get_queryset().filter(
            quantity__lte=F('product__reorder_point')
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class InventoryMovementViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = InventoryMovementSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['change_type', 'product']
    ordering_fields = ['created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return InventoryMovement.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return InventoryMovement.objects.filter(shop=shop)
        return InventoryMovement.objects.none()