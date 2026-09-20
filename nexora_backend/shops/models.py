from django.db import models
from django.conf import settings


class Shop(models.Model):
    name = models.CharField(max_length=255)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="owned_shops"
    )
    slug = models.SlugField(max_length=255, unique=True, blank=True, null=True)
    tax_id = models.CharField(max_length=50, blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    logo_url = models.TextField(blank=True, null=True)
    settings = models.JSONField(default=dict, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            base_slug = (self.name or "shop").lower().strip().replace(' ', '-') or "shop"
            # Slugs are unique: disambiguate repeated shop names instead of crashing
            # (e.g. two owners both creating a shop called "My Store").
            slug = base_slug
            suffix = 2
            while Shop.objects.filter(slug=slug).exclude(pk=self.pk).exists():
                slug = f"{base_slug}-{suffix}"
                suffix += 1
            self.slug = slug
        super().save(*args, **kwargs)