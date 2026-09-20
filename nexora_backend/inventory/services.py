from django.db import transaction
from rest_framework.exceptions import ValidationError
from inventory.models import Inventory, InventoryMovement


def get_inventory(shop, product):
    inventory, _ = Inventory.objects.get_or_create(
        shop=shop,
        product=product,
        defaults={"quantity": 0}
    )
    return inventory


@transaction.atomic
def decrease_stock(shop, product_id, quantity):
    if quantity <= 0:
        raise ValidationError("Quantity must be greater than 0")

    # get_or_create instead of get(): a product that was created but never
    # stocked has no Inventory row yet -- a bare get() raised DoesNotExist
    # here and crashed the whole sale with a 500.
    inventory, _created = Inventory.objects.select_for_update().get_or_create(
        shop=shop,
        product_id=product_id,
        defaults={"quantity": 0}
    )

    if inventory.quantity < quantity:
        raise ValidationError(f"Not enough stock. Available: {inventory.quantity}")

    inventory.quantity -= quantity
    inventory.save()

    InventoryMovement.objects.create(
        shop=shop,
        product_id=product_id,
        change_type="OUT",
        quantity=quantity,
        note="Sale deduction"
    )


@transaction.atomic
def increase_stock(shop, product_id, quantity, note="Stock added"):
    if quantity <= 0:
        raise ValidationError("Quantity must be greater than 0")

    inventory, _ = Inventory.objects.select_for_update().get_or_create(
        shop=shop,
        product_id=product_id,
        defaults={"quantity": 0}
    )

    inventory.quantity += quantity
    inventory.save()

    InventoryMovement.objects.create(
        shop=shop,
        product_id=product_id,
        change_type="IN",
        quantity=quantity,
        note=note
    )


def is_low_stock(inventory, threshold=5):
    return inventory.quantity <= threshold