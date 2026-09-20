from rest_framework import serializers
from inventory.models import Inventory, InventoryMovement
from products.api.serializers import ProductSerializer


class InventorySerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = Inventory
        fields = ['id', 'product', 'product_detail', 'quantity', 'reserved_quantity', 'last_updated', 'shop']
        read_only_fields = ['id', 'last_updated', 'shop']


class InventoryMovementSerializer(serializers.ModelSerializer):
    product_detail = ProductSerializer(source='product', read_only=True)

    class Meta:
        model = InventoryMovement
        fields = ['id', 'product', 'product_detail', 'change_type', 'quantity', 'reference_id', 'reference_type', 'note', 'created_at', 'shop']
        read_only_fields = ['id', 'created_at', 'shop']