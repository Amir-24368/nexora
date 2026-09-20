from django.db import models


class TenantManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset()

    def for_shop(self, shop):
        return self.get_queryset().filter(shop=shop)


class TenantModel(models.Model):
    shop = models.ForeignKey(
        'shops.Shop',
        on_delete=models.CASCADE,
        related_name="%(class)s_related",
    )

    objects = TenantManager()

    class Meta:
        abstract = True