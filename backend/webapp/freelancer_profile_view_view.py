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
from django.db.models import Avg


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
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication, CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def view_get_user_ratings(request, user_id):
    """
    Get all ratings for a specific user
    GET /api/freelancers/{user_id}/ratings/
    """
    try:
        import json
        
        # Get the user
        target_user = User.objects.get(user_id=user_id)
        
        # Get ALL ratings this user has received (regardless of rating_type)
        ratings = Rating.objects.filter(
            rated_user=target_user
        ).select_related(
            'rater', 
            'task',
            'rater_employer'
        ).order_by('-created_at')
        
        print(f"Found {ratings.count()} total ratings received by user")
        
        # Prepare the data
        ratings_data = []
        for rating in ratings:
            rater = rating.rater
            
            # Initialize work passport data
            work_passport_data = {}
            
            # 1. Add category_scores from the dedicated field
            if rating.category_scores:
                work_passport_data['category_scores'] = rating.category_scores
            
            # 2. Add the new dedicated fields
            if rating.would_recommend is not None:
                work_passport_data['would_recommend'] = rating.would_recommend
            
            if rating.would_rehire is not None:
                work_passport_data['would_rehire'] = rating.would_rehire
            
            if rating.performance_tags:
                work_passport_data['performance_tags'] = rating.performance_tags
            
            if rating.calculated_composite is not None:
                work_passport_data['calculated_composite'] = str(rating.calculated_composite)
            
            # 3. Parse extended data from review field if it contains JSON (for legacy data)
            extended_data = {}
            clean_comment = rating.review or ''
            
            if rating.review and '__EXTENDED_DATA__' in rating.review:
                try:
                    # Extract JSON from the review
                    json_start = rating.review.find('{')
                    if json_start != -1:
                        json_string = rating.review[json_start:]
                        extended_data = json.loads(json_string)
                        
                        # Extract clean comment (remove JSON part)
                        clean_comment_end = rating.review.find('__EXTENDED_DATA__')
                        if clean_comment_end > 0:
                            clean_comment = rating.review[:clean_comment_end].strip()
                except Exception as e:
                    print(f"Error parsing JSON from review: {e}")
                    # If parsing fails, keep the original review
                    clean_comment = rating.review
            
            # 4. Merge extended data with work passport data (for backward compatibility)
            # Only add fields if they don't already exist from dedicated fields
            if extended_data:
                for key, value in extended_data.items():
                    if key not in work_passport_data or work_passport_data[key] is None:
                        work_passport_data[key] = value
            
            # Get employer info if available
            employer_name = None
            employer_avatar = None
            if rating.rater_employer:
                employer_name = rating.rater_employer.username
                if hasattr(rating.rater_employer, 'profile_picture') and rating.rater_employer.profile_picture:
                    try:
                        employer_avatar = rating.rater_employer.profile_picture.url
                    except:
                        employer_avatar = None
            
            ratings_data.append({
                'id': rating.rating_id,
                'rating': rating.score,
                'comment': clean_comment,
                'review': rating.review or '',  # Keep original for backward compatibility
                'category_scores': rating.category_scores,
                'work_passport_data': work_passport_data if work_passport_data else None,
                'would_recommend': rating.would_recommend,  # Direct field access
                'would_rehire': rating.would_rehire,        # Direct field access
                'performance_tags': rating.performance_tags, # Direct field access
                'rater_name': employer_name or (rater.name or rater.username or "Anonymous"),
                'rater_id': rater.user_id,
                'employer_name': employer_name,
                'employer_avatar': employer_avatar,
                'task_title': rating.task.title if rating.task else 'Task',
                'task_id': rating.task_id if rating.task else None,
                'rating_type': rating.rating_type,
                'created_at': rating.created_at,
            })
        
        # Calculate average rating
        avg_rating = ratings.aggregate(avg_rating=Avg('score'))['avg_rating'] or 0
        total_ratings = ratings.count()
        
        print(f"Average: {avg_rating}, Total: {total_ratings}")
        
        return Response({
            'success': True,
            'ratings': ratings_data,
            'average_rating': round(float(avg_rating), 1),
            'total_ratings': total_ratings,
            'user_name': target_user.name or target_user.username,
            'user_id': user_id
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({
            'success': False,
            'message': f'User with ID {user_id} not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return Response({
            'success': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)    