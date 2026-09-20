from rest_framework import serializers
from customers.models import Customer
from shops.models import Shop


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = [
            'id', 'full_name', 'phone', 'email', 'address',
            'total_purchases', 'total_spent', 'last_purchase_date',
            'recency_days', 'frequency', 'monetary', 'rfm_score', 'rfm_segment',  # <-- added RFM
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'recency_days', 'frequency', 'monetary', 'rfm_score', 'rfm_segment']

    def validate_email(self, value):
        """Normalize the address and enforce per-shop uniqueness (case-insensitive).

        Mirrors the DB constraint (uniq_customer_shop_email) so the API returns a
        clean 400 instead of an IntegrityError 500.
        """
        if not value:
            return value
        value = value.strip().lower()
        qs = Customer.objects.filter(email__iexact=value)
        shop = None
        if self.instance is not None:
            shop = self.instance.shop
            qs = qs.exclude(pk=self.instance.pk)
        else:
            request = self.context.get('request')
            user = getattr(request, 'user', None)
            shop = getattr(user, 'shop', None)
            if shop is None and user is not None and user.is_superuser:
                shop_id = self.initial_data.get('shop')
                if shop_id:
                    shop = Shop.objects.filter(id=shop_id).first()
        if shop is not None:
            qs = qs.filter(shop=shop)
        if qs.exists():
            raise serializers.ValidationError(
                'A customer with this email already exists in this shop.'
            )
        return value