from rest_framework import viewsets, permissions, filters
from django_filters.rest_framework import DjangoFilterBackend
from django.db import transaction
from django.db.models import Sum
from rest_framework.exceptions import ValidationError
from rest_framework.decorators import action
from rest_framework.response import Response
from sales.models import Sale
from .serializers import SaleSerializer
from inventory.services import decrease_stock
from products.models import Product


class SaleViewSet(viewsets.ModelViewSet):
    serializer_class = SaleSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'payment_status', 'customer']
    search_fields = ['customer__full_name', 'customer__email']
    ordering_fields = ['sale_date', 'total_amount']
    ordering = ['-sale_date']

    def get_queryset(self):  # type: ignore
        user = self.request.user
        if user.is_superuser:
            return Sale.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return Sale.objects.filter(shop=shop)
        return Sale.objects.none()

    def _resolve_shop(self):
        """Pick the shop for the new sale. Superusers may pass a 'shop' id in the payload."""
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

    def _resolve_customer(self, shop, data):
        """
        Customer is optional (e.g. in-app shoppers).
        If a 'customer_email' (or an existing customer id) is supplied, auto-link
        it so the RFM engine has data to work with.
        """
        from customers.models import Customer

        customer_id = data.get('customer')
        if customer_id:
            try:
                return Customer.objects.get(id=customer_id, shop=shop)
            except Customer.DoesNotExist:
                raise ValidationError(f"Customer {customer_id} not found in this shop")

        email = (data.get('customer_email') or '').strip().lower()
        if email:
            # Match by email first. If none exists, adopt a legacy name-only row
            # left behind by older checkouts (which sent the display name instead
            # of an email) instead of silently creating yet another duplicate.
            customer = Customer.objects.filter(shop=shop, email__iexact=email).first()
            if customer is None:
                name = data.get('customer_name') or email
                legacy = Customer.objects.filter(
                    shop=shop, email__isnull=True, full_name=name
                ).first()
                if legacy is not None:
                    legacy.email = email
                    legacy.save(update_fields=['email'])
                    customer = legacy
            if customer is None:
                customer = Customer.objects.create(
                    shop=shop,
                    email=email,
                    full_name=data.get('customer_name') or email,
                )
            return customer

        return None

    @transaction.atomic
    def perform_create(self, serializer):
        shop = self._resolve_shop()
        data = self.request.data if isinstance(self.request.data, dict) else {}

        items = data.get('items', [])
        if not items:
            raise ValidationError("Sale must have at least one item")

        customer = self._resolve_customer(shop, data)
        status_value = data.get('status') or 'COMPLETED'
        if status_value not in ('PENDING', 'COMPLETED', 'CANCELLED', 'RETURNED'):
            raise ValidationError("Invalid status")

        # Compute the total on the server from the line items -- never trust the client.
        total = 0
        for item in items:
            if not isinstance(item, dict):
                raise ValidationError("Each sale item must be an object")

            product_id = item.get('product')
            quantity = item.get('quantity')
            price = item.get('price')

            if not product_id:
                raise ValidationError("Product is required")
            try:
                quantity = int(quantity)
                price = float(price)
            except (TypeError, ValueError):
                raise ValidationError("Quantity and price must be numbers")
            if quantity <= 0:
                raise ValidationError("Quantity must be greater than 0")
            if price < 0:
                raise ValidationError("Price must be valid")

            try:
                Product.objects.get(id=product_id, shop=shop)
            except Product.DoesNotExist:
                raise ValidationError(f"Product {product_id} not found in this shop")

            total += price * quantity

        sale = serializer.save(
            shop=shop,
            customer=customer,
            status=status_value,
            total_amount=total,
        )

        # Stock deduction happens after the sale row exists, inside the same transaction.
        for item in items:
            decrease_stock(shop, item.get('product'), int(item.get('quantity')))
            from sales.models import SaleItem
            SaleItem.objects.create(
                sale=sale,
                product_id=item.get('product'),
                quantity=int(item.get('quantity')),
                price=item.get('price'),
            )

    @action(detail=False, methods=['get'])
    def mine(self, request):
        """Sales linked to the current user's email (customer portal view)."""
        email = (getattr(request.user, 'email', '') or '').lower()
        queryset = (
            self.get_queryset()
            .filter(customer__email__iexact=email)
            .select_related('customer')
            .prefetch_related('items')
        )
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Quick dashboard numbers for completed sales."""
        queryset = self.get_queryset().filter(status='COMPLETED')
        agg = queryset.aggregate(revenue=Sum('total_amount'))
        return Response({
            'total_revenue': agg['revenue'] or 0,
            'total_orders': queryset.count(),
        })