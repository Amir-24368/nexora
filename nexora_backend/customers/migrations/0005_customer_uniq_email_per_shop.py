from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('customers', '0004_alter_customer_options'),
    ]

    operations = [
        # Guard against duplicate customer rows: one email may own only one
        # customer per shop. Partial because legacy rows with a NULL email are
        # allowed to share a name; NULLs never collide in SQL unique checks.
        migrations.AddConstraint(
            model_name='customer',
            constraint=models.UniqueConstraint(
                fields=['shop', 'email'],
                condition=models.Q(email__isnull=False),
                name='uniq_customer_shop_email',
            ),
        ),
    ]
