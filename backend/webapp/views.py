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
from .models import Contract, Employer, EmployerProfile, EmployerToken, Notification, Order, PaymentTransaction, Proposal, Rating, Service, Submission, Task, TaskCompletion, Transaction, UserProfile, Wallet
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
from .serializers import EmployerProfileSerializer, EmployerProfileCreateSerializer, EmployerProfileUpdateSerializer, IDNumberUpdateSerializer

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
        print(f"1. User object: {request.user}")
        print(f"   User ID: {request.user.user_id}")
        print(f"   User Name: {request.user.name}")
        print(f"   Is authenticated: {request.user.is_authenticated}")
        
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
        
        # Step 4: Import models
        print(f"\n4. Importing models...")
        try:
            from django.apps import apps
            Task = apps.get_model('webapp', 'Task')
            Contract = apps.get_model('webapp', 'Contract')
            print(f"   ✓ Successfully imported Task and Contract models")
        except LookupError as e:
            print(f"   ✗ Model import failed: {e}")
            raise
        
        # Step 5: Get task
        print(f"\n5. Getting task...")
        try:
            task = Task.objects.get(task_id=task_id)
            print(f"   ✓ Task found: ID={task.task_id}, Title='{task.title}'")
        except Task.DoesNotExist:
            print(f"   ✗ Task not found")
            return Response(
                {"success": False, "error": f"Task with ID {task_id} not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            print(f"   ✗ Error getting task: {type(e).__name__}: {e}")
            raise
        
        # Step 6: ✅ STRICT contract check - NO auto-creation
        print(f"\n6. Checking for ACTIVE contract...")
        try:
            # Only accept submissions with ACTIVE contracts
            contract = Contract.objects.get(
                task=task,
                freelancer=request.user,
                is_active=True,  # Must be active
                employer_accepted=True,  # Both must have accepted
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
        
        # Step 7: Check if submission already exists (prevent duplicates)
        print(f"\n7. Checking for existing submissions...")
        existing_submission = Submission.objects.filter(
            task=task,
            freelancer=request.user,
            contract=contract
        ).first()
        
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
        
        # Step 8: Create serializer
        print(f"\n8. Creating serializer...")
        try:
            from .serializers import SubmissionCreateSerializer
            serializer = SubmissionCreateSerializer(
                data=request.data,
                context={
                    'task': task,
                    'freelancer': request.user,
                    'contract': contract,
                    'is_resubmission': bool(existing_submission)
                }
            )
            print(f"   ✓ Serializer created")
        except Exception as e:
            print(f"   ✗ Error creating serializer: {type(e).__name__}: {e}")
            raise
        
        # Step 9: Validate serializer
        print(f"\n9. Validating serializer...")
        if serializer.is_valid():
            print(f"   ✓ Serializer is valid")
        else:
            print(f"   ✗ Serializer validation failed")
            print(f"   Errors: {serializer.errors}")
            return Response({
                "success": False,
                "error": "Validation failed",
                "errors": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Step 10: Save submission
        print(f"\n10. Saving submission...")
        try:
            submission = serializer.save()
            print(f"   ✓ Submission saved: ID={submission.submission_id}")
            print(f"   Status: {submission.status}")
            
            # ✅ Optional: Send notification to employer
            # try:
            #     send_email_notification(
            #         to_email=contract.employer.contact_email,
            #         subject=f"New Submission for {task.title}",
            #         message=f"{request.user.name} has submitted work for task: {task.title}"
            #     )
            #     print(f"   ✓ Notification sent to employer")
            # except Exception as notify_error:
            #     print(f"   ⚠ Notification failed: {notify_error}")
            
        except Exception as e:
            print(f"   ✗ Error saving submission: {type(e).__name__}: {e}")
            raise
        
        # Success!
        print(f"\n{'='*60}")
        print("SUCCESS: Submission created")
        print(f"{'='*60}")
        
        return Response({
            "success": True,
            "message": "Submission created successfully",
            "submission_id": submission.submission_id,
            "status": submission.status,
            "submitted_at": submission.submitted_at,
            "task_id": task.task_id,
            "task_title": task.title,
            "contract_id": contract.contract_id,
            "is_resubmission": bool(existing_submission)
        }, status=status.HTTP_201_CREATED)
        
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

# Rating Views
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_rating(request):
    try:
        data = request.data.copy()
        data['rater'] = request.user.id
        
        # Validate that user doesn't rate themselves
        if data.get('rated_user') == request.user.id:
            return Response(
                {"error": "You cannot rate yourself"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = RatingSerializer(data=data)
        if serializer.is_valid():
            rating = serializer.save()
            return Response(
                {"message": "Rating created successfully", "rating_id": rating.rating_id},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response(
            {"error": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# In your views.py - Update get_user_ratings view
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
    Get contracts that are eligible for rating by the current user.
    """
    try:
        user = request.user
        
        # ============ DEBUG: Check what fields the user has ============
        print(f"DEBUG: User object type: {type(user)}")
        print(f"DEBUG: User object dir: {[attr for attr in dir(user) if not attr.startswith('_')][:20]}")
        
        # Try to get user identifier
        user_pk = user.pk if hasattr(user, 'pk') else 'unknown'
        
        # Check common primary key field names
        if hasattr(user, 'user_id'):
            user_pk = user.user_id
        elif hasattr(user, 'uid'):
            user_pk = user.uid
        elif hasattr(user, 'userId'):
            user_pk = user.userId
        
        print(f"DEBUG: User PK/ID: {user_pk}")
        
        # ============ Get contracts where user is the FREELANCER ============
        # Try different ways to filter by user
        try:
            # First try: user is freelancer directly
            contracts = Contract.objects.filter(
                freelancer=user,
                is_completed=True,
                is_paid=True
            )
        except Exception as e:
            print(f"DEBUG: Direct filter failed: {e}")
            # Try alternative: user might be referenced differently
            contracts = Contract.objects.none()
        
        print(f"DEBUG: Found {contracts.count()} completed/paid contracts")
        
        # ============ Prepare response ============
        rateable_contracts = []
        for contract in contracts:
            try:
                # Get employer info
                employer = contract.employer
                employer_user = employer.user if hasattr(employer, 'user') else employer
                
                # Get employer identifier
                employer_id = employer_user.pk if hasattr(employer_user, 'pk') else 'unknown'
                employer_name = "Employer"
                
                if hasattr(employer_user, 'email'):
                    employer_name = employer_user.email.split('@')[0]
                elif hasattr(employer_user, 'name'):
                    employer_name = employer_user.name
                elif hasattr(employer_user, 'first_name'):
                    employer_name = employer_user.first_name
                
                # Get task info
                task_title = str(contract.task) if contract.task else "Task"
                if hasattr(contract.task, 'title'):
                    task_title = contract.task.title
                
                rateable_contracts.append({
                    'contract_id': contract.contract_id,
                    'task': {
                        'id': contract.task.id if hasattr(contract.task, 'id') else 0,
                        'title': task_title,
                        'budget': contract.task.budget if hasattr(contract.task, 'budget') else 0,
                    },
                    'user_to_rate': {
                        'id': employer_id,
                        'username': employer_name,
                        'email': getattr(employer_user, 'email', ''),
                    },
                    'current_user_role': 'freelancer',
                    'other_party_role': 'employer',
                    'completed_date': contract.completed_date.isoformat() if contract.completed_date else None,
                    'payment_date': contract.payment_date.isoformat() if contract.payment_date else None,
                })
                
            except Exception as e:
                print(f"DEBUG: Error processing contract {contract.contract_id}: {e}")
                continue
        
        return Response({
            'success': True,
            'count': len(rateable_contracts),
            'contracts': rateable_contracts,
            'debug_info': {
                'user_pk': user_pk,
                'user_type': str(type(user)),
                'contracts_found': contracts.count(),
            }
        })
        
    except Exception as e:
        import traceback
        error_detail = traceback.format_exc()
        print(f"ERROR in get_rateable_contracts: {error_detail}")
        
        return Response({
            'success': False,
            'error': str(e),
            'debug': 'Check user model and contract relationships'
        }, status=500)
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
    if request.method == 'GET':
        try:
            
            employer = Employer.objects.filter(contact_email=request.user.email).first()
            
            if not employer:
                return JsonResponse([], safe=False)
            
            # Get completed tasks with assigned freelancers
            completed_tasks = Task.objects.filter(
                employer=employer,
                assigned_user__isnull=False,
                status='completed'
            ).select_related('assigned_user')

            tasks_data = []
            for task in completed_tasks:
                # Check if already rated
                already_rated = Rating.objects.filter(
                    task=task,
                    rater=request.user,  # This is User model
                    rated_user=task.assigned_user  # This is also User model
                ).exists()
                
                if not already_rated:
                    tasks_data.append({
                        'id': task.task_id,
                        'title': task.title,
                        'description': task.description,
                        'freelancer': {
                            'id': task.assigned_user.user_id,
                            'username': task.assigned_user.name,
                        }
                    })

            return JsonResponse(tasks_data, safe=False)
            
        except Exception as e:
            print(f"Error: {e}")
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
    Initialize Paystack payment for an order
    """
    try:
        print(f"\n{'='*60}")
        print("🚀 INITIALIZE PAYMENT API CALLED!")
        print(f"{'='*60}")
        
        # Print all request details
        print(f"📋 Request Method: {request.method}")
        print(f"📋 Request Path: {request.path}")
        print(f"📋 Request Headers:")
        for header, value in request.headers.items():
            print(f"   {header}: {value}")
        print(f"📋 Request Content-Type: {request.content_type}")
        print(f"📋 Request Body: {request.body}")
        print(f"📋 Request Data: {request.data}")
        
        # Get request data
        order_id = request.data.get('order_id')
        email = request.data.get('email')
        
        print(f"\n📦 Request Data Analysis:")
        print(f"   order_id: '{order_id}'")
        print(f"   email: '{email}'")
        print(f"   Type of order_id: {type(order_id)}")
        print(f"   Type of email: {type(email)}")
        
        print(f"\n👤 Employer Info:")
        print(f"   Username: '{request.user.username}'")
        print(f"   Employer ID: {request.user.employer_id}")
        
        # Check employer fields
        print(f"\n🔍 Checking Employer Fields:")
        employer_fields = ['contact_email', 'email', 'contact_email_address', 'contactEmail']
        for field in employer_fields:
            if hasattr(request.user, field):
                value = getattr(request.user, field)
                print(f"   {field}: '{value}'")
        
        # Get employer from DB to be sure
        from .models import Employer
        try:
            db_employer = Employer.objects.get(pk=request.user.employer_id)
            print(f"\n💾 Database Employer Check:")
            print(f"   DB contact_email: '{db_employer.contact_email}'")
            print(f"   DB username: '{db_employer.username}'")
            print(f"   DB employer_id: {db_employer.employer_id}")
        except Employer.DoesNotExist:
            print(f"\n❌ Employer not found in database!")
        except Exception as e:
            print(f"\n❌ Error getting employer from DB: {e}")
        
        # ✅ **AUTO-GENERATE EMAIL IF MISSING**
        if not email:
            print(f"\n📧 Email is empty in request, trying to get from employer...")
            
            # Try different sources for email
            possible_emails = []
            
            # 1. From request.user (authenticated employer)
            if hasattr(request.user, 'contact_email') and request.user.contact_email:
                possible_emails.append(request.user.contact_email)
                print(f"   Found in request.user.contact_email: '{request.user.contact_email}'")
            
            # 2. From database employer
            try:
                db_employer = Employer.objects.get(pk=request.user.employer_id)
                if db_employer.contact_email:
                    possible_emails.append(db_employer.contact_email)
                    print(f"   Found in DB employer.contact_email: '{db_employer.contact_email}'")
            except:
                pass
            
            # 3. Generate from username
            if not possible_emails:
                generated_email = f"{request.user.username}@helawork.test"
                possible_emails.append(generated_email)
                print(f"   Generated email: '{generated_email}'")
            
            # Use the first available email
            email = possible_emails[0]
            print(f"   ✅ Selected email: '{email}'")
        
        print(f"\n🎯 Final Values:")
        print(f"   order_id: '{order_id}'")
        print(f"   email: '{email}'")
        
        # Validation
        if not order_id:
            print(f"\n❌ Validation failed: order_id is required")
            return Response({
                'status': False,
                'message': 'order_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not email:
            print(f"\n❌ Validation failed: email is required")
            return Response({
                'status': False,
                'message': 'email is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get the order
        print(f"\n🔍 Getting order from database...")
        try:
            order = Order.objects.get(order_id=order_id, employer=request.user)
            print(f"   ✅ Order found: {order.order_id}")
            print(f"   Order amount: {order.amount}")
            print(f"   Order status: {order.status}")
            print(f"   Order employer: {order.employer.username}")
        except Order.DoesNotExist:
            print(f"\n❌ Order not found: order_id='{order_id}', employer='{request.user.username}'")
            return Response({
                'status': False,
                'message': 'Order not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Check if order is already paid
        if order.status == 'paid':
            print(f"\n❌ Order already paid")
            return Response({
                'status': False,
                'message': 'Order is already paid'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate reference
        reference = f"HW_{order_id}_{secrets.token_hex(5)}"
        print(f"\n🔢 Generated reference: {reference}")
        
        # Initialize Paystack payment
        print(f"\n💳 Initializing Paystack payment...")
        paystack_service = PaystackService()
        
        # Convert amount to cents
        amount_in_cents = int(float(order.amount) * 100)
        print(f"   Amount: {order.amount} KSH")
        print(f"   Amount in cents: {amount_in_cents}")
        print(f"   Email for Paystack: {email}")
        print(f"   Currency: KES")
        
        # Initialize transaction
        response = paystack_service.initialize_transaction(
            email=email,
            amount=amount_in_cents,
            reference=reference,
            callback_url=f"{settings.PAYSTACK_CALLBACK_URL}?reference={reference}",
            currency="KES"
        )
        
        print(f"\n🔄 Paystack Response:")
        print(f"   Response status: {response.get('status')}")
        print(f"   Response message: {response.get('message')}")
        
        if response and response.get('status'):
            # Create transaction record
            transaction = Transaction.objects.create(
                order=order,
                paystack_reference=reference,
                amount=order.amount,
                status='pending',
                employer=request.user
            )
            
            print(f"\n✅ SUCCESS: Payment initialized!")
            print(f"   Authorization URL: {response['data']['authorization_url']}")
            print(f"   Reference: {reference}")
            print(f"   Transaction ID: {transaction.id}")
            
            return Response({
                'status': True,
                'message': 'Payment initialized successfully',
                'data': {
                    'authorization_url': response['data']['authorization_url'],
                    'reference': reference,
                    'order_id': str(order.order_id),
                    'amount': float(order.amount),
                    'email': email,
                    'employer_name': request.user.username,
                }
            })
        else:
            error_msg = response.get('message', 'Failed to initialize payment')
            print(f"\n❌ Paystack error: {error_msg}")
            return Response({
                'status': False,
                'message': error_msg
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        print(f"\n💥 UNEXPECTED ERROR:")
        print(f"   Error type: {type(e).__name__}")
        print(f"   Error message: {str(e)}")
        import traceback
        print(f"   Traceback:\n{traceback.format_exc()}")
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
    print(f"\n{'='*60}")
    print("ACCEPT PROPOSAL - START")
    print(f"{'='*60}")
    
    try:
        proposal = get_object_or_404(Proposal)
        task = proposal.task
        
        print(f"Proposal ID: ")
        print(f"Task: {task.title} (ID: {task.task_id})")
        print(f"Freelancer: {proposal.freelancer.name} (ID: {proposal.freelancer.user_id})")
        print(f"Employer making request: {request.user.username}")

        
        if request.user != task.employer:
            print("✗ Unauthorized - only task employer can accept proposals")
            return Response(
                {"success": False, "error": "Unauthorized - only task employer can accept proposals"},
                status=403
            )

        # Prevent double acceptance
        if task.status != 'open' or task.assigned_user is not None:
            print("✗ Task already assigned or not open")
            return Response(
                {"success": False, "error": "Task already assigned"},
                status=400
            )

        # Accept proposal
        proposal.status = 'accepted'
        proposal.save()
        print(f"✓ Proposal accepted")

        # Reject all others
        rejected_count = Proposal.objects.filter(task=task)\
            .exclude(proposal_id=proposal.proposal_id)\
            .update(status='rejected')
        print(f"✓ Rejected {rejected_count} other proposals")

        # LOCK TASK
        task.assigned_user = proposal.freelancer
        task.status = 'in_progress'
        task.is_active = False
        task.save()
        print(f"✓ Task locked and assigned to freelancer")

        # Create ACTIVE contract
        from django.utils import timezone
        contract = Contract.objects.create(
            task=task,
            freelancer=proposal.freelancer,
            employer=task.employer,
            employer_accepted=True,
            freelancer_accepted=True,
            is_active=True,
            start_date=timezone.now()
        )
        print(f"✓ Contract created: ID={contract.contract_id}")
        
        # ✅ ✅ ✅ **AUTO-CREATE ORDER WHEN PROPOSAL IS ACCEPTED** ✅ ✅ ✅
        from decimal import Decimal
        import uuid
        
        # Get amount from proposal or task budget
        amount = proposal.bid_amount if proposal.bid_amount else task.budget
        if not amount:
            amount = Decimal('0.00')
        
        # Check if order already exists (safety check)
        existing_order = Order.objects.filter(
            task=task,
            employer=request.user,
            freelancer=proposal.freelancer,
            status='pending'
        ).first()
        
        if existing_order:
            print(f"⚠ Order already exists: {existing_order.order_id}")
            order = existing_order
        else:
            # Create NEW order for this contract
            order = Order.objects.create(
                order_id=uuid.uuid4(),
                employer=request.user,
                task=task,
                freelancer=proposal.freelancer,
                amount=Decimal(str(amount)),
                currency='KSH',
                status='pending'
            )
            print(f"✅ Auto-created order: {order.order_id}")
            print(f"   Amount: {order.amount}")
            print(f"   Status: {order.status}")
            
            # Create notification for freelancer
            Notification.objects.create(
                user=proposal.freelancer,
                title='Payment Order Created',
                message=f'{request.user.username} has created a payment order for task: {task.title}',
                notification_type='payment_received',
                related_id=order.id
            )
        
        # Also notify freelancer about contract acceptance
        Notification.objects.create(
            user=proposal.freelancer,
            title='Proposal Accepted!',
            message=f'Your proposal for "{task.title}" has been accepted. Contract is ready.',
            notification_type='contract_accepted'
        )

        print(f"\n{'='*60}")
        print("SUCCESS: Proposal accepted, contract created, and order ready!")
        print(f"{'='*60}")
        
        return Response({
            "success": True,
            "message": "Proposal accepted, contract created, and payment order is ready",
            "task_id": task.task_id,
            "task_title": task.title,
            "task_status": task.status,
            "assigned_freelancer_id": proposal.freelancer.user_id,
            "assigned_freelancer_name": proposal.freelancer.name,
            "contract_id": contract.contract_id,
            "contract_active": contract.is_active,
            "order_created": True,
            "order_id": str(order.order_id),
            "order_amount": float(order.amount),
            "order_status": order.status,
            "task_locked": True
        })

    except Exception as e:
        print(f"\n{'='*60}")
        print("ERROR in accept_proposal")
        print(f"{'='*60}")
        print(f"Error: {e}")
        import traceback
        print(f"Traceback:\n{traceback.format_exc()}")
        
        return Response(
            {"success": False, "error": "Internal server error", "detail": str(e)},
            status=500
        )

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

from webapp.paystack_service import PaystackService

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def pending_payment_orders(request):
    """
    GET /api/orders/pending-payment/
    Get all pending payment orders for the authenticated employer
    """
    try:
        print(f"\n{'='*60}")
        print("PENDING PAYMENT ORDERS API")
        print(f"{'='*60}")
        print(f"Employer: {request.user.username} (ID: {request.user.employer_id})")
        
        # Get pending orders for this employer
        orders = Order.objects.filter(
            employer=request.user,
            status='pending'
        ).select_related('task', 'freelancer')
        
        print(f"Found {orders.count()} pending orders")
        
        if not orders.exists():
            return Response({
                'status': False,
                'message': 'No pending payment orders found'
            }, status=status.HTTP_200_OK)
        
        order_list = []
        for order in orders:
            order_data = {
                'order_id': str(order.order_id),
                'id': str(order.order_id),  # For compatibility
                'amount': float(order.amount),
                'currency': order.currency,
                'status': order.status,
                'created_at': order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'task': {
                    'task_id': order.task.task_id,
                    'title': order.task.title,
                    'description': order.task.description,
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
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def order_detail(request, order_id):
    """
    GET /api/payment/order/<str:order_id>/
    Get order details by ID
    """
    try:
        print(f"\n{'='*60}")
        print("ORDER DETAIL API")
        print(f"{'='*60}")
        print(f"Order ID: {order_id}")
        print(f"Employer: {request.user.username}")
        
        # Get the order
        order = get_object_or_404(Order, order_id=order_id, employer=request.user)
        
        # Get task and freelancer info
        task = order.task
        freelancer = order.freelancer
        
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
                'budget': float(task.budget) if task.budget else 0.0,
            } if task else None,
            'freelancer': {
                'name': freelancer.name if freelancer else 'Unknown',
                'email': freelancer.email if freelancer else None,
                'user_id': freelancer.user_id if freelancer else None,
            } if freelancer else None,
            'employer': {
                'id': request.user.employer_id,
                'username': request.user.username,
                'email': request.user.contact_email,
            }
        }
        
        return Response({
            'status': True,
            'order': order_data
        })
        
    except Order.DoesNotExist:
        return Response({
            'status': False,
            'message': 'Order not found'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"Error: {str(e)}")
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
        print("INITIALIZE PAYMENT API")
        print(f"{'='*60}")
        
        # Get request data
        order_id = request.data.get('order_id')
        email = request.data.get('email')
        
        print(f"Order ID: {order_id}")
        print(f"Email: {email}")
        print(f"Employer: {request.user.username}")
        
        # Validation
        if not order_id:
            return Response({
                'status': False,
                'message': 'order_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not email:
            return Response({
                'status': False,
                'message': 'email is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get the order
        try:
            order = Order.objects.get(order_id=order_id, employer=request.user)
        except Order.DoesNotExist:
            return Response({
                'status': False,
                'message': 'Order not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Check if order is already paid
        if order.status == 'paid':
            return Response({
                'status': False,
                'message': 'Order is already paid'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate reference
        reference = f"HW_{order_id}_{secrets.token_hex(5)}"
        
        # Initialize Paystack payment
        paystack_service = PaystackService()
        
        # Convert amount to kobo (Paystack uses kobo for NGN)
        amount_in_kobo = int(float(order.amount) * 100)
        
        # Initialize transaction
        response = paystack_service.initialize_transaction(
            email=email,
            amount=amount_in_kobo,
            reference=reference,
            callback_url=f"{settings.PAYSTACK_CALLBACK_URL}?reference={reference}"
        )
        
        if response and response.get('status'):
            # Create transaction record
            transaction = Transaction.objects.create(
                order=order,
                paystack_reference=reference,
                amount=order.amount,
                status='pending',
                employer=request.user
            )
            
            print(f"✅ Payment initialized successfully")
            print(f"Authorization URL: {response['data']['authorization_url']}")
            print(f"Reference: {reference}")
            
            return Response({
                'status': True,
                'message': 'Payment initialized successfully',
                'data': {
                    'authorization_url': response['data']['authorization_url'],
                    'reference': reference,
                    'access_code': response['data']['access_code'],
                    'order_id': str(order.order_id),
                    'amount': float(order.amount),
                    'email': email
                }
            })
        else:
            error_msg = response.get('message', 'Failed to initialize payment')
            print(f"❌ Paystack error: {error_msg}")
            return Response({
                'status': False,
                'message': error_msg
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

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
    """
    GET /api/payment/transactions/
    Get payment transactions for the employer via PaymentTransaction model
    """
    try:
        print(f"\n{'='*60}")
        print("EMPLOYER PAYMENT TRANSACTIONS")
        print(f"{'='*60}")
        print(f"Employer: {request.user.username}")
        
        # Get PaymentTransaction records via Order
        # PaymentTransaction -> Order -> Employer
        payment_transactions = PaymentTransaction.objects.filter(
            order__employer=request.user  # Go through Order to get Employer
        ).select_related('order', 'order__task', 'order__freelancer').order_by('-created_at')
        
        print(f"Found {payment_transactions.count()} payment transactions")
        
        transactions_data = []
        for pt in payment_transactions:
            transaction_info = {
                'id': pt.id,
                'paystack_reference': pt.paystack_reference,
                'amount': float(pt.amount),
                'platform_commission': float(pt.platform_commission),
                'freelancer_share': float(pt.freelancer_share),
                'status': pt.status,
                'created_at': pt.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'order': {
                    'order_id': str(pt.order.order_id),
                    'amount': float(pt.order.amount),
                    'status': pt.order.status,
                } if pt.order else None,
                'task': {
                    'title': pt.order.task.title if pt.order and pt.order.task else 'Unknown',
                } if pt.order and pt.order.task else None
            }
            transactions_data.append(transaction_info)
        
        # If no PaymentTransaction records, check if we have Orders
        if not transactions_data:
            orders = Order.objects.filter(employer=request.user)
            print(f"Found {orders.count()} orders (but no PaymentTransaction records)")
            
            # Return orders as placeholder
            for order in orders:
                transactions_data.append({
                    'id': str(order.order_id),
                    'type': 'order',
                    'amount': float(order.amount),
                    'status': order.status,
                    'created_at': order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                    'note': 'Payment transaction not yet created'
                })
        
        return Response({
            'status': True,
            'transactions': transactions_data,
            'count': len(transactions_data),
            'employer_id': request.user.employer_id
        })
        
    except Exception as e:
        print(f"Error: {str(e)}")
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
        