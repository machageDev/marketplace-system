from rest_framework import permissions
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from .models import EmployerToken, UserToken


class IsAuthenticated(permissions.BasePermission):
    """
    Custom permission that works with your User model
    """
    def has_permission(self, request, view):
        return bool(request.user and getattr(request.user, 'is_authenticated', False))


class CustomTokenAuthentication(BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        print(f" RAW Auth header: {auth_header}")

        if not auth_header or not auth_header.startswith('Bearer '):
            print(" No Bearer token found")
            return None

        try:
            # Extract token
            token_key = auth_header.split(' ')[1].strip()
            print(f" Looking for token: '{token_key}'")

            # Find the token
            user_token = UserToken.objects.get(key=token_key)
            user = user_token.user

            print(f" SUCCESS: Authenticated {user.name} (ID: {user.user_id})")

            # Add required attributes for DRF
            user.is_authenticated = True
            user.is_anonymous = False

            return (user, user_token)

        except UserToken.DoesNotExist:
            print(f" Token not found: {token_key}")
            raise AuthenticationFailed('Invalid token')
        except Exception as e:
            print(f" Authentication error: {e}")
            raise AuthenticationFailed('Authentication failed')

    def authenticate_header(self, request):
        return 'Bearer'

class EmployerTokenAuthentication(BaseAuthentication):
    """
    Custom authentication class for Employer model
    """
    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        print(f" RAW Auth header: {auth_header}")

        if not auth_header or not auth_header.startswith('Bearer '):
            print(" No Bearer token found")
            return None

        try:
            # Extract token key
            token_key = auth_header.split(' ')[1].strip()
            print(f" Looking for token: '{token_key}'")

            # Find employer token
            employer_token = EmployerToken.objects.get(key=token_key)
            employer = employer_token.employer

            print(f" ✅ SUCCESS: Authenticated employer {employer.username} (ID: {employer.employer_id})")

            # Required by DRF for authentication checks
            employer.is_authenticated = True
            employer.is_anonymous = False

            return (employer, employer_token)

        except EmployerToken.DoesNotExist:
            print(f" ❌ Token not found: {token_key}")
            raise AuthenticationFailed('Invalid token')
        except Exception as e:
            print(f" ⚠️ Authentication error: {e}")
            raise AuthenticationFailed('Authentication failed')

    def authenticate_header(self, request):
        return 'Bearer'