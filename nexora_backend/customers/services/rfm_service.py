from customers.models import Customer


class RFMService:
    @staticmethod
    def recalculate_all_customers(shop=None):
        """Update RFM for all customers of a shop or all shops."""
        queryset = Customer.objects.all()
        if shop:
            queryset = queryset.filter(shop=shop)

        for customer in queryset:
            customer.update_rfm()

        return queryset.count()

    @staticmethod
    def get_segment_counts(shop=None):
        """Return count of customers per RFM segment."""
        queryset = Customer.objects.all()
        if shop:
            queryset = queryset.filter(shop=shop)
        from django.db import models
        segments = queryset.values('rfm_segment').annotate(count=models.Count('id'))
        return segments