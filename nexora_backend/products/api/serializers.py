from rest_framework import serializers
from products.models import Product, Category


class CategorySerializer(serializers.ModelSerializer):
    children = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'parent', 'children', 'image', 'is_active']
        read_only_fields = ['id']

    def get_children(self, obj):
        if obj.children.exists():
            return CategorySerializer(obj.children.all(), many=True).data
        return []


class ProductSerializer(serializers.ModelSerializer):
    category_detail = CategorySerializer(source='category', read_only=True)

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'sku', 'brand', 'description',
            'category', 'category_detail',
            'purchase_price', 'sale_price', 'discount_percentage', 'tax_percentage',
            'volume_from', 'volume_to', 'date_from', 'date_to', 'source',
            'weight', 'length', 'width', 'height',
            'track_inventory', 'minimum_stock', 'maximum_stock', 'reorder_point',
            'status', 'is_active',
            'rating', 'total_sales', 'views_count', 'ai_tags',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'shop']
        extra_kwargs = {
            'name': {'required': True},
            'sku': {'required': True},
            'purchase_price': {'required': True},
            'sale_price': {'required': True},
        }