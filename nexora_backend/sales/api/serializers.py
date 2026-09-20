from rest_framework import serializers
from sales.models import Sale, SaleItem
from products.api.serializers import ProductSerializer
from customers.api.serializers import CustomerSerializer


class SaleItemSerializer(serializers.ModelSerializer):
    product_detail = serializers.SerializerMethodField()

    class Meta:
        model = SaleItem
        fields = ['id', 'product', 'product_detail', 'quantity', 'price']
        read_only_fields = ['id']

    def get_product_detail(self, obj):
        from products.api.serializers import ProductSerializer
        return ProductSerializer(obj.product).data if obj.product else None


class SaleSerializer(serializers.ModelSerializer):
    items = SaleItemSerializer(many=True, read_only=True)
    customer_detail = serializers.SerializerMethodField()

    class Meta:
        model = Sale
        fields = [
            'id', 'customer', 'customer_detail', 'total_amount',
            'sale_date', 'status', 'payment_status', 'items'
        ]
        # total_amount is computed server-side from the line items in
        # perform_create -- clients must never send it. Marking it read-only
        # stops DRF from rejecting the payload with "This field is required."
        read_only_fields = ['id', 'sale_date', 'total_amount']

    def get_customer_detail(self, obj):
        from customers.api.serializers import CustomerSerializer
        return CustomerSerializer(obj.customer).data if obj.customer else None