from django.db import transaction
from rest_framework.exceptions import ValidationError
from decimal import Decimal

from orders.models import Cart, CartItem, Order, OrderLine, Payment, InventoryTransaction
from inventory.models import Inventory
from products.models import Product


# ---------------- CART ----------------

def add_to_cart(shop, user, product, quantity=1):
    cart, _ = Cart.objects.get_or_create(
        shop=shop,
        created_by=user,
        status="ACTIVE"
    )

    item, created = CartItem.objects.get_or_create(
        cart=cart,
        product=product,
        defaults={"quantity": quantity}
    )

    if not created:
        item.quantity += quantity
        item.save()

    return cart


# ---------------- CHECKOUT ENGINE ----------------

@transaction.atomic
def checkout_cart(shop, user, payment_method="CASH"):
    cart = Cart.objects.select_for_update().filter(
        shop=shop,
        created_by=user,
        status="ACTIVE"
    ).first()

    if not cart:
        raise ValidationError("Cart not found")

    items = CartItem.objects.filter(cart=cart).select_related("product")

    if not items.exists():
        raise ValidationError("Cart is empty")

    order = Order.objects.create(
        shop=shop,
        user=user,
        status="PENDING"
    )

    total = Decimal("0.00")

    for item in items:
        product = item.product

        inventory = Inventory.objects.select_for_update().get(
            shop=shop,
            product=product
        )

        if inventory.quantity < item.quantity:
            raise ValidationError(f"Not enough stock for {product.name}")

        inventory.quantity -= item.quantity
        inventory.save()

        line_total = product.sale_price * item.quantity

        OrderLine.objects.create(
            order=order,
            product=product,
            product_name=product.name,
            unit_price=product.sale_price,
            quantity=item.quantity,
            line_total=line_total
        )

        InventoryTransaction.objects.create(
            shop=shop,
            product=product,
            change=-item.quantity,
            reason="SALE",
            reference_id=str(order.pk)
        )

        total += line_total

    order.total_price = total
    order.save()

    Payment.objects.create(
        order=order,
        method=payment_method,
        amount=total,
        status="PENDING"
    )

    cart.status = "CONVERTED"
    cart.save()

    # Reflect the order in the sales ledger so RFM/analytics see every purchase,
    # whether it came from the shop dashboard or the customer app.
    from sales.models import Sale
    Sale.objects.create(
        shop=shop,
        customer=None,
        total_amount=total,
        status='COMPLETED',
        payment_status='PAID' if payment_method != 'CASH' else 'UNPAID',
    )

    return order


# ---------------- ORDER STATUS ENGINE ----------------

def update_order_status(order, new_status):
    valid = ["PENDING", "PAID", "FAILED", "PROCESSING", "SHIPPED", "DELIVERED", "CANCELLED", "REFUNDED"]

    if new_status not in valid:
        raise ValidationError("Invalid status")

    order.status = new_status
    order.save()

    return order


def update_payment_status(order, status, transaction_id=None):
    """Update payment status for an order."""
    payment = order.payments.first()
    if not payment:
        raise ValidationError("No payment found for this order")

    payment.status = status
    if transaction_id:
        payment.transaction_id = transaction_id
    payment.save()

    if status == "PAID":
        order.status = "PAID"
        order.save()

    return order