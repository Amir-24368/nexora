from django.db import transaction
from django.db.models.query import QuerySet
from rest_framework.exceptions import ValidationError
from rest_framework.request import Request
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from typing import cast

from inventory.services import decrease_stock
from sales.models import Sale, SaleItem
from products.models import Product


class SaleViewSet(viewsets.ModelViewSet):
    queryset = Sale.objects.all()
    permission_classes = [IsAuthenticated]

    def _get_shop(self):
        user = self.request.user
        shop = getattr(user, "shop", None)
        if shop is None:
            raise ValidationError("Authenticated user's shop is unavailable")
        return shop

    def get_queryset(self) -> QuerySet[Sale]:  # type: ignore[override]
        return Sale.objects.filter(shop=self._get_shop())

    @transaction.atomic
    def perform_create(self, serializer):
        shop = self._get_shop()
        request = cast(Request, self.request)
        data = request.data if isinstance(request.data, dict) else {}
        items = data.get("items", [])

        # -------------------------
        # VALIDATION
        # -------------------------
        if not items:
            raise ValidationError("Sale must have at least one item")

        sale = serializer.save(shop=shop)

        total = 0

        # -------------------------
        # PROCESS ITEMS
        # -------------------------
        for item in items:
            if not isinstance(item, dict):
                raise ValidationError("Each sale item must be an object")

            product_id = item.get("product")
            quantity = item.get("quantity")
            price = item.get("price")

            if not product_id:
                raise ValidationError("Product is required")

            if quantity is None or quantity <= 0:
                raise ValidationError("Quantity must be greater than 0")

            if price is None or price < 0:
                raise ValidationError("Price must be valid")

            # -------------------------
            # CHECK PRODUCT EXISTS
            # -------------------------
            try:
                product = Product.objects.get(id=product_id, shop=shop)
            except Product.DoesNotExist:
                raise ValidationError(f"Product {product_id} not found in this shop")

            # -------------------------
            # INVENTORY UPDATE
            # -------------------------
            decrease_stock(shop, product_id, quantity)

            # -------------------------
            # CREATE SALE ITEM
            # -------------------------
            SaleItem.objects.create(
                sale=sale,
                product=product,
                quantity=quantity,
                price=price
            )

            total += price * quantity

        # -------------------------
        # FINALIZE SALE
        # -------------------------
        sale.total_amount = total
        sale.save()