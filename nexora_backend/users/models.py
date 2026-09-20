from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        # If username is not provided, use email
        if 'username' not in extra_fields or not extra_fields['username']:
            extra_fields['username'] = email
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractUser):
    ROLE_CHOICES = [
        ("OWNER", "Owner"),
        ("MANAGER", "Manager"),
        ("EMPLOYEE", "Employee"),
    ]

    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="EMPLOYEE")
    shop = models.ForeignKey(
        "shops.Shop",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="employees"
    )
    email = models.EmailField(unique=True)

    # New fields for full_name and phone
    full_name = models.CharField(max_length=255, blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True, null=True)

    # Profile picture (uploaded from the app's profile page)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)

    objects = UserManager()  # type: ignore

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.email