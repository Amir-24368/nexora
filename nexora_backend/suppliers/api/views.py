from django.db import transaction
from rest_framework import viewsets, permissions, filters, status
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from suppliers.models import Supplier, PurchaseOrder
from suppliers.services import (
    create_purchase_order,
    approve_purchase_order,
    receive_purchase_order,
    cancel_purchase_order,
)
from .serializers import SupplierSerializer, PurchaseOrderSerializer


class SupplierViewSet(viewsets.ModelViewSet):
    serializer_class = SupplierSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'company_name', 'email', 'phone']
    ordering_fields = ['name', 'created_at']
    ordering = ['name']

    def get_queryset(self):  # type: ignore
        user = self.request.user
        if user.is_superuser:
            return Supplier.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return Supplier.objects.filter(shop=shop)
        return Supplier.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        shop = getattr(user, 'shop', None)
        if not shop:
            if user.is_superuser:
                raise ValidationError("Superuser must pass a 'shop' id in the payload to create a supplier.")
            raise ValidationError("User does not have a shop assigned.")
        serializer.save(shop=shop)


class PurchaseOrderViewSet(viewsets.ModelViewSet):
    serializer_class = PurchaseOrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'supplier']
    search_fields = ['supplier__name']
    ordering_fields = ['created_at', 'total']
    ordering = ['-created_at']

    def get_queryset(self):  # type: ignore
        user = self.request.user
        if user.is_superuser:
            return PurchaseOrder.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return PurchaseOrder.objects.filter(shop=shop)
        return PurchaseOrder.objects.none()

    def _resolve_shop(self):
        user = self.request.user
        if user.is_superuser:
            data = self.request.data if isinstance(self.request.data, dict) else {}
            shop_id = data.get('shop')
            if shop_id:
                from shops.models import Shop
                try:
                    return Shop.objects.get(id=shop_id)
                except Shop.DoesNotExist:
                    raise ValidationError(f"Shop {shop_id} not found")
            shop = getattr(user, 'shop', None)
            if not shop:
                raise ValidationError("Superuser must provide a shop ID or have a shop assigned.")
            return shop
        shop = getattr(user, 'shop', None)
        if not shop:
            raise ValidationError("User does not have a shop assigned.")
        return shop

    @transaction.atomic
    def perform_create(self, serializer):
        """
        Full creation flow. Expected payload:
        {
          "supplier": <id>,
          "expected_delivery": "2026-10-01",   (optional)
          "notes": "...",                       (optional)
          "lines": [ {"product": <id>, "quantity": 5, "purchase_price": 12.5}, ... ]
        }
        Delegates to the supplier service so subtotals/totals stay consistent.
        """
        shop = self._resolve_shop()
        data = self.request.data if isinstance(self.request.data, dict) else {}

        supplier_id = data.get('supplier')
        if not supplier_id:
            raise ValidationError("Supplier is required")
        try:
            supplier = Supplier.objects.get(id=supplier_id, shop=shop)
        except Supplier.DoesNotExist:
            raise ValidationError(f"Supplier {supplier_id} not found in this shop")

        lines = data.get('lines') or data.get('items') or []
        if not lines:
            raise ValidationError("Purchase order must have at least one line")

        # Map frontend-friendly keys to what the service expects.
        items = []
        for line in lines:
            if not isinstance(line, dict):
                raise ValidationError("Each purchase order line must be an object")
            items.append({
                'product': line.get('product') or line.get('product_id'),
                'quantity': line.get('quantity'),
                'purchase_price': line.get('purchase_price') or line.get('price') or line.get('cost'),
            })

        purchase_order = create_purchase_order(
            shop=shop,
            supplier=supplier,
            user=self.request.user,
            items=items,
            expected_delivery=data.get('expected_delivery'),
            notes=data.get('notes', ''),
        )
        # Stash for create() so the response contains the real PO.
        self._created_po = purchase_order

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        po = getattr(self, '_created_po', None)
        if po is not None:
            return Response(PurchaseOrderSerializer(po).data, status=status.HTTP_201_CREATED)
        return Response({'detail': 'Purchase order created'}, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        po = self.get_object()
        approve_purchase_order(po, request.user)
        return Response(PurchaseOrderSerializer(po).data)

    @action(detail=True, methods=['post'])
    def receive(self, request, pk=None):
        """Receive goods. Payload: {"lines": [{"line_id": <id>, "quantity": 3}, ...]}"""
        po = self.get_object()
        received = request.data.get('lines') or []
        if not received:
            raise ValidationError("Provide the lines being received")
        receive_purchase_order(po, received)
        return Response(PurchaseOrderSerializer(po).data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        po = self.get_object()
        cancel_purchase_order(po)
        return Response(PurchaseOrderSerializer(po).data)