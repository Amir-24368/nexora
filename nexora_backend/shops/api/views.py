from rest_framework import viewsets, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from shops.models import Shop
from .serializers import ShopSerializer


class ShopViewSet(viewsets.ModelViewSet):
    serializer_class = ShopSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'slug']

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Shop.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return Shop.objects.filter(id=shop.id)
        return Shop.objects.none()

    def perform_create(self, serializer):
        # Only superusers can create shops
        if not self.request.user.is_superuser:
            raise ValidationError("Only superusers can create shops.")
        serializer.save()

    def perform_update(self, serializer):
        if not self.request.user.is_superuser:
            raise ValidationError("Only superusers can update shops.")
        serializer.save()

    def perform_destroy(self, instance):
        if not self.request.user.is_superuser:
            raise ValidationError("Only superusers can delete shops.")
        instance.delete()