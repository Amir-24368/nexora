from django.db import transaction
from django.utils import timezone
from decimal import Decimal
from rest_framework.exceptions import ValidationError

from suppliers.models import (
    PurchaseOrder,
    PurchaseOrderLine,
)

from inventory.models import Inventory

from products.models import Product


# ==========================================================
# CREATE PURCHASE ORDER
# ==========================================================

@transaction.atomic
def create_purchase_order(
    shop,
    supplier,
    user,
    items,
    expected_delivery=None,
    notes=""
):

    if not items:
        raise ValidationError(
            "Purchase order requires products"
        )


    purchase_order = PurchaseOrder.objects.create(
        shop=shop,
        supplier=supplier,
        created_by=user,
        expected_delivery=expected_delivery,
        notes=notes,
        status="DRAFT"
    )


    subtotal = Decimal("0")


    for item in items:

        product_id = item.get("product")

        quantity = item.get(
            "quantity",
            0
        )

        price = item.get(
            "purchase_price",
            0
        )


        if quantity <= 0:
            raise ValidationError(
                "Quantity must be greater than zero"
            )


        if price <= 0:
            raise ValidationError(
                "Purchase price must be greater than zero"
            )


        product = Product.objects.get(
            id=product_id
        )


        line = PurchaseOrderLine.objects.create(
            purchase_order=purchase_order,
            product=product,
            ordered_quantity=quantity,
            purchase_price=price
        )


        subtotal += line.subtotal



    purchase_order.subtotal = subtotal
    purchase_order.total = subtotal

    purchase_order.save()


    return purchase_order



# ==========================================================
# APPROVE PURCHASE ORDER
# ==========================================================

@transaction.atomic
def approve_purchase_order(
    purchase_order,
    user
):

    if purchase_order.status != "DRAFT":

        raise ValidationError(
            "Only draft orders can be approved"
        )


    purchase_order.status = "APPROVED"

    purchase_order.approved_by = user

    purchase_order.save()


    return purchase_order



# ==========================================================
# RECEIVE GOODS
# ==========================================================

@transaction.atomic
def receive_purchase_order(
    purchase_order,
    received_items
):

    if purchase_order.status not in [
        "APPROVED",
        "ORDERED",
        "PARTIALLY_RECEIVED"
    ]:

        raise ValidationError(
            "Purchase order cannot be received"
        )



    for item in received_items:


        line = PurchaseOrderLine.objects.select_for_update().get(
            id=item["line_id"]
        )


        quantity_received = item.get(
            "quantity",
            0
        )


        if quantity_received <= 0:

            raise ValidationError(
                "Invalid received quantity"
            )



        remaining = (
            line.ordered_quantity
            -
            line.received_quantity
        )


        if quantity_received > remaining:

            raise ValidationError(
                "Received quantity exceeds order"
            )



        line.received_quantity += quantity_received

        line.save()



        inventory, created = Inventory.objects.get_or_create(
            shop=purchase_order.shop,
            product=line.product,
            defaults={
                "quantity":0
            }
        )


        inventory.quantity += quantity_received

        inventory.save()



    all_received = True


    for line in purchase_order.lines.all():

        if line.received_quantity < line.ordered_quantity:

            all_received = False
            break



    if all_received:

        purchase_order.status = "RECEIVED"

        purchase_order.received_date = timezone.now().date()


    else:

        purchase_order.status = "PARTIALLY_RECEIVED"



    purchase_order.save()


    return purchase_order



# ==========================================================
# CANCEL PURCHASE ORDER
# ==========================================================

@transaction.atomic
def cancel_purchase_order(
    purchase_order
):

    if purchase_order.status == "RECEIVED":

        raise ValidationError(
            "Received orders cannot be cancelled"
        )


    purchase_order.status = "CANCELLED"

    purchase_order.save()


    return purchase_order