from django.db import models
from core.models import TenantModel
from django.utils import timezone
from decimal import Decimal


class Customer(TenantModel):
    """Customer model for each shop."""

    full_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)

    # Analytical fields (existing)
    total_purchases = models.PositiveIntegerField(default=0)
    total_spent = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0'))
    last_purchase_date = models.DateTimeField(null=True, blank=True)

    # ========== RFM FIELDS (NEW) ==========
    recency_days = models.PositiveIntegerField(default=0, help_text="Days since last purchase")
    frequency = models.PositiveIntegerField(default=0, help_text="Total number of orders")
    monetary = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0'), help_text="Total monetary value")
    rfm_score = models.PositiveSmallIntegerField(default=0, help_text="Combined RFM score (3-15)")
    rfm_segment = models.CharField(max_length=50, blank=True, null=True, help_text="Segment name (e.g., 'Champions', 'Loyal', 'At Risk')")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            # One email may own only one customer per shop -- stops the
            # duplicate rows old checkouts kept creating.
            models.UniqueConstraint(
                fields=['shop', 'email'],
                condition=models.Q(email__isnull=False),
                name='uniq_customer_shop_email',
            ),
        ]

    def __str__(self):
        return self.full_name

    def update_rfm(self):
        """Calculate RFM values based on sales history."""
        from sales.models import Sale
        from django.db.models import Sum, Count, Max

        sales = Sale.objects.filter(customer=self, status='COMPLETED')

        # If no sales, set default RFM
        if not sales.exists():
            self.recency_days = 999  # high number for inactive
            self.frequency = 0
            self.monetary = Decimal('0')
            self.rfm_score = 0
            self.rfm_segment = 'Inactive'
            self.total_purchases = 0
            self.total_spent = Decimal('0')
            self.last_purchase_date = None
            self.save(update_fields=[
                'recency_days', 'frequency', 'monetary', 'rfm_score', 'rfm_segment',
                'total_purchases', 'total_spent', 'last_purchase_date',
            ])
            return

        # Aggregate metrics in a single query
        agg = sales.aggregate(
            total=Sum('total_amount'),
            count=Count('id'),
            last=Max('sale_date'),
        )
        self.monetary = agg['total'] or Decimal('0')
        self.frequency = agg['count'] or 0
        last_purchase = agg['last']

        # Recency: days since last purchase
        if last_purchase:
            days_since = (timezone.now() - last_purchase).days
            self.recency_days = days_since if days_since >= 0 else 0
            self.last_purchase_date = last_purchase
        else:
            self.recency_days = 999

        # Keep legacy analytic fields in sync so both old and new pages agree
        self.total_purchases = self.frequency
        self.total_spent = self.monetary

        # Compute RFM score (1-5 for each dimension)
        r_score = self._score_recency()
        f_score = self._score_frequency()
        m_score = self._score_monetary()
        self.rfm_score = r_score + f_score + m_score  # total between 3 and 15

        # Assign segment based on score combination
        self.rfm_segment = self._get_segment(r_score, f_score, m_score)

        self.save(update_fields=[
            'recency_days', 'frequency', 'monetary', 'rfm_score', 'rfm_segment',
            'total_purchases', 'total_spent', 'last_purchase_date',
        ])

    def _score_recency(self):
        """Score recency: 5 = recent, 1 = old."""
        if self.recency_days <= 7:
            return 5
        elif self.recency_days <= 30:
            return 4
        elif self.recency_days <= 90:
            return 3
        elif self.recency_days <= 180:
            return 2
        else:
            return 1

    def _score_frequency(self):
        """Score frequency: 5 = frequent, 1 = rare."""
        if self.frequency >= 20:
            return 5
        elif self.frequency >= 10:
            return 4
        elif self.frequency >= 5:
            return 3
        elif self.frequency >= 2:
            return 2
        else:
            return 1

    def _score_monetary(self):
        """Score monetary: 5 = high spender, 1 = low."""
        if self.monetary >= 5000:
            return 5
        elif self.monetary >= 1000:
            return 4
        elif self.monetary >= 500:
            return 3
        elif self.monetary >= 100:
            return 2
        else:
            return 1

    def _get_segment(self, r, f, m):
        """Assign segment based on RFM scores (R/F/M each 1-5).

        Ordered best -> worst; more specific rules come first so
        every customer lands in exactly one segment.
        """
        if r >= 4 and f >= 4 and m >= 4:
            return 'Champions'
        if r >= 4 and f >= 2:
            return 'Loyal'
        if r >= 4 and f <= 2 and m >= 3:
            return 'Potential Loyalists'
        if r >= 4:
            return 'New Customers'
        if r == 3 and f >= 3 and m >= 3:
            return 'At Risk'
        if r <= 2 and f >= 4 and m >= 4:
            return 'Cannot Lose Them'
        if r <= 2 and f >= 3:
            return 'About to Sleep'
        if r <= 2 and f <= 2 and m <= 2:
            return 'Hibernating'
        if r <= 2 and m >= 4:
            return 'Recent but Low Value'
        return 'General'