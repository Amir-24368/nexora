from rest_framework.permissions import BasePermission


class IsShopMember(BasePermission):
    def has_object_permission(self, request, view, obj) -> bool:  # type: ignore[override]
        user_shop = getattr(request.user, 'shop', None)
        obj_shop = getattr(obj, 'shop', None)
        # Superuser can access anything
        if request.user.is_superuser:
            return True
        return bool(user_shop and obj_shop and user_shop == obj_shop)