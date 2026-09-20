from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError, NotFound
from rest_framework.permissions import IsAuthenticated

from django.db.models import Sum, F

from products.models import Product
from orders.models import Cart, Order, CartItem
from orders.services import add_to_cart, checkout_cart, update_order_status, update_payment_status


class CartViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def _get_shop(self, request):
        """Guard against users without a shop (returns 400 instead of a 500 AttributeError)."""
        shop = getattr(request.user, 'shop', None)
        if not shop:
            raise ValidationError("User does not have a shop assigned.")
        return shop

    def list(self, request):
        shop = self._get_shop(request)
        cart = Cart.objects.filter(
            shop=shop,
            created_by=request.user,
            status="ACTIVE"
        ).first()

        if not cart:
            return Response({"items": []})

        items = CartItem.objects.filter(cart=cart).select_related("product")

        return Response([
            {
                "product_id": item.product.pk,
                "name": item.product.name,
                "quantity": item.quantity,
                "price": float(item.product.sale_price)
            }
            for item in items
        ])

    @action(detail=False, methods=["post"])
    def add(self, request):
        shop = self._get_shop(request)
        product_id = request.data.get("product")
        quantity = request.data.get("quantity", 1)

        if not product_id:
            raise ValidationError("product is required")

        try:
            quantity = int(quantity)
        except (TypeError, ValueError):
            raise ValidationError("quantity must be a number")
        if quantity <= 0:
            raise ValidationError("quantity must be greater than 0")

        try:
            product = Product.objects.get(id=product_id, shop=shop)
        except Product.DoesNotExist:
            raise NotFound("Product not found in this shop")

        cart = add_to_cart(
            shop=shop,
            user=request.user,
            product=product,
            quantity=quantity
        )

        return Response({"cart_id": cart.pk})

    @action(detail=False, methods=["post"])
    def clear(self, request):
        """Empty the active cart without converting it to an order."""
        shop = self._get_shop(request)
        CartItem.objects.filter(
            cart__shop=shop,
            cart__created_by=request.user,
            cart__status="ACTIVE"
        ).delete()
        return Response({"status": "cleared"})

    @action(detail=False, methods=["post"])
    def checkout(self, request):
        payment_method = request.data.get("payment_method", "CASH")
        order = checkout_cart(
            shop=request.user.shop,
            user=request.user,
            payment_method=payment_method
        )

        return Response({
            "order_id": order.pk,
            "status": order.status,
            "total": float(order.total_price)
        })


class OrderViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def _get_shop(self, request):
        shop = getattr(request.user, 'shop', None)
        if not shop:
            raise ValidationError("User does not have a shop assigned.")
        return shop

    def _get_order(self, request, pk):
        shop = self._get_shop(request)
        order = Order.objects.filter(pk=pk).first()
        if not order:
            raise NotFound("Order not found")
        if not request.user.is_superuser and order.shop_id != shop.id:
            # Hide other tenants' orders rather than leaking their existence.
            raise NotFound("Order not found")
        return order

    def list(self, request):
        shop = self._get_shop(request)
        orders = Order.objects.filter(shop=shop).prefetch_related("lines")

        return Response([
            {
                "id": o.pk,
                "status": o.status,
                "total": float(o.total_price),
                "created_at": o.created_at,
                "lines": [
                    {
                        "product_name": line.product_name,
                        "quantity": line.quantity,
                        "unit_price": float(line.unit_price),
                        "line_total": float(line.line_total),
                    }
                    for line in o.lines.all()
                ],
            }
            for o in orders
        ])

    def retrieve(self, request, pk=None):
        order = self._get_order(request, pk)
        return Response({
            "id": order.pk,
            "status": order.status,
            "total": float(order.total_price),
            "created_at": order.created_at,
            "lines": [
                {
                    "product_name": line.product_name,
                    "quantity": line.quantity,
                    "unit_price": float(line.unit_price),
                    "line_total": float(line.line_total),
                }
                for line in order.lines.all()
            ],
        })

    @action(detail=True, methods=["post"])
    def set_status(self, request, pk=None):
        order = self._get_order(request, pk)

        new_status = request.data.get("status")

        if not new_status:
            raise ValidationError("status is required")

        order = update_order_status(order, new_status)

        return Response({
            "order_id": order.pk,
            "new_status": order.status
        })

    @action(detail=True, methods=["post"])
    def payment(self, request, pk=None):
        order = self._get_order(request, pk)

        payment_status = request.data.get("status")
        transaction_id = request.data.get("transaction_id")

        if not payment_status:
            raise ValidationError("status is required")

        order = update_payment_status(order, payment_status, transaction_id)

        return Response({
            "order_id": order.pk,
            "payment_status": payment_status,
            "order_status": order.status
        })

    @action(detail=False, methods=["get"])
    def summary(self, request):
        """Dashboard summary for the shop's orders."""
        shop = self._get_shop(request)
        orders = Order.objects.filter(shop=shop)
        revenue = orders.aggregate(revenue=Sum("total_price"))["revenue"] or 0
        return Response({
            "total_orders": orders.count(),
            "total_revenue": float(revenue),
            "pending": orders.filter(status="PENDING").count(),
            "paid": orders.filter(status="PAID").count(),
        })

    @action(detail=False, methods=["get"])
    def low_stock(self, request):
        """Products in this shop at or below their reorder point."""
        from inventory.models import Inventory
        shop = self._get_shop(request)
        low = (
            Inventory.objects
            .filter(shop=shop, quantity__lte=F("product__reorder_point"))
            .select_related("product")
        )
        return Response([
            {
                "product_id": inv.product_id,
                "name": inv.product.name,
                "sku": inv.product.sku,
                "quantity": inv.quantity,
                "reorder_point": inv.product.reorder_point,
            }
            for inv in low
        ])