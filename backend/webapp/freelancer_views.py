"""
Freelancer profile endpoints for read-only public data
These endpoints are designed to be safe for public viewing
"""
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.exceptions import NotFound
from .models import User, UserProfile, UserSkill, PortfolioItem, TaskCompletion, Rating, Contract
from .serializers import UserSkillSerializer, PortfolioItemSerializer
from .authentication import CustomTokenAuthentication, EmployerTokenAuthentication
from .permissions import IsAuthenticated
from django.utils import timezone


@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication, EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_freelancer_work_passport(request, user_id=None):
    """
    GET /api/freelancer/work-passport/ or /api/freelancer/work-passport/<user_id>/
    Returns computed work passport data for a freelancer
    """
    # If user_id is provided, get that user's work passport (for viewing other profiles)
    # Otherwise, get the authenticated user's work passport
    if user_id:
        try:
            target_user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return Response({
                "success": False,
                "message": "Freelancer not found"
            }, status=status.HTTP_404_NOT_FOUND)
    else:
        target_user = request.user
    
    # Check if user has a profile
    try:
        profile = UserProfile.objects.get(user=target_user)
    except UserProfile.DoesNotExist:
        return Response({
            "success": False,
            "message": "Profile not found"
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Calculate work passport data
    completed_tasks = TaskCompletion.objects.filter(user=target_user, status='approved')
    total_earnings = sum(float(task.amount) for task in completed_tasks)
    
    ratings = Rating.objects.filter(rated_user=target_user)
    avg_rating = 0
    review_count = ratings.count()
    if ratings.exists():
        avg_rating = sum(r.score for r in ratings) / review_count
    
    # Count verified skills (test_passed or verified status)
    verified_skills_count = UserSkill.objects.filter(
        user=target_user,
        verification_status__in=['test_passed', 'verified']
    ).count()
    
    # Calculate platform tenure (days since first contract or task completion)
    platform_tenure_days = 0
    try:
        earliest_contract = Contract.objects.filter(freelancer=target_user).order_by('start_date').first()
        earliest_completion = completed_tasks.order_by('completion_date').first()
        
        earliest_date = None
        if earliest_contract and earliest_completion:
            earliest_date = min(earliest_contract.start_date, earliest_completion.completion_date)
        elif earliest_contract:
            earliest_date = earliest_contract.start_date
        elif earliest_completion:
            earliest_date = earliest_completion.completion_date
        
        if earliest_date:
            platform_tenure_days = (timezone.now().date() - earliest_date).days
    except:
        pass
    
    # Client satisfaction summary
    satisfaction_summary = "No ratings yet"
    if review_count > 0:
        positive_ratings = ratings.filter(score__gte=4).count()
        satisfaction_percentage = (positive_ratings / review_count) * 100
        satisfaction_summary = f"{satisfaction_percentage:.0f}% positive ({positive_ratings}/{review_count})"
    
    work_passport_data = {
        "total_earnings": total_earnings,
        "completed_tasks": completed_tasks.count(),
        "avg_rating": round(avg_rating, 2),
        "review_count": review_count,
        "verified_skills_count": verified_skills_count,
        "platform_tenure_days": platform_tenure_days,
        "client_satisfaction_summary": satisfaction_summary
    }
    
    return Response({
        "success": True,
        "work_passport": work_passport_data
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication, EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_freelancer_verified_skills(request, user_id=None):
    """
    GET /api/freelancer/verified-skills/ or /api/freelancer/verified-skills/<user_id>/
    Returns only verified skills (test_passed or verified status) for a freelancer
    """
    # If user_id is provided, get that user's skills (for viewing other profiles)
    # Otherwise, get the authenticated user's skills
    if user_id:
        try:
            target_user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return Response({
                "success": False,
                "message": "Freelancer not found"
            }, status=status.HTTP_404_NOT_FOUND)
    else:
        target_user = request.user
    
    # Get only verified skills
    verified_skills = UserSkill.objects.filter(
        user=target_user,
        verification_status__in=['test_passed', 'verified']
    ).select_related('skill').order_by('-date_verified', '-id')
    
    serializer = UserSkillSerializer(verified_skills, many=True)
    
    return Response({
        "success": True,
        "verified_skills": serializer.data,
        "count": len(serializer.data)
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication, EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_freelancer_portfolio(request, user_id=None):
    """
    GET /api/freelancer/portfolio/ or /api/freelancer/portfolio/<user_id>/
    Returns portfolio items for a freelancer
    """
    # If user_id is provided, get that user's portfolio (for viewing other profiles)
    # Otherwise, get the authenticated user's portfolio
    if user_id:
        try:
            target_user = User.objects.get(user_id=user_id)
        except User.DoesNotExist:
            return Response({
                "success": False,
                "message": "Freelancer not found"
            }, status=status.HTTP_404_NOT_FOUND)
    else:
        target_user = request.user
    
    # Get portfolio items
    portfolio_items = PortfolioItem.objects.filter(
        user=target_user
    ).prefetch_related('skills_used').order_by('-completion_date', '-created_at')
    
    # Pass request context for image URL building
    serializer = PortfolioItemSerializer(portfolio_items, many=True, context={'request': request})
    
    return Response({
        "success": True,
        "portfolio": serializer.data,
        "count": len(serializer.data)
    }, status=status.HTTP_200_OK)
