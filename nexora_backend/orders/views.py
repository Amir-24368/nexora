from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from orders.models import Order, Cart
from orders.services import checkout_cart, update_payment_status


class CartViewSet(viewsets.ViewSet):

    def list(self, request):
        cart = Cart.objects.filter(
            shop=request.user.shop,
            created_by=request.user,
            status="ACTIVE"
        ).first()

        if not cart:
            return Response({"items": []})

        cart_items = cart.items.all()

        return Response([
            {
                "product": item.product.id,
                "name": item.product.name,
                "quantity": item.quantity,
                "price": item.product.sale_price
            }
            for item in cart_items
        ])

    @action(detail=False, methods=["post"])
    def checkout(self, request):
        order = checkout_cart(
            shop=request.user.shop,
            user=request.user,
            payment_method=request.data.get("payment_method", "CASH")
        )

        return Response({
            "order_id": order.pk,
            "status": order.status,
            "total": order.total_price
        })


class OrderViewSet(viewsets.ViewSet):

    def list(self, request):
        orders = Order.objects.filter(shop=request.user.shop)

        return Response([
            {
                "id": o.pk,
                "status": o.status,
                "total": o.total_price
            }
            for o in orders
        ])

    @action(detail=True, methods=["post"])
    def payment(self, request, pk=None):
        order = Order.objects.get(pk=pk)

        status = request.data.get("status")
        transaction_id = request.data.get("transaction_id")

        order = update_payment_status(order, status, transaction_id)

        return Response({
            "order_id": order.pk,
            "status": order.status
        })