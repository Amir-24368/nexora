from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SupplierViewSet, PurchaseOrderViewSet

router = DefaultRouter()
router.register(r'purchase-orders', PurchaseOrderViewSet, basename='purchase-order')
router.register(r'suppliers', SupplierViewSet, basename='supplier')

urlpatterns = [
    path('', include(router.urls)),
]