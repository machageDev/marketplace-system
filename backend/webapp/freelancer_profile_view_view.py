"""
New view for clients to view freelancer profiles (read-only)
Separate from the existing profile management endpoint
Allows both clients (employers) and freelancers to view any freelancer profile
"""
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.exceptions import NotFound, PermissionDenied
from .models import User, UserProfile, Rating
from .serializers import UserProfileSerializer
from .authentication import CustomTokenAuthentication, EmployerTokenAuthentication
from .permissions import IsAuthenticated


@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication, CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def view_freelancer_profile(request, user_id):
   
    try:
        # Get the freelancer user by ID
        freelancer_user = User.objects.get(user_id=user_id)
        
        # Get the freelancer's profile
        try:
            profile = UserProfile.objects.get(user=freelancer_user)
        except UserProfile.DoesNotExist:
            return Response({
                "success": False,
                "message": f"Profile not found for freelancer ID {user_id}",
                "profile": None
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Serialize the profile (includes verified_skills, portfolio_items, work_passport_data)
        profile_data = UserProfileSerializer(profile).data
        
        # Handle profile picture URL
        if profile.profile_picture:
            profile_data['profile_picture'] = request.build_absolute_uri(profile.profile_picture.url)
        
        # Add review count to work_passport_data
        reviews = Rating.objects.filter(rated_user=freelancer_user)
        review_count = reviews.count()
        
        # Enhance work_passport_data with review_count if it exists
        if 'work_passport_data' in profile_data:
            profile_data['work_passport_data']['review_count'] = review_count
        
        return Response({
            "success": True,
            "message": "Profile retrieved successfully",
            "profile": profile_data,
            "freelancer_id": user_id,
            "freelancer_name": freelancer_user.name
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({
            "success": False,
            "message": f"Freelancer with ID {user_id} not found",
            "profile": None
        }, status=status.HTTP_404_NOT_FOUND)
        
    except Exception as e:
        print(f"Error fetching freelancer profile: {e}")
        return Response({
            "success": False,
            "message": f"Error fetching profile: {str(e)}"
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
