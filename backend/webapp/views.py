from decimal import Decimal
import stripe
from django.conf import settings
from django.http import JsonResponse
import json
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import authentication_classes, permission_classes, api_view
from rest_framework.response import Response
from rest_framework import status
from datetime import date, timezone
import random
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from django.contrib.auth.tokens import default_token_generator
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db import IntegrityError, transaction
from rest_framework import status
from django.core.mail import send_mail
from .models import Contract, Employer, EmployerProfile, EmployerRating, EmployerToken, FreelancerRating, Proposal, Task, TaskCompletion, UserProfile, Wallet
from django.contrib.auth.hashers import check_password
from .models import  User
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import render
from django.db.models import Sum
from django.contrib import messages
from django.contrib.auth.hashers import make_password
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import authentication_classes, permission_classes, api_view
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from webapp.serializers import ContractSerializer, EmployerLoginSerializer, EmployerProfileSerializer, EmployerRatingSerializer, EmployerRegisterSerializer, EmployerSerializer, FreelancerRatingSerializer, LoginSerializer, ProposalSerializer, RegisterSerializer, TaskCompletionSerializer, TaskCreateSerializer, TaskSerializer, UserProfileSerializer, WalletSerializer
from .authentication import CustomTokenAuthentication, EmployerTokenAuthentication
from .permissions import IsAuthenticated  
from .models import UserProfile
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from .authentication import EmployerTokenAuthentication, IsAuthenticated
from .models import Task, Proposal

@csrf_exempt
@api_view(['POST', 'PUT'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def apiuserprofile(request):
    print(f"=== PROFILE API CALLED ===")
    print(f"AUTH SUCCESS: {request.user.name} (ID: {request.user.user_id})")
    print(f"Method: {request.method}")
    
    if request.method == 'POST':
        print("POST - Creating new profile...")
        serializer = UserProfileSerializer(data=request.data)
        if serializer.is_valid():
            profile = serializer.save(user=request.user)  
            return Response(UserProfileSerializer(profile).data, status=status.HTTP_201_CREATED)
        print("POST errors:", serializer.errors)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'PUT':
        print("PUT data:", request.data)
        print("FILES:", request.FILES)
        
        try:
            # Try to get existing profile
            profile = UserProfile.objects.get(user=request.user)
            print(f" Found existing profile: {profile}")
            
            # UPDATE existing profile
            serializer = UserProfileSerializer(profile, data=request.data, partial=True)
            if serializer.is_valid():
                updated_profile = serializer.save()
                print(" Profile updated successfully")
                return Response(UserProfileSerializer(updated_profile).data, status=status.HTTP_200_OK)
            print(" PUT validation errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        except UserProfile.DoesNotExist:
            print(" No profile found - CREATING new profile")
            
            serializer = UserProfileSerializer(data=request.data)
            if serializer.is_valid():
                new_profile = serializer.save(user=request.user)
                print(" New profile created successfully")
                return Response(UserProfileSerializer(new_profile).data, status=status.HTTP_201_CREATED)
            print(" CREATE validation errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)  
@csrf_exempt
@api_view(['GET'])
def debug_auth_test(request):
   
    from .models import UserToken
    
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    print(f" DEBUG - Raw header: {auth_header}")
    
    if auth_header.startswith('Bearer '):
        token = auth_header.split(' ')[1].strip()
        print(f" DEBUG - Token: '{token}'")
        
        try:
            user_token = UserToken.objects.get(key=token)
            return Response({
                "status": "success", 
                "user": user_token.user.name,
                "user_id": user_token.user.user_id
            })
        except UserToken.DoesNotExist:
            return Response({"status": "token_not_found"}, status=401)
        except Exception as e:
            return Response({"status": "error", "message": str(e)}, status=500)
    
    return Response({"status": "no_token"}, status=401)    
@api_view(['POST'])
@permission_classes([AllowAny])
def apiregister(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        name = serializer.validated_data['name'].strip()
        email = serializer.validated_data['email'].strip().lower()
        password = serializer.validated_data['password']
        phone_no = serializer.validated_data['phoneNo'].strip()   

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "User with this email already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )
        if User.objects.filter(name=name).exists():
            return Response(
                {"error": "Username already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        with transaction.atomic():
            user = User(
                name=name,
                email=email,
                phoneNo=phone_no,   
            )
            user.set_password(password)
            user.save()

        return Response(
            {"message": "User registered successfully."},
            status=status.HTTP_201_CREATED
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@csrf_exempt
@require_http_methods(["GET", "POST"])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_ratings_list(request):
   
    try:
        if request.method == 'GET':
            ratings = EmployerRating.objects.all()
            serializer = EmployerRatingSerializer(ratings, many=True)
            return JsonResponse(serializer.data, safe=False)
            
        elif request.method == 'POST':
            # For POST requests with JSON data
            import json
            data = json.loads(request.body)
            
            # Add the employer from the authenticated user
            data['employer'] = request.user
            
            serializer = EmployerRatingSerializer(data=data)
            if serializer.is_valid():
                serializer.save()
                return JsonResponse(serializer.data, status=201)
            return JsonResponse(serializer.errors, status=400)
            
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@require_http_methods(["GET", "PUT", "DELETE"])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_rating_detail(request):
   
    try:
        rating = EmployerRating.objects.get()
        
        if request.method == 'GET':
            serializer = EmployerRatingSerializer(rating)
            return JsonResponse(serializer.data)
            
        elif request.method == 'PUT':
            # Check if user owns this rating
            if rating.employer != request.user:
                return JsonResponse({"error": "Not authorized"}, status=403)
                
            import json
            data = json.loads(request.body)
            serializer = EmployerRatingSerializer(rating, data=data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return JsonResponse(serializer.data)
            return JsonResponse(serializer.errors, status=400)
            
        elif request.method == 'DELETE':
            # Check if user owns this rating
            if rating.employer != request.user:
                return JsonResponse({"error": "Not authorized"}, status=403)
                
            rating.delete()
            return JsonResponse({"message": "Rating deleted successfully"}, status=204)
            
    except EmployerRating.DoesNotExist:
        return JsonResponse({"error": "Rating not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@require_http_methods(["GET"])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def my_employer_ratings(request):
   
    try:
        ratings = EmployerRating.objects.filter(employer=request.user)
        serializer = EmployerRatingSerializer(ratings, many=True)
        return JsonResponse(serializer.data, safe=False)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
@require_http_methods(["GET"])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def freelancer_ratings(request, freelancer_id):
    
    try:
        ratings = EmployerRating.objects.filter(freelancer_id=freelancer_id)
        serializer = EmployerRatingSerializer(ratings, many=True)
        return JsonResponse(serializer.data, safe=False)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


   
from .models import User, UserToken
import uuid

@api_view(['POST'])
@permission_classes([AllowAny])
def apilogin(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        name = serializer.validated_data['name'].strip()
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(name=name)

            if user.check_password(password):  
                
                token, created = UserToken.objects.get_or_create(user=user)
                if not created:
                    
                    token.key = uuid.uuid4()
                    token.save()

                return Response(
                    {
                        "message": "Login successful",
                        "user_id": user.user_id,
                        "name": user.name,
                        "token": str(token.key),
                    },
                    status=status.HTTP_200_OK
                )
            else:
                return Response({"error": "Invalid login"}, status=status.HTTP_400_BAD_REQUEST)

        except User.DoesNotExist:
            return Response({"error": "Invalid login"}, status=status.HTTP_400_BAD_REQUEST)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def apiforgot_password(request):
    try:
        email = request.data.get('email')
        if not email:
            return Response({"error": "Please fill all fields"}, status=status.HTTP_400_BAD_REQUEST)
        if not User.objects.filter(email=email).exists():
            return Response({"error": "User does not exist"}, status=status.HTTP_400_BAD_REQUEST)
        user = User.objects.get(email=email)
         
        token = default_token_generator.make_token(user)
        reset_url = request.build_absolute_uri(reverse('password-reset-confirm', kwargs={'token': token, 'uidb64': user.pk}))

         
        send_mail(
            subject="Password Reset Request",
            message=f"Click the link below to reset your password:\n{reset_url}",
            from_email="no-reply@yourdomain.com",
            recipient_list=[email],
            fail_silently=False,
        )
        return Response({"message": "Password reset successfully"}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)        
    


@csrf_exempt
@require_http_methods(["POST"])
def apisubmit_proposal(request):
    try:
        print(" PROPOSAL SUBMISSION STARTED")
        
        
        auth = CustomTokenAuthentication()
        auth_result = auth.authenticate(request)
        
        if auth_result is None:
            print(" AUTHENTICATION FAILED - No valid token")
            return JsonResponse({"error": "Authentication failed"}, status=401)
            
        request.user, request.auth = auth_result
        
        
        user_identifier = getattr(request.user, 'username', 
                                getattr(request.user, 'email', 
                                        getattr(request.user, 'name', 
                                                f"User_{request.user}")))
        print(f" USER AUTHENTICATED: {user_identifier}")
        print(f" USER ID: {request.user}")

        # Get form data - use request.POST for multipart forms
        task_id = request.POST.get("task_id")
        bid_amount = request.POST.get("bid_amount")
        title = request.POST.get("title", "")
        cover_letter_file = request.FILES.get('cover_letter_file')

        print(f" RECEIVED FORM DATA:")
        print(f"   - task_id: {task_id}")
        print(f"   - bid_amount: {bid_amount}")
        print(f"   - title: {title}")
        print(f"   - file_received: {cover_letter_file is not None}")

        
        if not task_id:
            return JsonResponse({"error": "Task ID is required"}, status=400)
        if not cover_letter_file:
            return JsonResponse({"error": "Cover letter PDF file is required"}, status=400)

        
        try:
            task = Task.objects.get(pk=task_id)
            print(f" Task found: {task.title}")
        except Task.DoesNotExist:
            return JsonResponse({"error": "Task not found"}, status=404)

       
        if Proposal.objects.filter(task=task, freelancer=request.user).exists():
            return JsonResponse({"error": "You have already submitted a proposal for this task"}, status=400)

        
        proposal = Proposal(
            task=task,
            freelancer=request.user,
            bid_amount=float(bid_amount) if bid_amount else 0.0,      
            
            #cover_letter='Cover letter provided as PDF file',
        )
        proposal.save()
        print(f"Proposal saved with ID: {proposal}")

        # Save file
        if cover_letter_file and hasattr(proposal, 'cover_letter_file'):
            proposal.cover_letter_file.save(cover_letter_file.name, cover_letter_file)
            proposal.save()
            print(f" PDF file saved: {cover_letter_file.name}")

        return JsonResponse({
            "id": proposal,
            "task_id": proposal.task_id,
            "freelancer_id": proposal.freelancer.id,
            "cover_letter": proposal.cover_letter,
            "bid_amount": float(proposal.bid_amount),
            "status": proposal.status,
            "title": proposal.title,
            "message": "Proposal submitted successfully"
        }, status=201)

    except Exception as e:
        print(f" ERROR: {str(e)}")
        import traceback
        print(f" TRACEBACK: {traceback.format_exc()}")
        return JsonResponse({"error": f"Server error: {str(e)}"}, status=500)
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def apitask_list(request):
    
    try:
        
        tasks = Task.objects.select_related('employer').prefetch_related('employer__profile').all()
        
        data = []
        for task in tasks:
            
            employer_profile = getattr(task.employer, 'profile', None)
            
            task_data = {
                'task_id': task.task_id,
                'title': task.title,
                'description': task.description,
                'is_approved': task.is_approved,
                'created_at': task.created_at.isoformat() if task.created_at else None,
                'assigned_user': task.assigned_user.user_id if task.assigned_user else None,
                'completed': False,  
                'employer': {
                    'id': task.employer.employer_id,
                    'username': task.employer.username,
                    'contact_email': task.employer.contact_email,
                    'company_name': employer_profile.company_name if employer_profile else None,
                    'profile_picture': employer_profile.profile_picture.url if employer_profile and employer_profile.profile_picture else None,
                    'phone_number': employer_profile.phone_number if employer_profile else None,
                }
            }
            data.append(task_data)
        
        print(f" Returning {len(data)} tasks with employer data")
        return Response(data)
        
    except Exception as e:
        print(f" Error in apitask_list: {e}")
        return Response({"error": str(e)}, status=500)


@api_view(['GET', 'PUT', 'DELETE'])
def apitask_detail(request, pk):
    try:
        task = Task.objects.get(pk=pk)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = TaskSerializer(task)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = TaskSerializer(task, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        task.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)




@api_view(["GET"])
def freelancer_contracts(request, freelancer_id):
   
    contracts = Contract.objects.filter(freelancer_id=freelancer_id)
    serializer = ContractSerializer(contracts, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
def contract_detail(request, contract_id):
    
    try:
        contract = Contract.objects.get(pk=contract_id)
    except Contract.DoesNotExist:
        return Response({"error": "Contract not found"}, status=status.HTTP_404_NOT_FOUND)

    serializer = ContractSerializer(contract)
    return Response(serializer.data, status=status.HTTP_200_OK)



@api_view(['POST'])
@permission_classes([AllowAny])
def employer_login(request):
    username = request.data.get('username')
    password = request.data.get('password')

    print("Received data:", request.data)

    try:
        employer = Employer.objects.get(username=username, password=password)
        print(f"Found employer: {employer.username}")

        
        token, created = EmployerToken.objects.get_or_create(employer=employer)
        if not created:
            token.key = uuid.uuid4()  
            token.save()

        print(f"Token generated/saved: {token.key}")

        return Response({
            'success': True,
            'token': str(token.key),
            'employer': {
                'id': employer.employer_id,
                'username': employer.username,
                'email': employer.contact_email,
            }
        }, status=status.HTTP_200_OK)

    except Employer.DoesNotExist:
        print(" Invalid credentials")
        return Response({
            'success': False,
            'error': 'Invalid credentials'
        }, status=status.HTTP_401_UNAUTHORIZED)

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

@api_view(['POST'])
@permission_classes([AllowAny])
def employer_register(request):
    serializer = EmployerRegisterSerializer(data=request.data)
    if serializer.is_valid():
        username = serializer.validated_data['username'].strip()
        password = serializer.validated_data['password']
        contact_email = serializer.validated_data['contact_email']
        phone_number = serializer.validated_data.get('phone_number')

        
        if Employer.objects.filter(username=username).exists():
            return Response({"error": "Username already exists"}, status=status.HTTP_400_BAD_REQUEST)

        
        if Employer.objects.filter(contact_email=contact_email).exists():
            return Response({"error": "Email already exists"}, status=status.HTTP_400_BAD_REQUEST)

        
        employer = Employer.objects.create(
            username=username,
            password=password,
            contact_email=contact_email,
            phone_number=phone_number
        )

        return Response(
            {
                "message": "Registration successful",
                "employer_id": employer.employer_id,
                "username": employer.username,
                "contact_email": employer.contact_email,
            },
            status=status.HTTP_201_CREATED
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
# Get Employer by ID
@api_view(['GET'])
def get_employer(request, pk):
    
    employer = get_object_or_404(Employer, pk=pk)
    serializer = EmployerSerializer(employer)
    return Response(serializer.data)

# Update Employer
@api_view(['PUT'])
def update_employer(request, pk):
    employer = get_object_or_404(Employer, pk=pk)
    serializer = EmployerSerializer(employer, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# Delete Employer
@api_view(['DELETE'])
def delete_employer(request, pk):
    """
    Delete an employer
    """
    employer = get_object_or_404(Employer, pk=pk)
    employer.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)

# Get or Update Profile
@api_view(['GET', 'PUT'])
def employer_profile(request, employer_id):
    
    employer = get_object_or_404(Employer, pk=employer_id)
    
    if request.method == 'GET':
        try:
            profile = employer.profile
            serializer = EmployerProfileSerializer(profile)
            return Response(serializer.data)
        except EmployerProfile.DoesNotExist:
            return Response(
                {'message': 'Profile not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
    
    elif request.method == 'PUT':
        try:
            profile = employer.profile
            serializer = EmployerProfileSerializer(profile, data=request.data, partial=True)
        except EmployerProfile.DoesNotExist:
            
            data = request.data.copy()
            serializer = EmployerProfileSerializer(data=data)
        
        if serializer.is_valid():
            serializer.save(employer=employer)
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
# Create Task
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_task(request):
    
    try:
    
        employer = Employer.objects.get(username=request.user.username)
        
        
        skills = request.data.get('skills')
        if skills is None or skills == '':
            skills = ''  
        
        task_data = {
            'employer': employer.employer_id,
            'title': request.data.get('title'),
            'description': request.data.get('description'),
            'category': request.data.get('category'),
            'budget': request.data.get('budget'),
            'deadline': request.data.get('deadline'),
            'required_skills': skills,  
            'is_urgent': request.data.get('isUrgent', False)
        }
        
        # Create task
        serializer = TaskSerializer(data=task_data)
        if serializer.is_valid():
            task = serializer.save()
            return Response({
                'success': True,
                'message': 'Task created successfully',
                'task': TaskSerializer(task).data
            }, status=status.HTTP_201_CREATED)
        else:
            return Response({
                'success': False,
                'message': 'Invalid data',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Employer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Employer profile not found'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error creating task: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
# Delete Task
@api_view(['DELETE'])
def delete_task(request, task_id):
    
    task = get_object_or_404(Task, pk=task_id)
    task.delete()
    return Response(
        {'message': 'Task deleted successfully'}, 
        status=status.HTTP_204_NO_CONTENT
    )

# Bulk Delete Tasks
@api_view(['DELETE'])
def bulk_delete_tasks(request):
    
    task_ids = request.data.get('task_ids', [])
    
    if not task_ids:
        return Response(
            {'error': 'task_ids array is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    tasks = Task.objects.filter(task_id__in=task_ids)
    deleted_count = tasks.count()
    tasks.delete()
    
    return Response(
        {'message': f'{deleted_count} tasks deleted successfully'}, 
        status=status.HTTP_200_OK
    )  
    
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_freelancer_proposals(request):
    try:
        
        employer = request.user  
        
        
        proposals = Proposal.objects.filter(task__employer=employer)
        
        serializer = ProposalSerializer(proposals, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    except Proposal.DoesNotExist:
        return Response(
            {'error': 'No proposals found for this employer.'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )
    
  


@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_dashboard_api(request):
    print("=== Employer Dashboard API Called ===")
    print("User:", request.user)
    print("Headers:", request.headers)

    try:
        
        employer = request.user  

        if employer is None:
            print("No employer found for this user.")
            return Response({
                'success': False,
                'error': 'User is not associated with any employer account.'
            }, status=status.HTTP_403_FORBIDDEN)

        #  STATISTICS 
        all_tasks = Task.objects.filter(employer=employer)
        total_tasks = all_tasks.count()
        pending_proposals = Proposal.objects.filter(task__employer=employer).count()
        ongoing_tasks = all_tasks.filter(status='in_progress').count()
        completed_tasks = all_tasks.filter(status='completed').count()
        total_spent = 0  

        #  RECENT TASKS 
        recent_tasks = all_tasks.order_by('-created_at')[:5]
        recent_proposals = Proposal.objects.filter(
            task__employer=employer
        ).select_related('freelancer', 'task').order_by('-submitted_at')[:5]

        #  SERIALIZE DATA 
        tasks_data = [
            {
                'task_id': t.task_id,
                'title': t.title,
                'status': t.status,
                'created_at': t.created_at,
                'budget': str(t.budget) if t.budget else None,
            }
            for t in recent_tasks
        ]

        proposals_data = [
            {
                'proposal_id': p.proposal_id,
                'freelancer_name': getattr(p.freelancer, 'username', 'Unknown'),
                'task_title': getattr(p.task, 'title', 'Unknown'),
                'bid_amount': str(p.bid_amount),
                'status': p.status,
                'submitted_at': p.submitted_at,
            }
            for p in recent_proposals
        ]

        #RESPONSE 
        response_data = {
            'success': True,
            'data': {
                'statistics': {
                    'total_tasks': total_tasks,
                    'pending_proposals': pending_proposals,
                    'ongoing_tasks': ongoing_tasks,
                    'completed_tasks': completed_tasks,
                    'total_spent': total_spent,
                },
                'recent_tasks': tasks_data,
                'recent_proposals': proposals_data,
                'employer_info': {
                    'employer_id': employer.employer_id,
                    'username': employer.username,
                    'email': employer.contact_email,
                }
            }
        }

        return Response(response_data, status=status.HTTP_200_OK)

    except Exception as e:
        print(f" Dashboard API error: {e}")
        return Response({
            'success': False,
            'error': 'Failed to load dashboard data',
            'data': {
                'statistics': {
                    'total_tasks': 0,
                    'pending_proposals': 0,
                    'ongoing_tasks': 0,
                    'completed_tasks': 0,
                    'total_spent': 0,
                },
                'recent_tasks': [],
                'recent_proposals': [],
                'employer_info': {},
            }
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_employer_tasks(request):
    
    print("\n===  Employer Tasks API Called ===")
    print(" Auth Header:", request.headers.get('Authorization'))
    print(" User:", request.user)
    print(" Is Authenticated:", request.user.is_authenticated)

    try:
        
        employer = request.user  
        print(f" Employer found: {employer.username} (ID: {employer.employer_id})")

    except Exception as e:
        print(f" Unexpected error fetching employer: {e}")
        return Response(
            {"success": False, "error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

   
    try:
        tasks = Task.objects.filter(employer=employer).order_by('-created_at')
        print(f" Found {tasks.count()} tasks for employer.")
        serializer = TaskSerializer(tasks, many=True)

        return Response({
            "success": True,
            "tasks": serializer.data,
            "count": len(serializer.data),
            "employer": {
                "id": employer.employer_id,
                "username": employer.username,
                "email": employer.contact_email
            }
        }, status=status.HTTP_200_OK)

    except Exception as e:
        print(f" Error loading tasks: {e}")
        return Response({
            "success": False,
            "error": "Error fetching tasks",
            "details": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
 
 
api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_employer_profile(request, employer_id):
   
    try:
        profile = EmployerProfile.objects.get(employer_id=employer_id)
        serializer = EmployerProfileSerializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except EmployerProfile.DoesNotExist:
        return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_employer_profile(request):
    
    serializer = EmployerProfileSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def update_employer_profile(request, employer_id):
    """Update employer profile."""
    try:
        profile = EmployerProfile.objects.get(employer_id=employer_id)
    except EmployerProfile.DoesNotExist:
        return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

    serializer = EmployerProfileSerializer(profile, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def tasks_to_rate(request, employer_id):
    """Get completed tasks for rating"""
    tasks = Task.objects.filter(employer_id=employer_id, status='completed', assigned_user__isnull=False)
    data = [
        {
            'task_id': task.id,
            'title': task.title,
            'description': task.description,
            'assigned_user': {
                'id': task.assigned_user.id,
                'username': task.assigned_user.username
            }
        }
        for task in tasks
    ]
    return Response(data)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def rate_freelancer(request):
    """Submit a rating for freelancer"""
    serializer = FreelancerRatingSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



# views.py
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_ratings(request):
    try:
        
        employer = get_object_or_404(Employer, username=request.user.username)
        
        ratings = EmployerRating.objects.filter(employer=employer).select_related('freelancer', 'task')

        if not ratings.exists():
            return Response({
                "employer": getattr(employer, 'company_name', employer.username),
                "average_score": None,
                "total_reviews": 0,
                "ratings": []
            }, status=status.HTTP_200_OK)

        serializer = EmployerRatingSerializer(ratings, many=True)
        avg_score = round(sum(r.score for r in ratings) / ratings.count(), 2)

        return Response({
            "employer": getattr(employer, 'company_name', employer.username),
            "average_score": avg_score,
            "total_reviews": ratings.count(),
            "ratings": serializer.data
        }, status=status.HTTP_200_OK)
        
    except Employer.DoesNotExist:
        return Response({
            "error": "Employer profile not found"
        }, status=status.HTTP_404_NOT_FOUND)



@api_view(['GET', 'POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def task_completion_list(request):
    if request.method == 'GET':
        completions = TaskCompletion.objects.all()
        serializer = TaskCompletionSerializer(completions, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        serializer = TaskCompletionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET', 'PUT', 'DELETE'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def task_completion_detail(request, pk):
    try:
        completion = TaskCompletion.objects.get(pk=pk)
    except TaskCompletion.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
    
    if request.method == 'GET':
        serializer = TaskCompletionSerializer(completion)
        return Response(serializer.data)
    
    elif request.method == 'PUT':
        serializer = TaskCompletionSerializer(completion, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    elif request.method == 'DELETE':
        completion.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)        


import uuid
import requests
from django.conf import settings
from django.http import JsonResponse, HttpResponseRedirect
from django.views.decorators.csrf import csrf_exempt

@csrf_exempt
def initialize_payment(request):
    if request.method == "POST":
        amount = request.POST.get("amount")

        # create unique transaction reference
        tx_ref = "HLW_" + str(uuid.uuid4())

        data = {
            "tx_ref": tx_ref,
            "amount": amount,
            "currency": "KES",
            "redirect_url": "http://127.0.0.1:8000/payment/callback/",
            "payment_options": "card,mpesa",
            "customer": {
                "email": request.user.email if request.user.is_authenticated else "client@example.com",
                "phonenumber": "254742461239",
                "name": request.user.username if request.user.is_authenticated else "Anonymous Client",
            },
            "customizations": {
                "title": "Helawork Payment",
                "description": "Client paying freelancer for a completed project",
            },
        }

        headers = {
            "Authorization": f"Bearer {settings.FLUTTERWAVE_SECRET_KEY}",
            "Content-Type": "application/json",
        }

        r = requests.post("https://api.flutterwave.com/v3/payments", json=data, headers=headers)
        res = r.json()

        # Redirect client to Flutterwave checkout page
        if res.get("status") == "success":
            link = res["data"]["link"]
            return HttpResponseRedirect(link)
        else:
            return JsonResponse({"error": res}, status=400)

    return JsonResponse({"error": "Invalid request method"}, status=405)


# views.py
import json
import logging
import requests
from decimal import Decimal

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from .models import User, Wallet

logger = logging.getLogger(__name__)

@csrf_exempt
def payment_callback(request):
    """
    Flutterwave webhook callback to verify and credit wallet.
    """
    if request.method != 'POST':
        return JsonResponse({'message': 'Invalid request method'}, status=405)

    try:
        payload = json.loads(request.body)
        tx_ref = payload.get('tx_ref')
        transaction_id = payload.get('id')  # Flutterwave transaction ID
    except (json.JSONDecodeError, KeyError) as e:
        logger.error(f"Invalid payload: {e}")
        return JsonResponse({'message': 'Invalid payload'}, status=400)

    # Verify payment with Flutterwave
    headers = {
        'Authorization': f'Bearer {settings.FLUTTERWAVE_SECRET_KEY}',
    }
    verify_url = f"https://api.flutterwave.com/v3/transactions/{transaction_id}/verify"
    
    try:
        response = requests.get(verify_url, headers=headers, timeout=10)
        res_data = response.json()
    except requests.RequestException as e:
        logger.error(f"Error verifying payment: {e}")
        return JsonResponse({'message': 'Payment verification failed'}, status=500)

    if res_data.get('status') == 'success' and res_data['data'].get('status') == 'successful':
        amount = Decimal(res_data['data'].get('amount', 0))
        meta = res_data['data'].get('meta', {})
        freelancer_id = meta.get('freelancer_id')

        if not freelancer_id:
            logger.error("No freelancer_id in meta")
            return JsonResponse({'message': 'Freelancer ID not provided'}, status=400)

        try:
            freelancer = User.objects.get(user_id=freelancer_id)
        except User.DoesNotExist:
            logger.error(f"Freelancer not found: {freelancer_id}")
            return JsonResponse({'message': 'Freelancer not found'}, status=404)

        # Get or create wallet
        wallet, _ = Wallet.objects.get_or_create(user=freelancer)

        # Deduct 10% system fee
        net_amount = amount * Decimal('0.9')
        wallet.balance += net_amount
        wallet.save()

        logger.info(f"Wallet credited: User {freelancer_id}, Amount {net_amount}")
        return JsonResponse({'message': 'Payment verified, wallet credited successfully.'}, status=200)
    else:
        logger.warning(f"Payment verification failed: {res_data}")
        return JsonResponse({'message': 'Payment verification failed.'}, status=400)


@api_view(['GET'])
def get_wallet_balance(request, user_id):
    try:
        wallet = Wallet.objects.get(user__user_id=user_id)
        serializer = WalletSerializer(wallet)
        return Response(serializer.data)
    except Wallet.DoesNotExist:
        return Response({'error': 'Wallet not found'}, status=status.HTTP_404_NOT_FOUND)


#  Withdraw Funds
@api_view(['POST'])
def withdraw_funds(request, user_id):
    amount = Decimal(request.data.get('amount', 0))
    try:
        wallet = Wallet.objects.get(user__user_id=user_id)
        if wallet.balance < amount:
            return Response({'error': 'Insufficient funds'}, status=status.HTTP_400_BAD_REQUEST)
        wallet.balance -= amount
        wallet.save()
        return Response({'message': f'{amount} withdrawn successfully', 'balance': wallet.balance})
    except Wallet.DoesNotExist:
        return Response({'error': 'Wallet not found'}, status=status.HTTP_404_NOT_FOUND)


#  Top Up via Flutterwave (initial logic)
@api_view(['POST'])
def top_up_wallet(request, user_id):
    """
    Initialize a Flutterwave payment for wallet top-up.
    Returns a payment link for the frontend.
    """
    amount = Decimal(request.data.get('amount', 0))
    if amount <= 0:
        return Response({'error': 'Invalid amount'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        wallet = Wallet.objects.get(user__user_id=user_id)
        user = wallet.user
    except Wallet.DoesNotExist:
        return Response({'error': 'Wallet not found'}, status=status.HTTP_404_NOT_FOUND)

    # Prepare Flutterwave payload
    payload = {
        "tx_ref": f"wallet-{user.user_id}-{wallet.id}",
        "amount": float(amount),
        "currency": "USD",  # Change if needed
        "payment_options": "card,ussd,banktransfer",
        "redirect_url": settings.FLUTTERWAVE_REDIRECT_URL,  # Frontend redirect after payment
        "customer": {
            "email": user.email,
            "name": f"{user.first_name} {user.last_name}"
        },
        "meta": {
            "user_id": user.user_id,
            "wallet_id": wallet.id
        },
        "customizations": {
            "title": "Wallet Top-up",
            "description": f"Top-up wallet for user {user.user_id}",
        }
    }

    headers = {
        "Authorization": f"Bearer {settings.FLUTTERWAVE_SECRET_KEY}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(
            "https://api.flutterwave.com/v3/payments",
            headers=headers,
            data=json.dumps(payload),
            timeout=10
        )
        res_data = response.json()
        if res_data.get("status") == "success":
            payment_link = res_data["data"]["link"]
            return Response({
                "message": "Payment initialized successfully",
                "payment_link": payment_link
            })
        else:
            return Response({
                "error": "Failed to initialize payment",
                "details": res_data
            }, status=status.HTTP_400_BAD_REQUEST)
    except requests.RequestException as e:
        return Response({'error': f"Payment initialization failed: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)