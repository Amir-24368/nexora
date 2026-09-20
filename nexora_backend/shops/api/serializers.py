from rest_framework import serializers
from shops.models import Shop


class ShopSerializer(serializers.ModelSerializer):
    class Meta:
        model = Shop
        fields = ['id', 'name', 'slug', 'tax_id', 'phone', 'address', 'logo_url', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']