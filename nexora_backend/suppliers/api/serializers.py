from rest_framework import serializers
from suppliers.models import Supplier, PurchaseOrder, PurchaseOrderLine
from products.api.serializers import ProductSerializer


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = '__all__'


class PurchaseOrderLineSerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = PurchaseOrderLine
        fields = ['id', 'product', 'product_detail', 'ordered_quantity', 'received_quantity', 'purchase_price', 'subtotal', 'notes']
        read_only_fields = ['id', 'subtotal']


class PurchaseOrderSerializer(serializers.ModelSerializer):
    lines = PurchaseOrderLineSerializer(many=True, read_only=True)
    supplier_detail = SupplierSerializer(source='supplier', read_only=True)

    class Meta:
        model = PurchaseOrder
        fields = [
            'id', 'supplier', 'supplier_detail', 'created_by', 'approved_by',
            'status', 'expected_delivery', 'received_date',
            'subtotal', 'tax', 'shipping_cost', 'discount', 'total',
            'notes', 'created_at', 'updated_at', 'lines'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'subtotal', 'total']