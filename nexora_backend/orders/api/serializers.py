from rest_framework import serializers
from orders.models import Cart, CartItem, Order, OrderLine, Payment
from products.api.serializers import ProductSerializer


class CartItemSerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_detail', 'quantity']


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)

    class Meta:
        model = Cart
        fields = ['id', 'status', 'items', 'created_at', 'updated_at', 'shop']
        read_only_fields = ['id', 'created_at', 'updated_at', 'shop']


class OrderLineSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderLine
        fields = ['id', 'product_name', 'unit_price', 'quantity', 'line_total']


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ['id', 'method', 'status', 'amount', 'transaction_id', 'created_at']


class OrderSerializer(serializers.ModelSerializer):
    lines = OrderLineSerializer(many=True, read_only=True)
    payments = PaymentSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = ['id', 'user', 'status', 'total_price', 'currency',
                  'shipping_address', 'billing_address', 'lines', 'payments',
                  'created_at', 'updated_at', 'shop']
        read_only_fields = ['id', 'created_at', 'updated_at', 'shop']