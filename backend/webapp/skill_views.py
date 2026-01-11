from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import Skill, UserSkill, PortfolioItem
from .serializers import SkillSerializer, UserSkillSerializer, PortfolioItemSerializer
from .authentication import CustomTokenAuthentication
from .permissions import IsAuthenticated
from django.utils import timezone


@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_all_skills(request):
    skills = Skill.objects.all()
    serializer = SkillSerializer(skills, many=True)
    return Response({"success": True, "skills": serializer.data})

@api_view(['GET', 'POST', 'DELETE'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_user_skills(request):
    if request.method == 'GET':
        user_skills = UserSkill.objects.filter(user=request.user).select_related('skill')
        serializer = UserSkillSerializer(user_skills, many=True)
        return Response({"success": True, "skills": serializer.data})
    
    elif request.method == 'POST':
        skill_id = request.data.get('skill_id')
        verification_status = request.data.get('verification_status', 'self_reported')
        verification_evidence = request.data.get('verification_evidence', '')
        
        if not skill_id:
            return Response({"success": False, "message": "skill_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            skill = Skill.objects.get(id=skill_id)
        except Skill.DoesNotExist:
            return Response({"success": False, "message": "Skill not found"}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if user already has this skill
        user_skill, created = UserSkill.objects.get_or_create(
            user=request.user,
            skill=skill,
            defaults={
                'verification_status': verification_status,
                'verification_evidence': verification_evidence or None,
                'date_verified': timezone.now().date() if verification_status in ['test_passed', 'verified'] else None
            }
        )
        
        if not created:
            # Update existing
            user_skill.verification_status = verification_status
            if verification_evidence:
                user_skill.verification_evidence = verification_evidence
            if verification_status in ['test_passed', 'verified']:
                user_skill.date_verified = timezone.now().date()
            user_skill.save()
        
        serializer = UserSkillSerializer(user_skill)
        return Response({"success": True, "skill": serializer.data}, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
    
    elif request.method == 'DELETE':
        skill_id = request.data.get('skill_id')
        if not skill_id:
            return Response({"success": False, "message": "skill_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user_skill = UserSkill.objects.get(user=request.user, skill_id=skill_id)
            user_skill.delete()
            return Response({"success": True, "message": "Skill removed"}, status=status.HTTP_200_OK)
        except UserSkill.DoesNotExist:
            return Response({"success": False, "message": "Skill not found"}, status=status.HTTP_404_NOT_FOUND)

# Portfolio management endpoints  
@api_view(['GET', 'POST', 'PUT', 'DELETE'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def manage_portfolio(request, portfolio_id=None):
    if request.method == 'GET':
        if portfolio_id:
            try:
                portfolio_item = PortfolioItem.objects.get(id=portfolio_id, user=request.user)
                serializer = PortfolioItemSerializer(portfolio_item, context={'request': request})
                return Response({"success": True, "portfolio": serializer.data})
            except PortfolioItem.DoesNotExist:
                return Response({"success": False, "message": "Portfolio item not found"}, status=status.HTTP_404_NOT_FOUND)
        else:
            portfolio_items = PortfolioItem.objects.filter(user=request.user).prefetch_related('skills_used').order_by('-created_at')
            serializer = PortfolioItemSerializer(portfolio_items, many=True, context={'request': request})
            return Response({"success": True, "portfolio": serializer.data})
    
    elif request.method == 'POST':
        title = request.data.get('title')
        description = request.data.get('description')
        completion_date = request.data.get('completion_date')
        skills_used_ids = request.data.get('skills_used', [])
        
        if not title or not description or not completion_date:
            return Response({"success": False, "message": "title, description, and completion_date are required"}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        portfolio_item = PortfolioItem.objects.create(
            user=request.user,
            title=title,
            description=description,
            completion_date=completion_date,
            image=request.FILES.get('image'),
            video_url=request.data.get('video_url') or None,
            project_url=request.data.get('project_url') or None,
            client_quote=request.data.get('client_quote') or None,
        )
        
        # Add skills
        if skills_used_ids:
            skills = Skill.objects.filter(id__in=skills_used_ids)
            portfolio_item.skills_used.set(skills)
        
        serializer = PortfolioItemSerializer(portfolio_item, context={'request': request})
        return Response({"success": True, "portfolio": serializer.data}, status=status.HTTP_201_CREATED)
    
    elif request.method == 'PUT':
        if not portfolio_id:
            return Response({"success": False, "message": "portfolio_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            portfolio_item = PortfolioItem.objects.get(id=portfolio_id, user=request.user)
        except PortfolioItem.DoesNotExist:
            return Response({"success": False, "message": "Portfolio item not found"}, status=status.HTTP_404_NOT_FOUND)
        
        # Update fields
        portfolio_item.title = request.data.get('title', portfolio_item.title)
        portfolio_item.description = request.data.get('description', portfolio_item.description)
        portfolio_item.completion_date = request.data.get('completion_date', portfolio_item.completion_date)
        portfolio_item.video_url = request.data.get('video_url', portfolio_item.video_url) or None
        portfolio_item.project_url = request.data.get('project_url', portfolio_item.project_url) or None
        portfolio_item.client_quote = request.data.get('client_quote', portfolio_item.client_quote) or None
        
        if 'image' in request.FILES:
            portfolio_item.image = request.FILES['image']
        
        # Update skills
        if 'skills_used' in request.data:
            skills_used_ids = request.data.get('skills_used', [])
            skills = Skill.objects.filter(id__in=skills_used_ids)
            portfolio_item.skills_used.set(skills)
        
        portfolio_item.save()
        serializer = PortfolioItemSerializer(portfolio_item, context={'request': request})
        return Response({"success": True, "portfolio": serializer.data})
    
    elif request.method == 'DELETE':
        if not portfolio_id:
            return Response({"success": False, "message": "portfolio_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            portfolio_item = PortfolioItem.objects.get(id=portfolio_id, user=request.user)
            portfolio_item.delete()
            return Response({"success": True, "message": "Portfolio item deleted"}, status=status.HTTP_200_OK)
        except PortfolioItem.DoesNotExist:
            return Response({"success": False, "message": "Portfolio item not found"}, status=status.HTTP_404_NOT_FOUND)
