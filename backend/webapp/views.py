from decimal import Decimal
import secrets
from django.conf import settings
from django.http import JsonResponse
import json
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import authentication_classes, permission_classes, api_view
from rest_framework.response import Response
from rest_framework import status
from datetime import date, timedelta, timezone
import random
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
from django.contrib.auth.tokens import default_token_generator

from rest_framework.response import Response
from django.db import  transaction
from rest_framework import status
from django.core.mail import send_mail
from webapp.matcher import rank_jobs_for_freelancer
from webapp.paystack_service import PaystackService
from .models import Contract, Employer, EmployerProfile, EmployerToken, Freelancer, Notification, Order, PaymentTransaction, Proposal, Rating, Service, Submission, Task, TaskCompletion, Transaction, UserProfile, Wallet
from .models import  User
from rest_framework.permissions import IsAuthenticated
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import authentication_classes, permission_classes, api_view
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from webapp.serializers import ContractSerializer, EmployerProfileCreateSerializer, EmployerProfileSerializer, EmployerProfileUpdateSerializer,  EmployerRegisterSerializer, EmployerSerializer,  IDNumberUpdateSerializer, LoginSerializer, OrderSerializer, PaymentInitializeSerializer, ProposalSerializer, RatingSerializer, RegisterSerializer, SubmissionCreateSerializer, SubmissionSerializer, TaskCompletionSerializer, TaskCreateSerializer, TaskSerializer, TransactionSerializer, UserProfileSerializer, WalletSerializer
from .authentication import CustomTokenAuthentication, EmployerTokenAuthentication
from .permissions import IsAuthenticated  
from .models import UserProfile
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from .authentication import EmployerTokenAuthentication, IsAuthenticated
from .models import Task, Proposal
from rest_framework.parsers import MultiPartParser, FormParser

from webapp import models

@csrf_exempt
@api_view(['GET', 'POST', 'PUT'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def apiuserprofile(request):
    print(f"\n{'='*60}")
    print("PROFILE API CALLED")
    print(f"{'='*60}")
    print(f"Authenticated User: {request.user.name} (ID: {request.user.user_id})")
    print(f"Method: {request.method}")
    print(f"Content-Type: {request.content_type}")
    
    # GET - Retrieve user profile
    if request.method == 'GET':
        print("GET - Fetching user profile...")
        try:
            profile = UserProfile.objects.get(user=request.user)
            print(f"Profile found: ID={profile.profile_id}")
            
            # Handle profile picture URL
            profile_data = UserProfileSerializer(profile).data
            
            # If profile has a profile picture, construct full URL
            if profile.profile_picture:
                profile_data['profile_picture'] = request.build_absolute_uri(profile.profile_picture.url)
                print(f"Profile picture URL: {profile_data['profile_picture']}")
            
            return Response({
                "success": True,
                "message": "Profile retrieved successfully",
                "profile": profile_data
            }, status=status.HTTP_200_OK)
            
        except UserProfile.DoesNotExist:
            print("No profile found for user")
            return Response({
                "success": False,
                "message": "Profile not found. Create a profile first.",
                "profile": None
            }, status=status.HTTP_404_NOT_FOUND)
            
        except Exception as e:
            print(f"Error fetching profile: {e}")
            return Response({
                "success": False,
                "message": f"Error fetching profile: {str(e)}"
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # POST - Create new profile
    elif request.method == 'POST':
        print("POST - Creating new profile...")
        print(f"Request data: {request.data}")
        print(f"Request FILES: {request.FILES}")
        
        serializer = UserProfileSerializer(data=request.data)
        if serializer.is_valid():
            profile = serializer.save(user=request.user)
            
            # Handle profile picture URL in response
            profile_data = UserProfileSerializer(profile).data
            if profile.profile_picture:
                profile_data['profile_picture'] = request.build_absolute_uri(profile.profile_picture.url)
            
            return Response({
                "success": True,
                "message": "Profile created successfully",
                "profile": profile_data
            }, status=status.HTTP_201_CREATED)
        print("POST errors:", serializer.errors)
        return Response({
            "success": False,
            "errors": serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

    # PUT - Update existing profile or create if doesn't exist
    elif request.method == 'PUT':
        print("PUT - Updating profile...")
        print(f"Request data: {request.data}")
        print(f"Request FILES: {request.FILES}")
        
        try:
            # Try to get existing profile
            profile = UserProfile.objects.get(user=request.user)
            print(f"Found existing profile: ID={profile.profile_id}")
            
            # UPDATE existing profile
            serializer = UserProfileSerializer(profile, data=request.data, partial=True)
            if serializer.is_valid():
                updated_profile = serializer.save()
                print("Profile updated successfully")
                
                # Handle profile picture URL in response
                profile_data = UserProfileSerializer(updated_profile).data
                if updated_profile.profile_picture:
                    profile_data['profile_picture'] = request.build_absolute_uri(updated_profile.profile_picture.url)
                
                return Response({
                    "success": True,
                    "message": "Profile updated successfully",
                    "profile": profile_data
                }, status=status.HTTP_200_OK)
            print("PUT validation errors:", serializer.errors)
            return Response({
                "success": False,
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except UserProfile.DoesNotExist:
            print("No profile found - CREATING new profile with PUT")
            
            serializer = UserProfileSerializer(data=request.data)
            if serializer.is_valid():
                new_profile = serializer.save(user=request.user)
                print("New profile created successfully via PUT")
                
                # Handle profile picture URL in response
                profile_data = UserProfileSerializer(new_profile).data
                if new_profile.profile_picture:
                    profile_data['profile_picture'] = request.build_absolute_uri(new_profile.profile_picture.url)
                
                return Response({
                    "success": True,
                    "message": "Profile created successfully",
                    "profile": profile_data
                }, status=status.HTTP_201_CREATED)
            print("CREATE validation errors:", serializer.errors)
            return Response({
                "success": False,
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
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

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def apisubmit_proposal(request):
    try:
        print("=== PROPOSAL SUBMISSION (SERIALIZER VERSION) ===")
        print(f"User: {request.user.name} (ID: {request.user.user_id})")
        print(f"Content-Type: {request.content_type}")
        
        # Handle multipart/form-data (Flutter sends this)
        if 'multipart/form-data' in (request.content_type or ''):
            # For file uploads, use request.data which DRF handles
            data = request.data.copy()
            print(f"Received data keys: {list(data.keys())}")
            
            # Map Flutter's 'task_id' to serializer's 'task' field
            if 'task_id' in data and 'task' not in data:
                data['task'] = data.pop('task_id')
                print(f"Mapped task_id={data['task']} to task field")
            
            # Add required fields with defaults if missing
            if 'cover_letter' not in data:
                data['cover_letter'] = f"Proposal from {request.user.name}"
            
            if 'estimated_days' not in data:
                data['estimated_days'] = 7
            
            if 'status' not in data:
                data['status'] = 'pending'
            
        else:
            # Handle JSON if needed
            data = request.data
        
        print(f"Data for serializer: {data}")
        
        # Create serializer with request context
        serializer = ProposalSerializer(
            data=data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            print("✅ Serializer validation passed")
            proposal = serializer.save()
            
            print(f"✅ Proposal created: ID {proposal.proposal_id}")
            print(f"   Task: {proposal.task.title}")
            print(f"   Bid: ${proposal.bid_amount}")
            print(f"   Status: {proposal.status}")
            
            # Return success response
            return Response({
                "success": True,
                "message": "Proposal submitted successfully",
                "proposal": ProposalSerializer(proposal).data
            }, status=status.HTTP_201_CREATED)
        
        else:
            print("❌ Serializer validation failed")
            print(f"Errors: {serializer.errors}")
            return Response({
                "success": False,
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
from django.db.models import Prefetch
        
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def apitask_list(request):
    try:
        # Get open and active tasks
        tasks = Task.objects.filter(
            status='open', 
            is_active=True
        ).select_related('employer').prefetch_related(
            Prefetch(
                'contract',  # ForeignKey from Task to Contract
                queryset=Contract.objects.filter(is_active=True).select_related('freelancer'),
                to_attr='active_contract'
            ),
            'employer__profile'
        )
        
        data = []
        for task in tasks:
            employer_profile = getattr(task.employer, 'profile', None)
            
            # Check active contract (prefetched as single object, not list)
            has_active_contract = task.active_contract is not None
            active_contract = task.active_contract
            
            # Get freelancer info - FIXED: Use user_id (not id)
            assigned_freelancer = None
            if has_active_contract and active_contract.freelancer:
                user = active_contract.freelancer
                assigned_freelancer = {
                    'id': user.user_id,  # CORRECT: User model uses user_id as primary key
                    'name': user.name,  # User model has 'name' field, not 'get_full_name()'
                    'username': user.name,  # Use name as username
                    'email': user.email,
                }
            
            task_data = {
                'task_id': task.task_id,
                'id': task.task_id,
                'title': task.title,
                'description': task.description,
                'is_approved': task.is_approved,
                'status': task.status,
                'overall_status': 'taken' if has_active_contract else task.status,
                'has_contract': has_active_contract,
                'is_taken': has_active_contract,
                'assigned_user': task.assigned_user.user_id if task.assigned_user else None,  # Use user_id
                'assigned_freelancer': assigned_freelancer,
                'contract_count': 1 if has_active_contract else 0,
                'created_at': task.created_at.isoformat() if task.created_at else None,
                'completed': False,
                'employer': {
                    'id': task.employer.employer_id,
                    'username': task.employer.username,
                    'contact_email': task.employer.contact_email,
                    'profile_picture': employer_profile.profile_picture.url if employer_profile and employer_profile.profile_picture else None,
                    'phone_number': employer_profile.phone_number if employer_profile else None,
                }
            }
            data.append(task_data)
        
        print(f" Returning {len(data)} tasks with contract status")
        return Response({
            "status": True,
            "tasks": data,
            "count": len(data)
        })
        
    except Exception as e:
        print(f" Error in apitask_list: {e}")
        import traceback
        traceback.print_exc()
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
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django_ratelimit.decorators import ratelimit
from .models import Employer, EmployerProfile, EmployerToken
from .serializers import EmployerProfileSerializer, EmployerProfileCreateSerializer, EmployerProfileUpdateSerializer, EmployerRatingSerializer, IDNumberUpdateSerializer

# ============ HELPER FUNCTIONS ============
def get_employer_from_token(request):
    """
    Get Employer object from the Bearer token in the request.
    This is needed because Employer model doesn't have a 'user' field.
    """
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    if auth_header.startswith('Bearer '):
        token_key = auth_header[7:]  # Remove 'Bearer '
        try:
            employer_token = EmployerToken.objects.get(key=token_key)
            return employer_token.employer
        except EmployerToken.DoesNotExist:
            return None
    return None

def send_verification_email(profile):
    """Send verification email"""
    import secrets
    from django.core.mail import send_mail
    from django.conf import settings
    
    token = secrets.token_urlsafe(32)
    profile.email_verification_token = token
    profile.save()
    
    subject = 'Verify your email - HELAWORK'
    message = f'''
    Hello {profile.full_name},
    
    Please verify your email address by clicking the link below:
    
    {settings.FRONTEND_URL}/verify-email/{token}
    
    Or enter this token in the app: {token}
    
    This link will expire in 24 hours.
    
    Best regards,
    HELAWORK Team
    '''
    
    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [profile.contact_email],
        fail_silently=False,
    )

def send_phone_verification_code(profile):
    """Send phone verification code"""
    import random
    code = str(random.randint(100000, 999999))
    profile.phone_verification_code = code
    profile.phone_verification_sent_at = timezone.now()
    profile.save()
    print(f"Phone verification code for {profile.phone_number}: {code}")

def _update_verification_status(profile):
    """Update verification status"""
    if profile.is_fully_verified():
        profile.verification_status = 'verified'
    elif profile.email_verified or profile.phone_verified or profile.id_verified:
        profile.verification_status = 'pending'
    else:
        profile.verification_status = 'unverified'
    profile.save()

# ============ API VIEWS ============
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_employer_profile(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'error': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        profile = EmployerProfile.objects.get(employer=employer)
        serializer = EmployerProfileSerializer(profile)
        return Response(serializer.data)
    except EmployerProfile.DoesNotExist:
        return Response({'error': 'Profile not found. Create one first.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_employer_profile(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'error': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        if hasattr(employer, 'profile'):
            return Response({'error': 'Profile already exists. Use update instead.'}, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = EmployerProfileCreateSerializer(data=request.data, context={'employer': employer})
        if serializer.is_valid():
            profile = serializer.save()
            send_verification_email(profile)
            if profile.phone_number:
                send_phone_verification_code(profile)
            
            full_serializer = EmployerProfileSerializer(profile)
            return Response(full_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response({'error': 'Validation failed', 'details': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT', 'PATCH'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def update_employer_profile(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'error': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        profile = EmployerProfile.objects.get(employer=employer)
        serializer = EmployerProfileUpdateSerializer(profile, data=request.data, partial=(request.method == 'PATCH'))
        
        if serializer.is_valid():
            serializer.save()
            full_serializer = EmployerProfileSerializer(profile)
            return Response(full_serializer.data)
        
        return Response({'error': 'Validation failed', 'details': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
    except EmployerProfile.DoesNotExist:
        return Response({'error': 'Profile not found. Create one first.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
@ratelimit(key='user', rate='5/h', block=True)
def update_id_number(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'error': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        profile = EmployerProfile.objects.get(employer=employer)
        if profile.id_verified:
            return Response({'error': 'ID number is already verified and cannot be changed.'}, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = IDNumberUpdateSerializer(profile, data=request.data)
        if serializer.is_valid():
            serializer.save()
            profile.verification_status = 'pending'
            profile.save()
            
            return Response({
                'message': 'ID number updated successfully',
                'id_number': serializer.data['id_number'],
                'id_verified': profile.id_verified,
                'verification_status': profile.verification_status
            })
        
        return Response({'error': 'Validation failed', 'details': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
    except EmployerProfile.DoesNotExist:
        return Response({'error': 'Profile not found. Create one first.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_email(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'error': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        profile = EmployerProfile.objects.get(employer=employer)
        token = request.data.get('token')
        
        if not token:
            return Response({'error': 'Verification token required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if profile.email_verification_token == token:
            profile.email_verified = True
            profile.email_verified_at = timezone.now()
            profile.email_verification_token = None
            profile.save()
            _update_verification_status(profile)
            
            return Response({
                'message': 'Email verified successfully',
                'profile': EmployerProfileSerializer(profile).data
            })
        
        return Response({'error': 'Invalid verification token'}, status=status.HTTP_400_BAD_REQUEST)
    except EmployerProfile.DoesNotExist:
        return Response({'error': 'Profile not found. Create one first.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_phone(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'error': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        profile = EmployerProfile.objects.get(employer=employer)
        code = request.data.get('code')
        
        if not code:
            return Response({'error': 'Verification code required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if profile.phone_verification_code == code:
            if profile.phone_verification_sent_at:
                time_diff = timezone.now() - profile.phone_verification_sent_at
                if time_diff.total_seconds() > 300:
                    return Response({'error': 'Verification code expired'}, status=status.HTTP_400_BAD_REQUEST)
            
            profile.phone_verified = True
            profile.phone_verified_at = timezone.now()
            profile.phone_verification_code = None
            profile.save()
            _update_verification_status(profile)
            
            return Response({
                'message': 'Phone verified successfully',
                'profile': EmployerProfileSerializer(profile).data
            })
        
        return Response({'error': 'Invalid verification code'}, status=status.HTTP_400_BAD_REQUEST)
    except EmployerProfile.DoesNotExist:
        return Response({'error': 'Profile not found. Create one first.'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def check_profile_exists(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'exists': False, 'message': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        if hasattr(employer, 'profile'):
            return Response({
                'exists': True, 
                'profile_id': employer.profile.id,
                'employer_id': employer.id,
                'profile': EmployerProfileSerializer(employer.profile).data
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'exists': False, 
                'profile_id': None,
                'employer_id': employer.id
            }, status=status.HTTP_200_OK)
            
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_verification_status(request):
    try:
        employer = get_employer_from_token(request)
        if not employer:
            return Response({'exists': False, 'message': 'Invalid authentication token'}, status=status.HTTP_401_UNAUTHORIZED)
        
        profile = EmployerProfile.objects.get(employer=employer)
        data = {
            'email_verified': profile.email_verified,
            'phone_verified': profile.phone_verified,
            'id_verified': profile.id_verified,
            'verification_status': profile.verification_status,
            'is_fully_verified': profile.is_fully_verified(),
            'verification_progress': profile.get_verification_progress(),
        }
        
        return Response(data)
    except EmployerProfile.DoesNotExist:
        return Response({'exists': False, 'message': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
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

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_submission(request):
    print(f"\n{'='*60}")
    print("CREATE SUBMISSION - START")
    print(f"{'='*60}")
    
    try:
        # Step 1: Basic validation
        print(f"1. User: {request.user.user_id} ({request.user.name})")
        
        # Step 2: Check if user has UserProfile
        print(f"\n2. Checking UserProfile...")
        if not hasattr(request.user, 'worker_profile'):
            print("✗ User does not have a UserProfile")
            return Response(
                {"success": False, "error": "Please complete your user profile first"}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        user_profile = request.user.worker_profile
        print(f"✓ User has profile: ID={user_profile.profile_id}")
        
        # Step 3: Check request data
        print(f"\n3. Request data analysis:")
        task_id = request.data.get('task_id')
        print(f"   Task ID: {task_id}")
        
        if not task_id:
            print("✗ task_id is missing")
            return Response(
                {"success": False, "error": "task_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Step 4: Get task
        print(f"\n4. Getting task...")
        try:
            task = Task.objects.get(task_id=task_id)
            print(f"   ✓ Task found: ID={task.task_id}, Title='{task.title}', Status='{task.status}'")
        except Task.DoesNotExist:
            print(f"   ✗ Task not found")
            return Response(
                {"success": False, "error": f"Task with ID {task_id} not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            print(f"   ✗ Error getting task: {type(e).__name__}: {e}")
            raise
        
        # Step 5: Check for ACTIVE contract
        print(f"\n5. Checking for ACTIVE contract...")
        try:
            contract = Contract.objects.get(
                task=task,
                freelancer=request.user,
                is_active=True,
                employer_accepted=True,
                freelancer_accepted=True
            )
            print(f"   ✓ Active contract found: ID={contract.contract_id}")
            print(f"   Contract details: is_active={contract.is_active}")
            
        except Contract.DoesNotExist:
            print(f"   ✗ No active contract found")
            
            # Check what contracts exist (for debugging)
            contracts = Contract.objects.filter(task=task, freelancer=request.user)
            if contracts.exists():
                print(f"   Found {contracts.count()} inactive contracts:")
                for c in contracts:
                    print(f"     Contract {c.contract_id}: "
                          f"is_active={c.is_active}, "
                          f"employer_accepted={c.employer_accepted}, "
                          f"freelancer_accepted={c.freelancer_accepted}")
            else:
                print(f"   No contracts found at all")
            
            return Response({
                "success": False,
                "error": "No active contract found. You must have an accepted proposal to submit work.",
                "action_required": "Wait for your proposal to be accepted or submit a proposal first"
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            print(f"   ✗ Error getting contract: {type(e).__name__}: {e}")
            raise
        
        # Step 6: Check for existing submissions
        print(f"\n6. Checking for existing submissions...")
        existing_submission = Submission.objects.filter(
            task=task,
            freelancer=request.user,
            contract=contract
        ).first()
        
        is_resubmission = False
        if existing_submission:
            print(f"   ✓ Existing submission found: ID={existing_submission.submission_id}")
            print(f"   Status: {existing_submission.status}")
            
            # Only allow resubmission if revisions are requested
            if existing_submission.status != 'revisions_requested':
                return Response({
                    "success": False,
                    "error": "Submission already exists for this task",
                    "submission_id": existing_submission.submission_id,
                    "status": existing_submission.status,
                    "action": "Use resubmission endpoint if revisions are requested"
                }, status=status.HTTP_400_BAD_REQUEST)
            else:
                print(f"   Allowing resubmission for revisions")
                is_resubmission = True
        
        # Step 7: Create serializer inside atomic transaction
        print(f"\n7. Creating serializer inside atomic transaction...")
        
        from .serializers import SubmissionCreateSerializer
        
        # ✅ CRITICAL: Use transaction.atomic to ensure both submission and task update succeed together
        with transaction.atomic():
            serializer = SubmissionCreateSerializer(
                data=request.data,
                context={
                    'task': task,
                    'freelancer': request.user,
                    'contract': contract,
                    'is_resubmission': is_resubmission
                }
            )
            
            if serializer.is_valid():
                # This will create submission AND update task status
                submission = serializer.save()
                
                print(f"   ✓ Submission saved: ID={submission.submission_id}")
                print(f"   ✓ Task {task.task_id} status updated to: {task.status}")
                
                # Double-check task status was updated
                task.refresh_from_db()
                print(f"   ✓ Confirmed Task status: {task.status}")
                
                return Response({
                    "success": True,
                    "message": "Submission created successfully. Task is now pending review.",
                    "submission_id": submission.submission_id,
                    "status": submission.status,
                    "task_status": task.status,  # Include task status in response
                    "submitted_at": submission.submitted_at,
                    "task_id": task.task_id,
                    "task_title": task.title,
                    "contract_id": contract.contract_id,
                    "is_resubmission": is_resubmission
                }, status=status.HTTP_201_CREATED)
            else:
                print(f"   ✗ Serializer validation failed")
                print(f"   Errors: {serializer.errors}")
                return Response({
                    "success": False,
                    "error": "Validation failed",
                    "errors": serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
        
    except Exception as e:
        print(f"\n{'='*60}")
        print("FATAL ERROR")
        print(f"{'='*60}")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        import traceback
        error_traceback = traceback.format_exc()
        print(f"Full traceback:\n{error_traceback}")
        
        return Response({
            "success": False,
            "error": "Internal server error",
            "detail": str(e),
            "type": type(e).__name__
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_submissions_for_rating(request):
    try:
        # Fetch submissions for tasks owned by the requesting user (employer)
        # We filter by the task's owner and a status that needs attention
        submissions = Submission.objects.filter(
            task__employer=request.user, 
            status__in=['submitted', 'resubmitted']
        ).select_related('task', 'freelancer')

        data = []
        for sub in submissions:
            data.append({
                "submission_id": sub.submission_id,
                "task_title": sub.task.title,
                "freelancer_name": sub.freelancer.name,
                "submitted_at": sub.submitted_at,
                "content": sub.content, # Or the file URL
                "status": sub.status
            })

        return Response(data, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)        
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_assigned_tasks(request):
    
    # Get contracts where this user is the freelancer
    contracts = Contract.objects.filter(
        freelancer=request.user,  # The current logged-in user
        is_active=True  # Only active contracts
    )
    
    tasks_data = []
    for contract in contracts:
        task = contract.task
        tasks_data.append({
            'task_id': task.id,  # The actual task ID from your database
            'title': task.title,
            'status': task.status,
        })
    
    return Response({
        'tasks': tasks_data
    })        
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_employer_submissions(request):
    
    if not hasattr(request.user, 'employer'):
        return Response(
            {"error": "Only employers can view their task submissions"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    employer = request.user.employer
    submissions = Submission.objects.filter(contract__employer=employer).order_by('-submitted_at')
    serializer = SubmissionSerializer(submissions, many=True)
    return Response(serializer.data)

@api_view(['POST'])

def approve_submission(request, submission_id):
    if not hasattr(request.user, 'employer'):
        return Response(
            {"error": "Only employers can approve submissions"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    submission = get_object_or_404(Submission, submission_id=submission_id)
    
    # Verify employer owns this submission
    if submission.contract.employer.user != request.user:
        return Response(
            {"error": "You can only approve submissions for your own tasks"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    try:
        with transaction.atomic():
            submission.approve()
            submission.status = 'approved'
            submission.save()
            
            # Update TaskCompletion
            completion = get_object_or_404(TaskCompletion, submission=submission)
            completion.approve_completion()
        
        return Response({
            "message": "Submission approved successfully",
            "submission_id": submission.submission_id,
            "status": submission.status
        })
    
    except Exception as e:
        return Response(
            {"error": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_revision(request, submission_id):
    if not hasattr(request.user, 'employer'):
        return Response(
            {"error": "Only employers can request revisions"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    submission = get_object_or_404(Submission, submission_id=submission_id)
    
    # Verify employer owns this submission
    if submission.contract.employer.user != request.user:
        return Response(
            {"error": "You can only request revisions for your own tasks"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    revision_notes = request.data.get('revision_notes', '')
    if not revision_notes:
        return Response(
            {"error": "Revision notes are required"}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        submission.request_revision(revision_notes)
        return Response({
            "message": "Revision requested successfully",
            "submission_id": submission.submission_id,
            "status": submission.status
        })
    
    except Exception as e:
        return Response(
            {"error": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_employer_rating(request):
    """
    Create rating from employer to freelancer using rater_employer field
    """
    try:
        print(f"\n=== CREATE EMPLOYER RATING ===")
        print(f"Employer: {request.user.username}")
        print(f"Request data: {request.data}")
        
        # Get employer
        employer = request.user
        
        # Get required data
        data = request.data
        task_id = data.get('task')
        freelancer_id = data.get('rated_user')
        score = data.get('score')
        review = data.get('review', '')
        
        # Validate required fields
        if not task_id:
            return Response(
                {"success": False, "error": "task is required"}, 
                status=400
            )
        
        if not freelancer_id:
            return Response(
                {"success": False, "error": "rated_user is required"}, 
                status=400
            )
        
        if not score:
            return Response(
                {"success": False, "error": "score is required (1-5)"}, 
                status=400
            )
        
        # Convert score to integer
        try:
            score = int(score)
            if score < 1 or score > 5:
                return Response({
                    "success": False,
                    "error": "Score must be between 1 and 5"
                }, status=400)
        except ValueError:
            return Response({
                "success": False,
                "error": "Score must be a valid number"
            }, status=400)
        
        # Get task and verify ownership
        try:
            task = Task.objects.get(task_id=task_id, employer=employer)
            print(f"Task found: {task.title}, status: {task.status}")
        except Task.DoesNotExist:
            return Response(
                {"success": False, "error": "Task not found or you don't own this task"}, 
                status=404
            )
        
        # Check task status
        if task.status != 'submitted':
            return Response({
                "success": False,
                "error": f"Task must be in 'submitted' status. Current status: {task.status}",
                "current_status": task.status
            }, status=400)
        
        # Get freelancer
        try:
            freelancer = User.objects.get(user_id=freelancer_id)
            print(f"Freelancer found: {freelancer.name}")
        except User.DoesNotExist:
            return Response(
                {"success": False, "error": "Freelancer not found"}, 
                status=404
            )
        
        # Get contract for this task and freelancer
        try:
            contract = Contract.objects.get(
                task=task,
                freelancer=freelancer,
                is_active=True
            )
            print(f"Contract found: {contract.contract_id}")
        except Contract.DoesNotExist:
            return Response({
                "success": False,
                "error": "No active contract found for this task and freelancer"
            }, status=400)
        
        # Get submission if exists
        submission = Submission.objects.filter(
            task=task,
            freelancer=freelancer
        ).first()
        
        # Check if rating already exists (using rater_employer)
        if Rating.objects.filter(
            task=task, 
            rater_employer=employer, 
            rated_user=freelancer
        ).exists():
            return Response({
                "success": False,
                "error": "You have already rated this freelancer for this task"
            }, status=400)
        
        # Create the rating - model will handle User creation
        rating = Rating.objects.create(
            task=task,
            contract=contract,
            submission=submission,
            rater_employer=employer,  # Just pass the employer
            rated_user=freelancer,
            score=score,
            review=review,
            # Don't set rater or rating_type - they will be auto-set in save() method
        )
        
        print(f"Rating created: {rating.rating_id}")
        print(f"Auto-assigned rater: {rating.rater.name if rating.rater else 'None'}")
        print(f"Rating type: {rating.rating_type}")
        
        # Update task status to 'completed'
        task.status = 'completed'
        task.save()
        print(f"Task status updated to: {task.status}")
        
        # Update submission status to 'accepted' if exists
        if submission:
            submission.status = 'accepted'
            submission.save()
            print(f"Submission status updated to: {submission.status}")
        
        # Update contract status
        contract.status = 'completed'
        contract.is_completed = True
        contract.completed_date = timezone.now()
        contract.save()
        print(f"Contract marked as completed")
        
        return Response({
            "success": True,
            "message": "Rating submitted successfully",
            "rating_id": rating.rating_id,
            "data": {
                "task_status": task.status,
                "submission_status": submission.status if submission else None,
                "contract_status": contract.status,
                "score": rating.score,
                "review": rating.review,
                "rating_type": rating.rating_type,
                "freelancer_rated": freelancer.name
            }
        }, status=201)
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return Response({
            "success": False,
            "error": str(e)
        }, status=500)
                
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_user_ratings(request):
    try:
        # Get user_id from query parameter
        user_id = request.GET.get('user_id')
        
        if not user_id:
            # If no user_id provided, return current user's ratings
            ratings = Rating.objects.filter(rated_user=request.user).order_by('-created_at')
        else:
            # Get ratings for specific user
            ratings = Rating.objects.filter(rated_user_id=user_id).order_by('-created_at')
        
        serializer = RatingSerializer(ratings, many=True)
        return Response(serializer.data)
    
    except Exception as e:
        return Response(
            {"error": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
from django.db.models import Q, Exists, OuterRef
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_rateable_contracts(request):
    """
    Fetches contracts where the freelancer has submitted work 
    that the employer now needs to review and rate.
    """
    try:
        user = request.user
        print(f"DEBUG: Fetching rateable work for Employer: {user.name} (ID: {user.user_id})")

        # 1. Get contracts where current user is the employer 
        # AND there is a submission with status 'submitted' or 'resubmitted'
        # We use distinct() to avoid duplicate contracts if there are multiple submissions
        contracts = Contract.objects.filter(
            task__employer=user,
            is_active=True,
            submissions__status__in=['submitted', 'resubmitted']
        ).select_related('task', 'freelancer').distinct()

        print(f"DEBUG: Found {contracts.count()} contracts with pending submissions")

        rateable_list = []
        for contract in contracts:
            try:
                # Get the latest submission for this contract
                latest_submission = contract.submissions.filter(
                    status__in=['submitted', 'resubmitted']
                ).latest('submitted_at')

                # Handle User/Profile naming logic safely
                freelancer_user = contract.freelancer
                freelancer_name = getattr(freelancer_user, 'name', 
                                  getattr(freelancer_user, 'username', 'Freelancer'))

                rateable_list.append({
                    'contract_id': contract.contract_id,
                    'submission_id': latest_submission.submission_id,
                    'task': {
                        'id': contract.task.task_id,
                        'title': contract.task.title,
                        'budget': str(contract.task.budget),
                    },
                    'freelancer': {
                        'id': freelancer_user.user_id,
                        'name': freelancer_name,
                    },
                    'submitted_work': {
                        'content': latest_submission.content,
                        'submitted_at': latest_submission.submitted_at.isoformat(),
                    },
                    'status': latest_submission.status,
                })

            except Exception as e:
                print(f"DEBUG: Skipping contract {contract.contract_id} due to error: {e}")
                continue

        return Response({
            'success': True,
            'count': len(rateable_list),
            'tasks': rateable_list  # Named 'tasks' to match your Flutter expectations
        }, status=status.HTTP_200_OK)

    except Exception as e:
        print(f"FATAL ERROR in get_rateable_contracts: {str(e)}")
        return Response({
            'success': False,
            'error': "Internal server error occurred while fetching submissions."
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])

def get_task_ratings(request, task_id):
    task = get_object_or_404(Task, id=task_id)
    
    # Check permissions
    user = request.user
    if not (user == task.employer.user or user == task.contract.freelancer or user.is_staff):
        return Response(
            {"error": "You don't have permission to view ratings for this task"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    ratings = Rating.objects.filter(task=task).order_by('-created_at')
    serializer = RatingSerializer(ratings, many=True)
    return Response(serializer.data)

# Dashboard Stats
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def submission_stats(request):
    user = request.user
    
    try:
        if hasattr(user, 'employer'):
            # Employer stats
            employer = user.employer
            total_submissions = Submission.objects.filter(contract__employer=employer).count()
            pending_review = Submission.objects.filter(
                contract__employer=employer, 
                status__in=['submitted', 'under_review']
            ).count()
            approved = Submission.objects.filter(contract__employer=employer, status='approved').count()
            
            return Response({
                'total_submissions': total_submissions,
                'pending_review': pending_review,
                'approved': approved
            })
        
        elif hasattr(user, 'freelancer'):
            # Freelancer stats
            total_submissions = Submission.objects.filter(freelancer=user).count()
            approved = Submission.objects.filter(freelancer=user, status='approved').count()
            pending = Submission.objects.filter(
                freelancer=user, 
                status__in=['submitted', 'under_review']
            ).count()
            
            return Response({
                'total_submissions': total_submissions,
                'approved': approved,
                'pending_review': pending
            })
        
        return Response({'error': 'User role not recognized'}, status=400)
    
    except Exception as e:
        return Response(
            {"error": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_rateable_tasks(request):
    """
    Get tasks that are ready for employer to rate/review.
    """
    if request.method == 'GET':
        try:
            print(f"\n=== GET RATEABLE TASKS (UPDATED) ===")
            
            employer = request.user
            
            # Get SUBMITTED tasks
            submitted_tasks = Task.objects.filter(
                employer=employer,
                assigned_user__isnull=False,
                status='submitted'
            ).select_related('assigned_user')
            
            print(f"Found {submitted_tasks.count()} submitted tasks")
            
            tasks_data = []
            for task in submitted_tasks:
                print(f"\nProcessing task: {task.task_id} - {task.title}")
                print(f"Assigned user: {task.assigned_user.name} (ID: {task.assigned_user.user_id})")
                
                # Check if already rated (using rater_employer)
                already_rated = Rating.objects.filter(
                    task=task,
                    rater_employer=employer,
                    rated_user=task.assigned_user
                ).exists()
                
                print(f"Already rated: {already_rated}")
                
                if not already_rated:
                    # Get latest submission
                    submission = Submission.objects.filter(
                        task=task,
                        freelancer=task.assigned_user,
                        status__in=['submitted', 'resubmitted']
                    ).order_by('-submitted_at').first()
                    
                    if submission:
                        tasks_data.append({
                            'id': task.task_id,
                            'title': task.title,
                            'description': task.description,
                            'budget': str(task.budget) if task.budget else "0.00",
                            'freelancer': {
                                'id': task.assigned_user.user_id,
                                'username': task.assigned_user.name,
                                'email': task.assigned_user.email,
                            },
                            'submission_id': submission.submission_id,
                            'submission_title': submission.title,
                            'submission_status': submission.status,
                            'submitted_at': submission.submitted_at.isoformat() if submission.submitted_at else None,
                            'task_status': task.status,
                            'can_rate': True
                        })
                        print(f"  ✓ Added to rateable list")
                    else:
                        print(f"  ⚠ No submission found")
                else:
                    print(f"  ✗ Already rated, skipping")
            
            print(f"\nReturning {len(tasks_data)} rateable tasks")
            return JsonResponse(tasks_data, safe=False)
            
        except Exception as e:
            print(f"Error in employer_rateable_tasks: {e}")
            import traceback
            traceback.print_exc()
            return JsonResponse([], safe=False)
    
    return JsonResponse([], safe=False) 
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_ratings(request, employer_id):
    try:
        # Get the employer
        employer = Employer.objects.filter(employer_id=employer_id).first()
        if not employer:
            return Response([], status=status.HTTP_200_OK)
        
     
        ratings = Rating.objects.filter(
            rating_type='freelancer_to_employer'
        ).filter(
            rated_user__email=employer.contact_email
        ).select_related('rater', 'task')
        
        ratings_data = []
        for rating in ratings:
            ratings_data.append({
                'id': rating.rating_id,
                'score': rating.score,
                'review': rating.review,
                'created_at': rating.created_at.isoformat(),
                'freelancer': {
                    'name': rating.rater.name,
                    'id': rating.rater.user_id,
                },
                'task': {
                    'title': rating.task.title,
                    'id': rating.task.task_id,
                }
            })
        
        return Response(ratings_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def payment_order_details(request, order_id):
   
    try:
        order = get_object_or_404(Order, order_id=order_id)
        
        # Get parameters from query string
        email = request.GET.get('email', '')
        amount = request.GET.get('amount', order.amount)
        
        data = {
            'order_id': order.order_id,
            'amount': float(amount),
            'email': email,
            'freelancer_name': order.service.freelancer.user.get_full_name() or order.service.freelancer.user.username,
            'service_description': order.service.title,
            'paystack_public_key': settings.PAYSTACK_PUBLIC_KEY,
        }
        
        return Response({
            'status': True,
            'data': data
        })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def initialize_payment(request):
    """
    POST /api/payment/initialize/
    Initialize Paystack SPLIT payment for an order.
    """
    try:
        print(f"\n{'='*60}")
        print("🚀 INITIALIZE SPLIT PAYMENT API")
        print(f"{'='*60}")

        order_id = request.data.get('order_id')
        email = request.data.get('email', '')

        if not order_id:
            return Response({
                'status': False,
                'message': 'Order ID is required'
            }, status=400)

        # Get order and freelancer
        order = get_object_or_404(Order, order_id=order_id, employer=request.user)
        freelancer = order.freelancer
        if not freelancer:
            return Response({
                'status': False,
                'message': 'Order does not have a freelancer assigned'
            }, status=400)

        # Safely get freelancer info
        freelancer_user = getattr(freelancer, 'user', None)
        if not freelancer_user:
            return Response({
                'status': False,
                'message': 'Freelancer user info is missing'
            }, status=400)

        # Get Paystack subaccount for freelancer
        paystack_subaccount = None
        if hasattr(freelancer, 'profile') and getattr(freelancer.profile, 'paystack_subaccount_code', None):
            paystack_subaccount = freelancer.profile.paystack_subaccount_code
        else:
            paystack_subaccount = getattr(freelancer, 'paystack_subaccount_code', None)

        if not paystack_subaccount:
            return Response({
                'status': False,
                'message': 'Freelancer does not have a Paystack subaccount configured'
            }, status=400)

        # Platform subaccount
        platform_subaccount = getattr(settings, 'PAYSTACK_PLATFORM_SUBACCOUNT', None)
        if not platform_subaccount:
            return Response({
                'status': False,
                'message': 'Platform subaccount not configured in settings'
            }, status=400)

        # Generate email if missing
        if not email:
            email = f"{request.user.username.replace(' ', '.').lower()}@helawork.pay"

        # Calculate split amounts in KES -> kobo
        total_amount_kobo = int(order.amount * 100)
        freelancer_share_kobo = int(total_amount_kobo * 0.90)
        platform_share_kobo = total_amount_kobo - freelancer_share_kobo  # Ensure sum matches total

        print(f"💰 Payment Breakdown: Total={total_amount_kobo} kobo, Freelancer={freelancer_share_kobo}, Platform={platform_share_kobo}")

        # Prepare subaccounts
        subaccounts = [
            {'subaccount': paystack_subaccount, 'share': freelancer_share_kobo, 'bearer': 'subaccount'},
            {'subaccount': platform_subaccount, 'share': platform_share_kobo, 'bearer': 'subaccount'},
        ]

        # Generate unique reference
        reference = f"HW_{order_id}_{secrets.token_hex(5).upper()}"

        # Initialize Paystack split transaction
        paystack_service = PaystackService()
        response = paystack_service.initialize_split_transaction(
            email=email,
            amount=total_amount_kobo,
            reference=reference,
            subaccounts=subaccounts,
            callback_url=f"{settings.FRONTEND_URL}/payment/callback?reference={reference}"
        )

        if not response or not response.get('status'):
            error_msg = response.get('message', 'Failed to initialize split payment') if response else 'No response from Paystack'
            return Response({
                'status': False,
                'message': f'Paystack error: {error_msg}',
                'paystack_response': response
            }, status=400)

        # Create PaymentTransaction safely
        transaction = PaymentTransaction.objects.create(
            order=order,  # Must be Order instance!
            paystack_reference=reference,
            amount=Decimal(order.amount),
            platform_commission=Decimal(platform_share_kobo / 100),
            freelancer_share=Decimal(freelancer_share_kobo / 100),
            status='pending',
            employer=request.user
        )

        print(f"✅ Transaction created: {transaction.id}")

        return Response({
            'status': True,
            'message': 'Split payment initialized successfully',
            'data': {
                'authorization_url': response['data']['authorization_url'],
                'reference': reference,
                'access_code': response['data']['access_code'],
                'order_id': str(order.order_id),
                'amount': order.amount,
                'email': email,
                'split_details': {
                    'total': order.amount,
                    'freelancer_share': freelancer_share_kobo / 100,
                    'platform_commission': platform_share_kobo / 100,
                    'freelancer_percentage': 90,
                    'platform_percentage': 10,
                    'currency': 'KES'
                }
            }
        })

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_payment_api(request, reference):

    try:
        paystack = PaystackService()
        verification = paystack.verify_transaction(reference)
        
        if verification and verification.get('status'):
            transaction_data = verification['data']
            
            # Find transaction
            transaction = Transaction.objects.get(paystack_reference=reference)
            
            if transaction_data['status'] == 'success':
                # Update transaction status
                transaction.status = 'success'
                transaction.save()
                
                # Update order status
                order = transaction.order
                order.status = 'paid'
                order.save()
                
                # Serialize response data
                transaction_serializer = TransactionSerializer(transaction)
                order_serializer = OrderSerializer(order)
                
                return Response({
                    'status': True,
                    'message': 'Payment verified successfully',
                    'data': {
                        'transaction': transaction_serializer.data,
                        'order': order_serializer.data,
                        'payment_status': 'success'
                    }
                })
            else:
                # Payment failed
                transaction.status = 'failed'
                transaction.save()
                
                return Response({
                    'status': False,
                    'message': 'Payment failed or was cancelled',
                    'data': {
                        'payment_status': 'failed',
                        'reference': reference
                    }
                })
        else:
            return Response({
                'status': False,
                'message': 'Payment verification failed',
                'data': {
                    'payment_status': 'failed',
                    'reference': reference
                }
            })
            
    except Transaction.DoesNotExist:
        return Response({
            'status': False,
            'message': 'Transaction not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'status': False,
            'message': f'Error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def payment_webhook_api(request):
    
    if request.method == 'POST':
        try:
            payload = request.data
            event = payload.get('event')
            
            if event == 'charge.success':
                data = payload.get('data')
                reference = data.get('reference')
                
                # Verify the transaction
                paystack = PaystackService()
                verification = paystack.verify_transaction(reference)
                
                if verification and verification.get('status'):
                    transaction_data = verification['data']
                    
                    if transaction_data['status'] == 'success':
                        # Update transaction and order
                        transaction = Transaction.objects.get(paystack_reference=reference)
                        transaction.status = 'success'
                        transaction.save()
                        
                        order = transaction.order
                        order.status = 'paid'
                        order.save()
                        
                       
                        
            return Response({'status': 'success'})
            
        except Exception as e:
            return Response(
                {'status': 'error', 'message': str(e)}, 
                status=status.HTTP_400_BAD_REQUEST
            )
    
    return Response(
        {'status': 'error', 'message': 'Method not allowed'}, 
        status=status.HTTP_405_METHOD_NOT_ALLOWED
    )

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def transaction_history(request):
   
    try:
        if hasattr(request.user, 'client'):
            # User is a client - get their orders' transactions
            client_orders = Order.objects.filter(client__user=request.user)
            transactions = Transaction.objects.filter(order__in=client_orders)
        elif hasattr(request.user, 'freelancer'):
            # User is a freelancer - get transactions for their services
            freelancer_services = Service.objects.filter(freelancer__user=request.user)
            freelancer_orders = Order.objects.filter(service__in=freelancer_services)
            transactions = Transaction.objects.filter(order__in=freelancer_orders)
        else:
            return Response({
                'status': False,
                'message': 'User type not recognized'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = TransactionSerializer(transactions.order_by('-created_at'), many=True)
        
        return Response({
            'status': True,
            'data': serializer.data
        })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)        


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def freelancer_withdraw(request):
    amount = request.data.get('amount')
    freelancer = request.user.freelancer

    if amount > freelancer.wallet_balance:
        return Response({'status': False, 'message': 'Insufficient balance'})
    
    # Option A: Paystack transfer
    paystack = PaystackService()
    transfer = paystack.transfer(
        amount=int(amount*100),
        recipient=freelancer.paystack_recipient_code,
        reason='Freelancer withdrawal'
    )

    if transfer['status']:
        freelancer.wallet_balance -= amount
        freelancer.save()
        return Response({'status': True, 'message': 'Withdrawal successful'})
    else:
        return Response({'status': False, 'message': 'Withdrawal failed'})


from webapp.matcher import rank_freelancers_for_job



@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def suggest_freelancers(request, job_id):
   
    try:
        # Get the job (Task)
        job = get_object_or_404(Task, pk=job_id)
        
        print(f"Finding freelancers for job: {job.title} (ID: {job_id})")
        
        # Get active freelancers in same category
        candidates = UserProfile.objects.filter(
            is_active=True,
            category=job.category
        )[:100]  # Reduced from 1000 to 100 for better performance
        
        print(f"Found {candidates.count()} candidates in category: {job.category}")
        
        if not candidates:
            return Response({
                "status": False,
                "message": "No freelancers available for this category."
            })
        
        # Run the matching
        ranked_results = rank_freelancers_for_job(job, list(candidates), top_n=10)
        
        print(f"Ranking completed. Found {len(ranked_results)} matches")
        
        # Extract profile IDs from results
        profile_ids = [r["profile_id"] for r in ranked_results]
        
        # Query corresponding profile data
        profiles = UserProfileSerializer(
            UserProfile.objects.filter(profile_id__in=profile_ids),
            many=True
        ).data
        
        # Maintain ranking order and add match scores
        ordered_profiles = []
        for rank_result in ranked_results:
            profile_id = rank_result["profile_id"]
            # Find the profile with this ID
            profile = next((p for p in profiles if p["profile_id"] == profile_id), None)
            if profile:
                # Add match score to profile data
                profile_with_score = profile.copy()
                profile_with_score["match_score"] = rank_result["score"]
                profile_with_score["skill_overlap"] = rank_result["skill_overlap"]
                profile_with_score["common_skills"] = rank_result.get("common_skills", [])
                ordered_profiles.append(profile_with_score)
        
        return Response({
            "status": True,
            "job": {
                "id": job.task_id,
                "title": job.title,
                "category": job.category,
                "required_skills": job.required_skills,
            },
            "matches": ordered_profiles,
            "meta": {
                "total_candidates": candidates.count(),
                "top_matches": len(ranked_results),
                "category": job.category,
            }
        })
        
    except Exception as e:
        print(f"Error in suggest_freelancers: {e}")
        import traceback
        traceback.print_exc()
        return Response({
            "status": False,
            "message": f"Error suggesting freelancers: {str(e)}"
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def recommended_jobs(request):
    
    print(f"=== RECOMMENDED JOBS API CALLED ===")
    print(f"User: {request.user.name} (ID: {request.user.user_id})")
    
    try:
        # Get freelancer's profile
        try:
            freelancer_profile = UserProfile.objects.get(user=request.user)
            print(f"Freelancer profile found: {freelancer_profile}")
            print(f"Freelancer skills (type: {type(freelancer_profile.skills)}): {freelancer_profile.skills}")
            
            # DON'T access category - it doesn't exist
            # print(f"Freelancer category: {freelancer_profile.category}")  # REMOVE THIS LINE
            
        except UserProfile.DoesNotExist:
            return Response({
                "status": False,
                "message": "Please complete your profile to get job recommendations"
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Get all active tasks (approved and not assigned)
        all_tasks = Task.objects.select_related('employer').prefetch_related('employer__profile').filter(
            is_approved=True,
            assigned_user__isnull=True  # Only unassigned tasks
        )[:50]  # Limit to 50 for better performance
        
        print(f"Found {all_tasks.count()} active tasks")
        
        if not all_tasks.exists():
            return Response({
                "status": True,
                "message": "No available tasks",
                "recommended": []
            })
        
        # Convert tasks to list for the matcher
        tasks_list = []
        for task in all_tasks:
            employer_profile = getattr(task.employer, 'profile', None)
            task_data = {
                'id': task.task_id,
                'title': task.title,
                'description': task.description,
                'required_skills': task.required_skills or '',
                'category': task.category or '',
                'budget': str(task.budget) if task.budget else '0',
                'is_approved': task.is_approved,
                'assigned_user': task.assigned_user.user_id if task.assigned_user else None,
                'employer': {
                    'id': task.employer.employer_id,
                    'username': task.employer.username,
                    'contact_email': task.employer.contact_email,
                    'company_name': employer_profile.company_name if employer_profile else None,
                    'profile_picture': employer_profile.profile_picture.url if employer_profile and employer_profile.profile_picture else None,
                    'phone_number': employer_profile.phone_number if employer_profile else None,
                }
            }
            tasks_list.append(task_data)
        
        # Use your existing matcher function with error handling
        try:
            # Get ranked jobs
            ranked_jobs = rank_jobs_for_freelancer(freelancer_profile, all_tasks, top_n=20)
            
            # Map ranked results to full task data
            recommended_jobs = []
            for rank_result in ranked_jobs:
                job_id = rank_result["job_id"]
                # Find the task with this ID
                task_data = next((t for t in tasks_list if t['id'] == job_id), None)
                if task_data:
                    # Add match score to task data
                    task_with_score = task_data.copy()
                    task_with_score["match_score"] = rank_result["score"] * 100  # Convert to percentage
                    task_with_score["skill_overlap"] = rank_result["skill_overlap"]
                    task_with_score["base_similarity"] = rank_result["base_similarity"]
                    recommended_jobs.append(task_with_score)
            
            print(f"Matcher returned {len(recommended_jobs)} ranked jobs")
            
            return Response({
                "status": True,
                "message": f"Found {len(recommended_jobs)} recommended jobs",
                "recommended": recommended_jobs,
                "freelancer_profile": {
                    "skills": freelancer_profile.skills,
                    # REMOVE category and experience_level since they don't exist in model
                    # "category": freelancer_profile.category,
                    # "experience_level": freelancer_profile.experience_level,
                }
            })
            
        except Exception as e:
            print(f"Error in matcher: {e}")
            import traceback
            traceback.print_exc()
            # Fallback: return all tasks if matcher fails
            return Response({
                "status": True,
                "message": f"Found {len(tasks_list)} available tasks",
                "recommended": tasks_list,
                "note": "Using fallback (matcher failed)"
            })
        
    except Exception as e:
        print(f"Error in recommended_jobs API: {e}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return Response({
            "status": False,
            "message": f"Error fetching recommended jobs: {str(e)}",
            "recommended": []
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def accept_proposal(request):
    """
    Accept a proposal, lock the task, create contract, and auto-create order.
    Expects: {'proposal_id': int}
    """
    try:
        # 1️⃣ Validate employer
        try:
            employer = Employer.objects.get(pk=request.user.employer_id)
        except Employer.DoesNotExist:
            return Response({"success": False, "error": "Employer profile not found"}, status=400)

        # 2️⃣ Get proposal
        proposal_id = request.data.get('proposal_id')
        if not proposal_id:
            return Response({"success": False, "error": "proposal_id is required"}, status=400)

        proposal = get_object_or_404(Proposal, pk=proposal_id)
        task = proposal.task

        # 3️⃣ Ensure employer owns the task
        if task.employer != employer:
            return Response({"success": False, "error": "Unauthorized - only task employer can accept proposals"}, status=403)

        # 4️⃣ Prevent double acceptance
        if task.status != 'open' or task.assigned_user is not None:
            return Response({"success": False, "error": "Task already assigned"}, status=400)

        # 5️⃣ Accept proposal
        proposal.status = 'accepted'
        proposal.save()

        # 6️⃣ Reject all other proposals
        Proposal.objects.filter(task=task).exclude(pk=proposal.pk).update(status='rejected')

        # 7️⃣ Lock task
        task.assigned_user = proposal.freelancer  # User instance
        task.status = 'in_progress'
        task.is_active = False
        task.save()

        # 8️⃣ Ensure freelancer exists
        freelancer_obj, _ = Freelancer.objects.get_or_create(user=proposal.freelancer)

        # 9️⃣ Create contract
        contract = Contract.objects.create(
            task=task,
            freelancer=proposal.freelancer,
            employer=employer,
            employer_accepted=True,
            freelancer_accepted=True,
            is_active=True,
            start_date=timezone.now()
        )

        # 🔟 Auto-create order
        amount = proposal.bid_amount if proposal.bid_amount else task.budget or Decimal('0.00')

        existing_order = Order.objects.filter(
            task=task,
            employer=employer,
            freelancer=freelancer_obj,
            status='pending'
        ).first()

        if existing_order:
            order = existing_order
        else:
            order = Order.objects.create(
                order_id=uuid.uuid4(),
                employer=employer,
                task=task,
                freelancer=freelancer_obj,
                amount=Decimal(amount),
                currency='KSH',
                status='pending'
            )

            # Notify freelancer
            Notification.objects.create(
                user=proposal.freelancer,
                title='Payment Order Created',
                message=f'{employer.username} has created a payment order for task: {task.title}',
                notification_type='payment_received',
                related_id=order.id
            )

        # Notify freelancer about acceptance
        Notification.objects.create(
            user=proposal.freelancer,
            title='Proposal Accepted!',
            message=f'Your proposal for "{task.title}" has been accepted. Contract is ready.',
            notification_type='contract_accepted'
        )

        return Response({
            "success": True,
            "message": "Proposal accepted, contract created, and payment order ready",
            "proposal_id": proposal.proposal_id,
            "task_id": task.task_id,
            "task_title": task.title,
            "task_status": task.status,
            "assigned_freelancer_id": proposal.freelancer.user_id,
            "assigned_freelancer_name": proposal.freelancer.name,
            "contract_id": contract.contract_id,
            "contract_active": contract.is_active,
            "order_id": str(order.order_id),
            "order_amount": float(order.amount),
            "order_status": order.status,
        })

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({"success": False, "error": "Internal server error", "detail": str(e)}, status=500)

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def reject_contract(request, contract_id):
    contract = get_object_or_404(Contract, contract_id=contract_id)

    # Authorization: Only freelancer can reject their own contract
    if request.user != contract.freelancer:
        return Response({"error": "Unauthorized"}, status=403)

    # Reject contract
    contract.delete()  # Or mark as rejected if you want to keep record
    
    return Response({
        "message": "Contract rejected and removed"
    })
        
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def accept_contract(request, contract_id):
    contract = get_object_or_404(Contract, contract_id=contract_id)

    if request.user != contract.freelancer:
        return Response({"error": "Unauthorized"}, status=403)

    contract.freelancer_accepted = True
    contract.activate_contract()

    return Response({
        "message": "Contract accepted",
        "is_active": contract.is_active
    })
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def freelancer_contracts(request):
    try:
        # CORRECT: Filter by User directly since Contract.freelancer points to User
        contracts = Contract.objects.filter(
            freelancer=request.user
        ).select_related('task', 'employer').all()
        
        data = []
        for contract in contracts:
            # Note: Your Employer model doesn't have a 'profile' field
            # Remove employer__profile from select_related if it doesn't exist
            
            contract_data = {
                'contract_id': contract.contract_id,
                'task': {
                    'task_id': contract.task.task_id,
                    'title': contract.task.title,
                    'description': contract.task.description,
                    'budget': float(contract.task.budget) if contract.task.budget else None,
                    'deadline': contract.task.deadline.isoformat() if contract.task.deadline else None,
                },
                'employer': {
                    'id': contract.employer.employer_id,
                    'name': contract.employer.username,  # Direct field from Employer model
                    'email': contract.employer.contact_email,
                    'phone': contract.employer.phone_number,
                },
                'start_date': contract.start_date.isoformat(),
                'end_date': contract.end_date.isoformat() if contract.end_date else None,
                'employer_accepted': contract.employer_accepted,
                'freelancer_accepted': contract.freelancer_accepted,
                'is_active': contract.is_active,
                'is_fully_accepted': contract.is_fully_accepted,
                'status': 'active' if contract.is_active else 'pending',
            }
            data.append(contract_data)
        
        return Response({
            "status": True,
            "contracts": data,
            "count": len(data)
        })
        
    except Exception as e:
        print(f"Error in freelancer_contracts: {e}")
        import traceback
        print(traceback.format_exc())  # Add this for detailed error
        return Response({"error": str(e)}, status=500)
    
    
# views.py
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_mark_contract_completed(request, contract_id):
    """
    Task Provider (Employer) marks a contract as completed
    Called after they've reviewed work and made payment
    """
    try:
        user = request.user
        
        # Get the contract - user must be the employer
        contract = Contract.objects.select_related(
            'task', 'employer', 'employer__user'
        ).get(
            contract_id=contract_id,
            employer__user=user  # User must be the employer
        )
        
        # Check if payment was made
        if not contract.is_paid:
            return Response({
                'error': 'Payment must be completed first'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Mark as completed
        contract.is_completed = True
        contract.status = 'completed'
        contract.completed_date = timezone.now()
        contract.save()
        
        # Create notification for freelancer
        Notification.objects.create(
            user=contract.freelancer,
            title='Contract Completed',
            message=f'Your contract for "{contract.task.title}" has been marked as completed. You can now rate the employer.',
            notification_type='contract_completed'
        )
        
        return Response({
            'success': True,
            'message': 'Contract marked as completed successfully',
            'contract': {
                'id': contract.contract_id,
                'title': contract.task.title,
                'completed_date': contract.completed_date,
                'status': contract.status,
            }
        })
        
    except Contract.DoesNotExist:
        return Response({
            'error': 'Contract not found or you are not the employer'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)    
# Add this to your views.py file
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_contracts(request):
    """
    GET /api/employer/contracts/
    Returns ALL contracts for the employer (not just pending completions)
    """
    try:
        print(f"\n{'='*60}")
        print("EMPLOYER ALL CONTRACTS API CALLED")
        print(f"{'='*60}")
        print(f"Employer: {request.user.username}")
        
        # Get ALL contracts where this employer is involved
        contracts = Contract.objects.filter(
            employer=request.user
        ).select_related(
            'task', 
            'freelancer'
        ).order_by('-start_date')
        
        print(f"Found {contracts.count()} total contracts")
        
        contracts_data = []
        for contract in contracts:
            # Get freelancer name
            freelancer_name = contract.freelancer.name if contract.freelancer else 'Unknown'
            
            # Determine contract status
            status = 'active'
            if contract.is_completed:
                status = 'completed'
            elif not contract.is_active:
                status = 'pending'
            
            # Determine if contract can be marked as completed
            # A contract can be completed if:
            # 1. It's paid AND not completed, OR
            # 2. It's active and both parties accepted (for testing/demo)
            can_complete = (contract.is_paid and not contract.is_completed) or (
                contract.is_active and 
                contract.employer_accepted and 
                contract.freelancer_accepted
            )
            
            contract_data = {
                'contract_id': contract.contract_id,
                'task_id': contract.task.task_id if contract.task else None,
                'task_title': contract.task.title if contract.task else 'Unknown Task',
                'freelancer_id': contract.freelancer.user_id if contract.freelancer else None,
                'freelancer_name': freelancer_name,
                'freelancer_email': contract.freelancer.email if contract.freelancer else '',
                'freelancer_photo': None,  # Add if you have profile pictures
                'amount': float(contract.task.budget) if contract.task and contract.task.budget else 0.0,
                'status': status,
                'contract_status': contract.status if hasattr(contract, 'status') else status,
                'employer_accepted': contract.employer_accepted,
                'freelancer_accepted': contract.freelancer_accepted,
                'is_active': contract.is_active,
                'is_completed': contract.is_completed,
                'is_paid': contract.is_paid,
                'start_date': contract.start_date.strftime('%Y-%m-%d') if contract.start_date else None,
                'end_date': contract.end_date.strftime('%Y-%m-%d') if contract.end_date else None,
                'created_date': contract.start_date.strftime('%Y-%m-%d %H:%M:%S') if contract.start_date else None,
                'can_complete': can_complete,
                'requires_payment': not contract.is_paid and contract.is_active,
            }
            contracts_data.append(contract_data)
        
        return Response({
            'success': True,
            'count': len(contracts_data),
            'contracts': contracts_data,
            'message': f'Found {len(contracts_data)} contracts'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"ERROR in employer_contracts: {str(e)}")
        return Response({
            'error': f'Failed to fetch contracts: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_pending_completions(request):
    """
    GET /contracts/employer/pending-completions/
    Returns contracts that are paid but not completed (ready for employer to mark as completed)
    This is the endpoint your Flutter app is calling!
    """
    try:
        print(f"\n{'='*60}")
        print("EMPLOYER PENDING COMPLETIONS API CALLED")
        print(f"{'='*60}")
        print(f"Employer: {request.user.username}")
        
        # Get contracts that are paid but not completed
        contracts = Contract.objects.filter(
            employer=request.user,
            is_paid=True,
            is_completed=False,
            is_active=True
        ).select_related('task', 'freelancer')
        
        print(f"Found {contracts.count()} pending completion contracts")
        
        contracts_data = []
        for contract in contracts:
            freelancer_name = contract.freelancer.name if contract.freelancer else 'Unknown'
            
            contract_info = {
                'contract_id': contract.contract_id,
                'task_id': contract.task.task_id if contract.task else None,
                'task_title': contract.task.title if contract.task else 'Unknown Task',
                'freelancer_name': freelancer_name,
                'freelancer_email': contract.freelancer.email if contract.freelancer else '',
                'amount': float(contract.task.budget) if contract.task and contract.task.budget else 0.0,
                'status': contract.status,
                'payment_date': contract.payment_date.strftime('%Y-%m-%d') if contract.payment_date else None,
                'can_complete': True,  # Paid but not completed
                'requires_completion': True,
            }
            contracts_data.append(contract_info)
        
        return Response({
            'success': True,
            'count': len(contracts_data),
            'contracts': contracts_data,
            'message': 'Found contracts ready for completion'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"ERROR in employer_pending_completions: {str(e)}")
        return Response({
            'error': f'Failed to fetch pending completions: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)        


from decimal import Decimal
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_order(request):
    """
    POST /api/payment/create-order/
    Create payment order from accepted proposal/contract
    (Now acts as a fallback/redundancy method)
    """
    try:
        print(f"\n{'='*60}")
        print("CREATE ORDER API (Fallback)")
        print(f"{'='*60}")
        
        task_id = request.data.get('task_id')
        print(f"Task ID: {task_id}")
        
        if not task_id:
            return Response({
                'status': False,
                'message': 'task_id is required'
            }, status=400)
        
        # Get task
        try:
            task = Task.objects.get(task_id=task_id, employer=request.user)
        except Task.DoesNotExist:
            return Response({
                'status': False,
                'message': 'Task not found or not owned by you'
            }, status=404)
        
        print(f"Task: {task.title}")
        
        # Check if contract exists
        contract = Contract.objects.filter(
            task=task,
            employer=request.user,
            is_active=True
        ).first()
        
        if not contract:
            return Response({
                'status': False,
                'message': 'No active contract found for this task'
            }, status=400)
        
        print(f"Contract: {contract.contract_id}")
        print(f"Freelancer: {contract.freelancer.name}")
        
        # ✅ Check if order already exists (should exist if proposal was accepted)
        existing_order = Order.objects.filter(
            task=task,
            employer=request.user,
            freelancer=contract.freelancer
        ).first()
        
        if existing_order:
            print(f"✅ Order already exists: {existing_order.order_id}")
            return Response({
                'status': True,
                'message': 'Order already exists (auto-created when proposal was accepted)',
                'order': {
                    'order_id': str(existing_order.order_id),
                    'amount': float(existing_order.amount),
                    'status': existing_order.status,
                    'created_at': existing_order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                    'task_title': task.title,
                    'freelancer_name': contract.freelancer.name,
                }
            })
        
        # Get amount (from proposal or task budget)
        proposal = Proposal.objects.filter(
            task=task,
            freelancer=contract.freelancer,
            status='accepted'
        ).first()
        
        amount = proposal.bid_amount if proposal and proposal.bid_amount else task.budget
        if not amount:
            amount = Decimal('0.00')
        
        print(f"Amount: {amount}")
        
        # Create new order (fallback)
        import uuid
        order = Order.objects.create(
            order_id=uuid.uuid4(),
            employer=request.user,
            task=task,
            freelancer=contract.freelancer,
            amount=Decimal(str(amount)),
            currency='KSH',
            status='pending'
        )
        
        print(f"⚠ Fallback order created: {order.order_id}")
        print(f"   Note: Orders should auto-create when proposals are accepted")
        
        return Response({
            'status': True,
            'message': 'Order created (fallback method)',
            'note': 'Future orders will auto-create when proposals are accepted',
            'order': {
                'order_id': str(order.order_id),
                'amount': float(order.amount),
                'currency': order.currency,
                'status': order.status,
                'created_at': order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'task_title': task.title,
                'task_id': task.task_id,
                'freelancer_name': contract.freelancer.name,
                'freelancer_id': contract.freelancer.user_id,
                'employer_name': request.user.username,
            }
        })
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)
import secrets
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def pending_payment_orders(request):
    """
    Get all pending orders for the authenticated employer,
    including freelancer details safely.
    """
    try:
        # If request.user is Employer instance, just filter directly
        orders = Order.objects.filter(
            employer=request.user,
            status='pending'
        )

        if not orders.exists():
            return Response({
                'status': False,
                'message': 'No pending payment orders found'
            }, status=200)

        order_list = []
        for order in orders:
            freelancer_data = None
            if order.freelancer:
                user = order.freelancer.user
                freelancer_data = {
                    'freelancer_id': order.freelancer.id,
                    'name': user.name,
                    'email': user.email,
                }

            order_list.append({
                'order_id': str(order.order_id),
                'id': str(order.order_id),
                'amount': float(order.amount),
                'currency': order.currency,
                'status': order.status,
                'created_at': order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'task': None,  # Only add if Order has a task FK
                'freelancer': freelancer_data
            })

        return Response({
            'status': True,
            'orders': order_list,
            'count': len(order_list)
        }, status=200)

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({'status': False, 'message': str(e)}, status=500)


# -----------------------------
# ORDER DETAIL
# -----------------------------
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def order_detail(request, order_id):
    """
    Get a single order by ID for the authenticated employer.
    """
    try:
        order = get_object_or_404(Order, order_id=order_id, employer=request.user)
        freelancer = order.freelancer
        task = order.task

        freelancer_data = None
        if freelancer and freelancer.user:
            user = freelancer.user
            freelancer_data = {
                'id': user.user_id,
                'freelancer_id': user.user_id,
                'name': user.name,
                'email': user.email
            }

        order_data = {
            'order_id': str(order.order_id),
            'id': str(order.order_id),
            'amount': float(order.amount),
            'currency': order.currency,
            'status': order.status,
            'created_at': order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'task': {
                'task_id': task.task_id,
                'title': task.title,
                'description': task.description,
                'budget': float(task.budget) if task and task.budget else 0.0,
            } if task else None,
            'freelancer': freelancer_data,
            'employer': {
                'id': request.user.employer_id,
                'username': request.user.username,
                'email': request.user.contact_email
            }
        }

        return Response({'status': True, 'order': order_data}, status=200)

    except Order.DoesNotExist:
        return Response({'status': False, 'message': 'Order not found'}, status=404)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({'status': False, 'message': str(e)}, status=500)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def initialize_payment(request):
    """
    POST /api/payment/initialize/
    Initialize Paystack payment for an order
    """
    try:
        print(f"\n{'='*60}")
        print("🚀 INITIALIZE PAYMENT API")
        print(f"{'='*60}")
        
        # Get request data
        order_id = request.data.get('order_id')
        email = request.data.get('email', '')
        
        print(f"Order ID: {order_id}")
        print(f"Email: {email}")
        print(f"Employer: {request.user.username}")
        
        # Get the order
        order = get_object_or_404(Order, order_id=order_id, employer=request.user)
        
        # Generate email if empty
        if not email:
            email = f"{request.user.username.replace(' ', '.').lower()}@helawork.pay"
            print(f"✅ Generated email: {email}")
        
        # Calculate amount in CENTS (not kobo!)
        amount_ksh = float(order.amount)
        amount_cents = int(amount_ksh * 100)  # Convert KSH to cents
        print(f"💰 Amount: {amount_ksh} KSH = {amount_cents} cents")
        
        # Generate reference
        reference = f"HW_{order_id}_{secrets.token_hex(5)}"
        
        # Initialize Paystack payment
        paystack_service = PaystackService()
        
        # For now, use regular transaction (not split)
        response = paystack_service.initialize_transaction(
            email=email,
            amount_cents=amount_cents,  # Pass in CENTS
            reference=reference,
            callback_url=f"{settings.FRONTEND_URL}/payment/callback?reference={reference}",
            currency="KES"
        )
        
        print(f"💰 Paystack response: {response}")
        
        if response and response.get('status'):
            # Create transaction record
            try:
                from .models import PaymentTransaction
                transaction = PaymentTransaction.objects.create(
                    order=order,
                    paystack_reference=reference,
                    amount=order.amount,
                    amount_cents=amount_cents,  # Store cents too
                    platform_commission=Decimal('0.00'),
                    freelancer_share=order.amount,
                    status='pending',
                    employer=request.user
                )
                print(f"✅ PaymentTransaction created: {transaction.id}")
                print(f"   Amount: {transaction.amount} KSH = {transaction.amount_cents} cents")
            except Exception as e:
                print(f"⚠️ Could not create PaymentTransaction: {e}")
            
            return Response({
                'status': True,
                'message': 'Payment initialized successfully',
                'data': {
                    'authorization_url': response['data']['authorization_url'],
                    'reference': reference,
                    'access_code': response['data']['access_code'],
                    'order_id': str(order.order_id),
                    'amount_ksh': amount_ksh,
                    'amount_cents': amount_cents,
                    'email': email,
                    'currency': 'KES'
                }
            })
        else:
            error_msg = response.get('message', 'Failed to initialize payment') if response else 'No response from Paystack'
            print(f"❌ Paystack error: {error_msg}")
            return Response({
                'status': False,
                'message': f'Payment failed: {error_msg}',
                'paystack_response': response
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        print(f"❌ Error in initialize_payment: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_order_payment(request, order_id):
    """
    Verify that an order is completed and the freelancer is correct.
    """
    try:
        # Get the order
        order = get_object_or_404(Order, order_id=order_id)

        # Get freelancer_id from query params
        freelancer_id = request.GET.get('freelancer_id')
        if not freelancer_id:
            return Response({
                'status': False,
                'message': 'Freelancer ID is required',
                'code': 'MISSING_FREELANCER_ID'
            }, status=400)

        # Verify freelancer is assigned to this order
        if not order.freelancer or str(order.freelancer.user.user_id) != freelancer_id:
            return Response({
                'status': False,
                'message': 'Freelancer not assigned to this order',
                'code': 'FREELANCER_MISMATCH'
            }, status=400)

        # Get freelancer profile safely
        freelancer_user = order.freelancer.user
        try:
            freelancer_profile = UserProfile.objects.get(user=freelancer_user)
        except UserProfile.DoesNotExist:
            freelancer_profile = None

        # Check if work is completed
        if order.status != 'completed':
            return Response({
                'status': False,
                'message': 'Work not completed yet',
                'code': 'WORK_INCOMPLETE'
            }, status=400)

        return Response({
            'status': True,
            'message': 'Payment verified successfully',
            'data': {
                'order_id': str(order.order_id),
                'freelancer_id': freelancer_user.user_id,
                'freelancer_name': freelancer_user.name,
                'freelancer_email': freelancer_user.email,
                'freelancer_paystack_account': getattr(freelancer_profile, 'paystack_account_id', 'default_account') if freelancer_profile else 'default_account',
                'amount': float(order.amount),
                'currency': order.currency,
                'order_status': order.status,
                'work_completed': True,
                'service_description': order.task.title if order.task else 'N/A',
            }
        })

    except Order.DoesNotExist:
        return Response({
            'status': False,
            'message': 'Order not found',
            'code': 'ORDER_NOT_FOUND'
        }, status=404)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': str(e),
            'code': 'SERVER_ERROR'
        }, status=500)   
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_payment(request, reference):
    """
    GET /api/payment/verify/<str:reference>/
    Verify Paystack payment
    """
    try:
        print(f"\n{'='*60}")
        print("VERIFY PAYMENT API")
        print(f"{'='*60}")
        print(f"Reference: {reference}")
        print(f"Employer: {request.user.username}")
        
        # Verify transaction with Paystack
        paystack_service = PaystackService()
        verification = paystack_service.verify_transaction(reference)
        
        if verification and verification.get('status'):
            transaction_data = verification['data']
            
            # Get transaction from database
            try:
                transaction = Transaction.objects.get(paystack_reference=reference)
            except Transaction.DoesNotExist:
                return Response({
                    'status': False,
                    'message': 'Transaction not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            if transaction_data['status'] == 'success':
                # Update transaction status
                transaction.status = 'success'
                transaction.save()
                
                # Update order status
                order = transaction.order
                order.status = 'paid'
                order.save()
                
                # Update contract payment status
                contract = Contract.objects.filter(
                    task=order.task,
                    employer=request.user,
                    freelancer=order.freelancer
                ).first()
                
                if contract:
                    contract.is_paid = True
                    contract.payment_date = transaction.created_at
                    contract.save()
                
                print(f"✅ Payment verified successfully")
                
                return Response({
                    'status': True,
                    'message': 'Payment verified successfully',
                    'data': {
                        'reference': reference,
                        'amount': float(transaction.amount),
                        'currency': transaction_data.get('currency', 'NGN'),
                        'paid_at': transaction_data.get('paid_at'),
                        'transaction_status': 'success',
                        'order_status': 'paid',
                        'order_id': str(order.order_id)
                    }
                })
            else:
                # Payment failed
                transaction.status = 'failed'
                transaction.save()
                
                return Response({
                    'status': False,
                    'message': 'Payment failed or was cancelled',
                    'data': {
                        'reference': reference,
                        'transaction_status': 'failed'
                    }
                })
        else:
            return Response({
                'status': False,
                'message': 'Payment verification failed'
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def payment_callback(request):
    """
    GET /api/payment/callback/
    Paystack payment callback endpoint
    """
    try:
        reference = request.GET.get('reference', '')
        trxref = request.GET.get('trxref', '')
        
        print(f"\n{'='*60}")
        print("PAYMENT CALLBACK")
        print(f"{'='*60}")
        print(f"Reference: {reference}")
        print(f"trxref: {trxref}")
        
        if reference:
            # Redirect to frontend with reference
            frontend_url = f"{settings.FRONTEND_URL}/payment/callback?reference={reference}"
            return redirect(frontend_url)
        else:
            return Response({
                'status': False,
                'message': 'No reference provided'
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_transactions(request):
    try:
        employer = request.user  # Employer instance

        transactions = (
            PaymentTransaction.objects
            .filter(order__employer=employer)
            .select_related('order')
            .order_by('-created_at')
        )

        data = []
        for tx in transactions:
            order = tx.order
            data.append({
                'transaction_id': tx.id,
                'reference': tx.paystack_reference,
                'amount': float(tx.amount),
                'platform_commission': float(tx.platform_commission),
                'freelancer_share': float(tx.freelancer_share),
                'status': tx.status,
                'created_at': tx.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'order': {
                    'order_id': str(order.order_id),
                    'amount': float(order.amount),
                    'status': order.status,
                }
            })

        return Response({
            'status': True,
            'count': len(data),
            'transactions': data
        })

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)

    
@api_view(['GET'])
def payment_status(request, order_id):
    """
    GET /api/payment/status/<str:order_id>/
    Check payment status for an order
    """
    try:
        order = get_object_or_404(Order, order_id=order_id)
        
        # Get latest transaction for this order
        transaction = Transaction.objects.filter(order=order).order_by('-created_at').first()
        
        status_data = {
            'order_id': str(order.order_id),
            'order_status': order.status,
            'amount': float(order.amount),
            'currency': order.currency,
            'transaction': {
                'reference': transaction.paystack_reference if transaction else None,
                'status': transaction.status if transaction else None,
                'created_at': transaction.created_at.strftime('%Y-%m-%d %H:%M:%S') if transaction else None,
            } if transaction else None
        }
        
        return Response({
            'status': True,
            'data': status_data
        })
        
    except Order.DoesNotExist:
        return Response({
            'status': False,
            'message': 'Order not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def pending_payment_orders(request):
    """
    GET /api/orders/pending-payment/
    """
    try:
        print(f"\n{'='*60}")
        print("PENDING PAYMENT ORDERS API")
        print(f"{'='*60}")
        print(f"Employer: {request.user.username}")
        
        # ✅ NOW THIS WORKS! Order has employer field
        orders = Order.objects.filter(
            employer=request.user,  # ✅ Direct filter by employer
            status='pending'
        ).select_related('task', 'freelancer')
        
        print(f"Found {orders.count()} pending orders")
        
        order_list = []
        for order in orders:
            order_data = {
                'order_id': str(order.order_id),
                'id': str(order.order_id),
                'amount': float(order.amount),
                'currency': order.currency,
                'status': order.status,
                'created_at': order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'task': {
                    'task_id': order.task.task_id if order.task else None,
                    'title': order.task.title if order.task else 'Unknown',
                    'description': order.task.description if order.task else '',
                } if order.task else None,
                'freelancer': {
                    'name': order.freelancer.name if order.freelancer else 'Unknown',
                    'email': order.freelancer.email if order.freelancer else None,
                } if order.freelancer else None
            }
            order_list.append(order_data)
        
        return Response({
            'status': True,
            'orders': order_list,
            'count': len(order_list)
        })
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)        
        