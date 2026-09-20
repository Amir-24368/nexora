from rest_framework import viewsets, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError
from django.db import models
from customers.models import Customer
from .serializers import CustomerSerializer


class CustomerViewSet(viewsets.ModelViewSet):
    serializer_class = CustomerSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['full_name', 'phone', 'email']
    ordering_fields = ['full_name', 'created_at', 'total_spent', 'recency_days', 'rfm_score']
    ordering = ['full_name']

    def get_queryset(self):  # type: ignore
        user = self.request.user
        if user.is_superuser:
            return Customer.objects.all()
        shop = getattr(user, 'shop', None)
        if shop:
            return Customer.objects.filter(shop=shop)
        return Customer.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        if user.is_superuser:
            request_data = getattr(self.request, 'data', {})
            shop_id = request_data.get('shop')
            if shop_id:
                from shops.models import Shop
                shop = Shop.objects.get(id=shop_id)
            else:
                shop = getattr(user, 'shop', None)
                if not shop:
                    raise ValidationError("Superuser must provide a shop ID or have a shop assigned.")
        else:
            shop = getattr(user, 'shop', None)
            if not shop:
                raise ValidationError("User does not have a shop assigned.")
        serializer.save(shop=shop)

    @action(detail=False, methods=['get'])
    def rfm_segments(self, request):
        queryset = self.get_queryset()
        segments = queryset.values('rfm_segment').annotate(
            count=models.Count('id')
        ).order_by('-count')
        return Response(segments)

    @action(detail=True, methods=['post'])
    def recalculate_rfm(self, request, pk=None):
        customer = self.get_object()
        customer.update_rfm()
        serializer = self.get_serializer(customer)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def recalculate_all(self, request):
        customers = self.get_queryset()
        updated = 0
        for c in customers:
            c.update_rfm()
            updated += 1
        return Response({'status': 'success', 'updated': updated})