from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AbstractUser
from typing import cast
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer

User = get_user_model()


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = cast(AbstractUser, serializer.save())
            refresh = RefreshToken.for_user(user)
            return Response({
                'status': 'success',
                'data': {
                    'user': UserSerializer(user).data,
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                }
            }, status=status.HTTP_201_CREATED)
        return Response({
            'status': 'error',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            validated_data = serializer.validated_data
            user = validated_data.get('user') if isinstance(validated_data, dict) else None
            if not isinstance(user, User):
                return Response({
                    'status': 'error',
                    'errors': {'user': ['User not found']}
                }, status=status.HTTP_400_BAD_REQUEST)
            refresh = RefreshToken.for_user(user)
            return Response({
                'status': 'success',
                'data': {
                    'user': UserSerializer(user).data,
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                }
            })
        return Response({
            'status': 'error',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'status': 'success', 'message': 'Logged out successfully'})
        except Exception:
            return Response({'status': 'error'}, status=status.HTTP_400_BAD_REQUEST)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user, context={'request': request})
        return Response({'status': 'success', 'data': serializer.data})

    def patch(self, request):
        serializer = UserSerializer(
            request.user, data=request.data, partial=True,
            context={'request': request},
        )
        if serializer.is_valid():
            serializer.save()
            return Response({'status': 'success', 'data': serializer.data})
        return Response({'status': 'error', 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)