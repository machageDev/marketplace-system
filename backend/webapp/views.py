from decimal import Decimal
import secrets
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

from rest_framework.response import Response
from django.db import  transaction
from rest_framework import status
from django.core.mail import send_mail
from webapp.matcher import rank_jobs_for_freelancer
from webapp.paystack_service import PaystackService
from .models import Contract, Employer, EmployerProfile, EmployerToken, Order, Proposal, Rating, Service, Submission, Task, TaskCompletion, Transaction, UserProfile, Wallet
from .models import  User
from rest_framework.permissions import IsAuthenticated
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import authentication_classes, permission_classes, api_view
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from webapp.serializers import ContractSerializer, EmployerProfileSerializer,  EmployerRegisterSerializer, EmployerSerializer, LoginSerializer, OrderSerializer, PaymentInitializeSerializer, ProposalSerializer, RatingSerializer, RegisterSerializer, SubmissionCreateSerializer, SubmissionSerializer, TaskCompletionSerializer, TaskCreateSerializer, TaskSerializer, TransactionSerializer, UserProfileSerializer, WalletSerializer
from .authentication import CustomTokenAuthentication, EmployerTokenAuthentication
from .permissions import IsAuthenticated  
from .models import UserProfile
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.response import Response
from rest_framework import status
from .authentication import EmployerTokenAuthentication, IsAuthenticated
from .models import Task, Proposal
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
                    'company_name': employer_profile.company_name if employer_profile else None,
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
 
 
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_employer_profile(request, employer_id):
    """
    Get employer profile by employer_id
    """
    try:
        # Add permission check to ensure user can only access their own profile
        if request.user.id != employer_id and not request.user.is_staff:
            return Response(
                {'error': 'You do not have permission to access this profile'}, 
                status=status.HTTP_403_FORBIDDEN
            )
            
        profile = EmployerProfile.objects.get(employer_id=employer_id)
        serializer = EmployerProfileSerializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except EmployerProfile.DoesNotExist:
        return Response(
            {'error': 'Profile not found', 'employer_id': employer_id}, 
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        return Response(
            {'error': f'Server error: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_employer_profile(request):
   
    try:
        # Ensure user can only create their own profile
        if 'employer' in request.data and request.data['employer'] != request.user.id:
            return Response(
                {'error': 'You can only create your own profile'}, 
                status=status.HTTP_403_FORBIDDEN
            )
            
        # Check if profile already exists
        existing_profile = EmployerProfile.objects.filter(employer_id=request.user.id).first()
        if existing_profile:
            return Response(
                {'error': 'Profile already exists. Use update instead.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        serializer = EmployerProfileSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(
            {'error': 'Validation failed', 'details': serializer.errors}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        return Response(
            {'error': f'Server error: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['PUT', 'PATCH'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def update_employer_profile(request, employer_id):
    
    try:
        # Permission check
        if request.user.id != employer_id and not request.user.is_staff:
            return Response(
                {'error': 'You do not have permission to update this profile'}, 
                status=status.HTTP_403_FORBIDDEN
            )
            
        try:
            profile = EmployerProfile.objects.get(employer_id=employer_id)
        except EmployerProfile.DoesNotExist:
            return Response(
                {'error': 'Profile not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Determine if it's partial update (PATCH) or full update (PUT)
        partial = request.method == 'PATCH'
        
        serializer = EmployerProfileSerializer(
            profile, 
            data=request.data, 
            partial=partial
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        return Response(
            {'error': 'Validation failed', 'details': serializer.errors}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        return Response(
            {'error': f'Server error: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def check_profile_exists(request):
   
    try:
        profile = EmployerProfile.objects.filter(employer_id=request.user.id).first()
        exists = profile is not None
        return Response(
            {'exists': exists, 'profile_id': profile.id if profile else None}, 
            status=status.HTTP_200_OK
        )
    except Exception as e:
        return Response(
            {'error': f'Server error: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

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

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_ratings(request, user_id):
    ratings = Rating.objects.filter(rated_user_id=user_id).order_by('-created_at')
    serializer = RatingSerializer(ratings, many=True)
    return Response(serializer.data)

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
def initialize_payment_api(request):
   
    serializer = PaymentInitializeSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response({
            'status': False,
            'message': 'Invalid data',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        order_id = serializer.validated_data['order_id']
        email = serializer.validated_data['email']
        
        order = get_object_or_404(Order, order_id=order_id)
        
        # Calculate split amounts
        total_amount = float(order.amount)
        platform_commission = total_amount * 0.10  # 10%
        freelancer_share = total_amount * 0.90     # 90%
        
        # Generate unique reference
        reference = f"HW_{order_id}_{secrets.token_hex(5)}"
        
        # Prepare subaccounts for split payment
        subaccounts = [
            {
                'subaccount': order.service.freelancer.paystack_subaccount_code,
                'share': int(freelancer_share * 100),  # Convert to kobo
                'bearer': 'subaccount'
            }
        ]
        
        paystack = PaystackService()
        
        # Initialize split payment
        response = paystack.initialize_split_payment(
            email=email,
            amount=total_amount,
            reference=reference,
            subaccounts=subaccounts,
            callback_url=f"{settings.PAYSTACK_CALLBACK_URL}{reference}/"
        )
        
        if response and response.get('status'):
            # Create transaction record
            transaction = Transaction.objects.create(
                order=order,
                paystack_reference=reference,
                amount=total_amount,
                platform_commission=platform_commission,
                freelancer_share=freelancer_share,
                status='pending'
            )
            
            return Response({
                'status': True,
                'message': 'Payment initialized successfully',
                'data': {
                    'authorization_url': response['data']['authorization_url'],
                    'reference': reference,
                    'transaction_id': transaction.id
                }
            })
        else:
            return Response({
                'status': False,
                'message': 'Failed to initialize payment with Paystack'
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'status': False,
            'message': f'Error: {str(e)}'
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
        
        # Use your existing matcher function
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
                    "category": freelancer_profile.category,
                    "experience_level": freelancer_profile.experience_level,
                }
            })
            
        except Exception as e:
            print(f"Error in matcher: {e}")
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
def accept_proposal(request, proposal_id):
    print(f"\n{'='*60}")
    print("ACCEPT PROPOSAL - START")
    print(f"{'='*60}")
    
    try:
        proposal = get_object_or_404(Proposal, proposal_id=proposal_id)
        task = proposal.task
        
        print(f"Proposal ID: {proposal_id}")
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

        #  FIX: Create ACTIVE contract with both parties accepted
        from django.utils import timezone
        contract = Contract.objects.create(
            task=task,
            freelancer=proposal.freelancer,
            employer=task.employer,
            employer_accepted=True,
            freelancer_accepted=True,  # Freelancer accepts by default when proposal is accepted
            is_active=True,  # Contract should be active immediately
            start_date=timezone.now()
        )
        print(f"✓ Contract created: ID={contract.contract_id}")
        print(f"  Contract is_active: {contract.is_active}")
        print(f"  employer_accepted: {contract.employer_accepted}")
        print(f"  freelancer_accepted: {contract.freelancer_accepted}")
 

        print(f"\n{'='*60}")
        print("SUCCESS: Proposal accepted and ACTIVE contract created")
        print(f"{'='*60}")
        
        return Response({
            "success": True,
            "message": "Proposal accepted and task locked successfully",
            "task_id": task.task_id,
            "task_title": task.title,
            "task_status": task.status,
            "assigned_freelancer_id": proposal.freelancer.user_id,
            "assigned_freelancer_name": proposal.freelancer.name,
            "contract_id": contract.contract_id,
            "contract_active": contract.is_active,
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