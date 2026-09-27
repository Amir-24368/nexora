from rest_framework import serializers
from django.contrib.auth import authenticate
from users.models import User
from shops.models import Shop


class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(max_length=255)
    shop_name = serializers.CharField(max_length=255)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email already exists.")
        return value

    def create(self, validated_data):
        # Create User with full_name and phone
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            full_name=validated_data['full_name'],
            phone=validated_data.get('phone', ''),
            role='OWNER',
        )
        # Create Shop with user as owner
        shop = Shop.objects.create(
            name=validated_data['shop_name'],
            owner=user,
        )
        # Assign shop to user
        user.shop = shop
        user.save(update_fields=['shop'])
        return user


class StaffCreateSerializer(serializers.Serializer):
    """Create a user inside an *existing* shop.

    Used by OWNER/MANAGER accounts (and superusers) to add employees or
    managers to their own shop -- unlike RegisterSerializer, which always
    creates a brand-new OWNER with a brand-new shop.
    """

    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(max_length=255)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=['EMPLOYEE', 'MANAGER', 'OWNER'], default='EMPLOYEE')
    # Superuser-only: place the new user in a specific shop. Non-superusers
    # are always placed in their own shop.
    shop = serializers.IntegerField(required=False)

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('User with this email already exists.')
        return value.strip().lower()

    def validate(self, attrs):
        request = self.context.get('request')
        creator = getattr(request, 'user', None)
        if creator is None or not creator.is_authenticated:
            raise serializers.ValidationError('Authentication required.')
        if not creator.is_superuser:
            if attrs.get('role') == 'OWNER':
                raise serializers.ValidationError(
                    {'role': 'Only a superuser can create an OWNER account.'}
                )
            if attrs.get('shop') is not None:
                raise serializers.ValidationError(
                    {'shop': 'Only a superuser can assign a shop explicitly.'}
                )
            if not getattr(creator, 'shop', None):
                raise serializers.ValidationError(
                    {'shop': 'Your account has no shop, so you cannot add users to one.'}
                )
        return attrs

    def create(self, validated_data):
        creator = self.context['request'].user
        if creator.is_superuser:
            shop_id = validated_data.pop('shop', None)
            shop = None
            if shop_id is not None:
                shop = Shop.objects.filter(id=shop_id).first()
                if shop is None:
                    raise serializers.ValidationError({'shop': 'Shop not found.'})
            if shop is None:
                shop = getattr(creator, 'shop', None)
        else:
            validated_data.pop('shop', None)
            shop = creator.shop
        if shop is None:
            raise serializers.ValidationError(
                {'shop': 'No shop to assign the new user to.'}
            )

        password = validated_data.pop('password')
        new_user = User.objects.create_user(
            email=validated_data['email'],
            password=password,
            username=validated_data['email'],
            full_name=validated_data.get('full_name', ''),
            phone=validated_data.get('phone', ''),
            role=validated_data.get('role', 'EMPLOYEE'),
            shop=shop,
        )
        return new_user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(email=attrs['email'], password=attrs['password'])
        if not user:
            raise serializers.ValidationError("Invalid email or password.")
        if not user.is_active:
            raise serializers.ValidationError("User account is inactive.")
        return {'user': user}


class UserSerializer(serializers.ModelSerializer):
    avatar_url = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'full_name', 'phone', 'role', 'shop', 'avatar', 'avatar_url']
        read_only_fields = ['id', 'email', 'role', 'shop']

    def get_avatar_url(self, obj):
        if not obj.avatar:
            return None
        url = obj.avatar.url
        request = self.context.get('request')
        # Return an absolute URL so Flutter's Image.network works directly.
        try:
            return request.build_absolute_uri(url) if request is not None else url
        except Exception:
            return url

    def validate_avatar(self, value):
        if value and value.size > 5 * 1024 * 1024:
            raise serializers.ValidationError("Avatar image must be under 5 MB.")
        return value