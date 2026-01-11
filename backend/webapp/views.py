from decimal import Decimal
import secrets
from django.conf import settings
from django.http import Http404, JsonResponse
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
from webapp.utils import get_bank_name
from .models import Contract, Employer, EmployerProfile, EmployerToken, Freelancer, Notification, Order, PaymentTransaction, Proposal, Rating, Service, Submission, Task, TaskCompletion, Transaction, UserProfile, Wallet, WithdrawalRequest
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
from django_ratelimit.decorators import ratelimit
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
        
        employer = request.user
        data = request.data
        task_id = data.get('task')
        freelancer_id = data.get('rated_user')
        score = data.get('score')
        review = data.get('review', '')
        
        # Validate required fields
        if not task_id:
            return Response({"success": False, "error": "task is required"}, status=400)
        if not freelancer_id:
            return Response({"success": False, "error": "rated_user is required"}, status=400)
        if not score:
            return Response({"success": False, "error": "score is required (1-5)"}, status=400)
        
        # Convert score
        try:
            score = int(score)
            if score < 1 or score > 5:
                return Response({"success": False, "error": "Score must be between 1 and 5"}, status=400)
        except ValueError:
            return Response({"success": False, "error": "Score must be a valid number"}, status=400)
        
        # Get task
        try:
            task = Task.objects.get(task_id=task_id, employer=employer)
            print(f"Task found: {task.title}, status: {task.status}")
        except Task.DoesNotExist:
            return Response({"success": False, "error": "Task not found or you don't own this task"}, status=404)
        
        # ✅ FIXED: Allow both 'submitted' and 'completed' status
        allowed_statuses = ['submitted', 'completed']
        if task.status not in allowed_statuses:
            return Response({
                "success": False,
                "error": f"Task must be in 'submitted' or 'completed' status. Current status: {task.status}",
                "current_status": task.status
            }, status=400)
        
        # Get freelancer
        try:
            freelancer = User.objects.get(user_id=freelancer_id)
            print(f"Freelancer found: {freelancer.name}")
        except User.DoesNotExist:
            return Response({"success": False, "error": "Freelancer not found"}, status=404)
        
        # Get contract
        try:
            contract = Contract.objects.get(
                task=task,
                freelancer=freelancer,
                is_active=True
            )
            print(f"Contract found: {contract.contract_id}")
        except Contract.DoesNotExist:
            return Response({"success": False, "error": "No active contract found"}, status=400)
        
        # Get submission if exists
        submission = Submission.objects.filter(
            task=task,
            freelancer=freelancer
        ).first()
        
        # Check if rating already exists
        if Rating.objects.filter(
            task=task, 
            rater_employer=employer, 
            rated_user=freelancer
        ).exists():
            return Response({"success": False, "error": "Already rated this freelancer"}, status=400)
        
        # Create rating
        rating = Rating.objects.create(
            task=task,
            contract=contract,
            submission=submission,
            rater_employer=employer,
            rated_user=freelancer,
            score=score,
            review=review,
        )
        
        print(f"Rating created: {rating.rating_id}")
        
        # Update task status to 'completed' if not already
        if task.status != 'completed':
            task.status = 'completed'
            task.save()
            print(f"Task status updated to: {task.status}")
        
        # Update submission status if exists
        if submission and submission.status != 'accepted':
            submission.status = 'accepted'
            submission.save()
            print(f"Submission status updated to: {submission.status}")
        
        # Update contract
        if contract.status != 'completed':
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
        return Response({"success": False, "error": str(e)}, status=500)
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
            
            # Get tasks that are COMPLETED or ready for review
            # Statuses that indicate task is done and ready for rating
            rateable_statuses = ['completed', 'done', 'submitted', 'review']
            
            tasks_query = Task.objects.filter(
                employer=employer,
                assigned_user__isnull=False
            ).select_related('assigned_user')
            
            print(f"Found {tasks_query.count()} tasks with assigned users")
            
            tasks_data = []
            for task in tasks_query:
                print(f"\nProcessing task: {task.task_id} - {task.title}")
                print(f"Status: {task.status}")
                print(f"Assigned user: {task.assigned_user.name} (ID: {task.assigned_user.user_id})")
                
                # Check if task status is appropriate for rating
                if task.status.lower() not in [s.lower() for s in rateable_statuses]:
                    print(f"  ✗ Status '{task.status}' not in rateable statuses: {rateable_statuses}")
                    continue
                
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
                        freelancer=task.assigned_user
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
# Django views.py - Add these endpoints

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def register_bank_account(request):
    """
    POST /api/freelancer/register-bank/
    Required for withdrawals
    """
    try:
        freelancer = request.user.freelancer
        
        bank_code = request.data.get('bank_code')       # e.g., '058' for GTBank
        account_number = request.data.get('account_number')
        account_name = request.data.get('account_name')
        
        # 1. Verify account with Paystack
        paystack = PaystackService()
        
        # First resolve account name
        verify_data = paystack.resolve_account_number(account_number, bank_code)
        
        if not verify_data.get('status'):
            return Response({
                'status': False,
                'message': 'Account verification failed'
            }, status=400)
        
        # 2. Create transfer recipient
        recipient_data = {
            'type': 'nuban',
            'name': verify_data['data']['account_name'],
            'account_number': account_number,
            'bank_code': bank_code,
            'currency': 'KES'
        }
        
        recipient = paystack.create_transfer_recipient(recipient_data)
        
        if recipient.get('status'):
            # Save to freelancer profile
            freelancer_profile = freelancer.profile
            
            freelancer_profile.bank_account_number = account_number
            freelancer_profile.bank_code = bank_code
            freelancer_profile.bank_account_name = verify_data['data']['account_name']
            freelancer_profile.paystack_recipient_code = recipient['data']['recipient_code']
            freelancer_profile.bank_verified = True
            freelancer_profile.save()
            
            return Response({
                'status': True,
                'message': 'Bank account registered successfully',
                'recipient_code': recipient['data']['recipient_code']
            })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def request_withdrawal(request):
    """
    POST /api/freelancer/withdraw/
    """
    try:
        freelancer = request.user.freelancer
        amount = Decimal(request.data.get('amount', 0))
        
        # Check if freelancer has enough balance
        if amount > freelancer.available_balance:
            return Response({
                'status': False,
                'message': f'Insufficient balance. Available: KES {freelancer.available_balance}'
            }, status=400)
        
        # Check if bank account is verified
        if not hasattr(freelancer, 'profile') or not freelancer.profile.paystack_recipient_code:
            return Response({
                'status': False,
                'message': 'Please register your bank account first'
            }, status=400)
        
        # Create withdrawal request
        withdrawal = WithdrawalRequest.objects.create(
            freelancer=freelancer,
            amount=amount,
            status='pending',
            paystack_recipient_code=freelancer.profile.paystack_recipient_code
        )
        
        # Initiate transfer via Paystack
        paystack = PaystackService()
        transfer_response = paystack.initiate_transfer(
            amount=int(amount * 100),  # Convert to kobo
            recipient_code=freelancer.profile.paystack_recipient_code,
            reason=f'Withdrawal for {freelancer.user.get_full_name()}'
        )
        
        if transfer_response.get('status'):
            withdrawal.status = 'processing'
            withdrawal.paystack_transfer_code = transfer_response['data']['transfer_code']
            withdrawal.save()
            
            # Deduct from freelancer's balance (but keep in escrow until transfer succeeds)
            freelancer.pending_withdrawal += amount
            freelancer.save()
            
            return Response({
                'status': True,
                'message': 'Withdrawal request submitted. Funds will be transferred within 24 hours.',
                'transfer_code': transfer_response['data']['transfer_code']
            })
        else:
            withdrawal.status = 'failed'
            withdrawal.save()
            
            return Response({
                'status': False,
                'message': f'Transfer failed: {transfer_response.get("message", "Unknown error")}'
            }, status=400)
            
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)


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
        print(f"🔍 DEBUG: User making request: {request.user}")
        print(f"🔍 DEBUG: User ID: {request.user.user_id}")
        print(f"🔍 DEBUG: User type: {type(request.user)}")
        print(f"🔍 DEBUG: User is freelancer? {hasattr(request.user, 'freelancer_profile')}")
        
        contracts = Contract.objects.filter(freelancer=request.user)
        print(f"🔍 DEBUG: Found {contracts.count()} contracts for this user")
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
    try:
        print(f"\n{'='*60}")
        print("EMPLOYER PENDING COMPLETIONS API CALLED")
        print(f"{'='*60}")
        
        # Show completed but unpaid contracts
        contracts = Contract.objects.filter(
            employer=request.user,
            is_completed=True,
            is_paid=False,
            is_active=True,
            status='completed'
        ).select_related('task', 'freelancer')
        
        print(f"Found {contracts.count()} completed contracts pending payment")
        
        contracts_data = []
        for contract in contracts:
            # Get freelancer data
            freelancer_name = 'Unknown'
            freelancer_email = ''
            freelancer_id = None  # ADD THIS
            
            if contract.freelancer:
                if hasattr(contract.freelancer, 'name') and contract.freelancer.name:
                    freelancer_name = contract.freelancer.name
                elif hasattr(contract.freelancer, 'username') and contract.freelancer.username:
                    freelancer_name = contract.freelancer.username
                
                if hasattr(contract.freelancer, 'email') and contract.freelancer.email:
                    freelancer_email = contract.freelancer.email
                
                # 🚨 ADD THIS: Get freelancer ID
                # Try different possible ID fields
                if hasattr(contract.freelancer, 'id'):
                    freelancer_id = contract.freelancer.id
                elif hasattr(contract.freelancer, 'user_id'):
                    freelancer_id = contract.freelancer.user_id
                elif hasattr(contract.freelancer, 'freelancer_id'):
                    freelancer_id = contract.freelancer.freelancer_id
                
                print(f"Freelancer ID found: {freelancer_id}")
            
            contract_info = {
                'contract_id': contract.contract_id,
                'task_id': contract.task.task_id if contract.task else None,
                'task_title': contract.task.title if contract.task else 'Unknown Task',
                'freelancer_name': freelancer_name,
                'freelancer_email': freelancer_email,
                'freelancer_id': freelancer_id,  # 🚨 ADD THIS LINE
                'amount': float(contract.task.budget) if contract.task and contract.task.budget else 0.0,
                'contract_status': contract.status,
                'is_paid': contract.is_paid,
                'is_completed': contract.is_completed,
                'completed_date': contract.completed_date.strftime('%Y-%m-%d') if contract.completed_date else None,
                'can_pay': True,
                'requires_payment': True,
            }
            
            # DEBUG: Print what's being sent
            print(f"\nSending contract {contract.contract_id}:")
            print(f"  Freelancer Name: {freelancer_name}")
            print(f"  Freelancer ID: {freelancer_id}")
            print(f"  Freelancer Email: {freelancer_email}")
            
            contracts_data.append(contract_info)
        
        return Response({
            'success': True,
            'count': len(contracts_data),
            'contracts': contracts_data,
            'message': 'Found completed contracts ready for payment'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        return Response({'error': str(e)}, status=500)
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def mark_contract_completed(request, contract_id):
    """
    POST /contracts/<contract_id>/mark-completed/
    Employer marks a contract as completed
    """
    try:
        print(f"\n{'='*60}")
        print("MARK CONTRACT COMPLETED API CALLED")
        print(f"{'='*60}")
        print(f"Contract ID: {contract_id}")
        print(f"Employer: {request.user.username}")
        
        # Get the contract
        try:
            contract = Contract.objects.get(
                contract_id=contract_id,
                employer=request.user,
                is_completed=False,  # Not already completed
                is_active=True
            )
        except Contract.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Contract not found or already completed'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Mark as completed
        contract.mark_as_completed()  # Using your model method
        
        print(f"✓ Contract {contract_id} marked as completed")
        
        return Response({
            'success': True,
            'message': f'Contract {contract_id} marked as completed',
            'contract_id': contract.contract_id,
            'task_title': contract.task.title if contract.task else '',
            'status': contract.status,
            'is_completed': contract.is_completed,
            'completed_date': contract.completed_date.strftime('%Y-%m-%d %H:%M:%S') if contract.completed_date else None
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"ERROR in mark_contract_completed: {str(e)}")
        return Response({
            'success': False,
            'error': f'Failed to mark contract as completed: {str(e)}'
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

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_submissions(request):
    """
    GET /api/submissions/employer/
    Returns ALL submissions for the employer to review
    """
    try:
        print(f"\n{'='*60}")
        print("EMPLOYER SUBMISSIONS API CALLED")
        print(f"{'='*60}")
       #print(f"Employer: {request.user.username} (ID: {request.user.id})")  
        
        # Get ALL contracts for this employer (regardless of status)
        all_contracts = Contract.objects.filter(employer=request.user)
        print(f"Found {all_contracts.count()} total contracts")
        
        # Get submissions where contract is completed AND submission is not approved/accepted yet
        submissions = Submission.objects.filter(
            contract__in=all_contracts,
            status__in=['submitted', 'under_review', 'resubmitted']  # Only show pending review
        ).select_related(
            'contract', 
            'freelancer', 
            'task'
        ).order_by('-submitted_at')
        
        print(f"Found {submissions.count()} submissions pending review")
        
        submissions_data = []
        for submission in submissions:
            # Get freelancer details
            freelancer = submission.freelancer
            
            # Get freelancer name
            freelancer_name = 'Unknown'
            if hasattr(freelancer, 'first_name') and freelancer.first_name:
                freelancer_name = f"{freelancer.first_name} {freelancer.last_name or ''}".strip()
                if not freelancer_name:
                    freelancer_name = freelancer.username
            elif hasattr(freelancer, 'username'):
                freelancer_name = freelancer.username
            else:
                freelancer_name = freelancer.email
            
            # Get task details
            task = submission.task
            task_title = task.title if task else 'Task'
            
            submission_data = {
                'submission_id': submission.submission_id,
                'contract_id': submission.contract.contract_id if submission.contract else None,
                'task_id': task.task_id if task else None,
                'task_title': task_title,
                'freelancer_id': freelancer.pk,  # Use .pk
                'freelancer_name': freelancer_name,
                'freelancer_email': freelancer.email,
                'description': submission.description,
                'title': submission.title,
                'status': submission.status,
                'submitted_date': submission.submitted_at.isoformat() if submission.submitted_at else None,
                'repo_url': submission.repo_url,
                'live_demo_url': submission.live_demo_url,
                'staging_url': submission.staging_url,
                'apk_download_url': submission.apk_download_url,
                'testflight_link': submission.testflight_link,
                'admin_username': submission.admin_username,
                'access_instructions': submission.access_instructions,
                'deployment_instructions': submission.deployment_instructions,
                'test_instructions': submission.test_instructions,
                'release_notes': submission.release_notes,
                'revision_notes': submission.revision_notes,
                'checklist_tests_passing': submission.checklist_tests_passing,
                'checklist_deployed_staging': submission.checklist_deployed_staging,
                'checklist_documentation': submission.checklist_documentation,
                'checklist_no_critical_bugs': submission.checklist_no_critical_bugs,
                'contract_status': submission.contract.status if submission.contract else None,
                'task_status': task.status if task else None,
                'can_approve': submission.status in ['submitted', 'under_review', 'resubmitted'],
                'can_request_revision': submission.status in ['submitted', 'under_review', 'resubmitted'],
            }
            
            print(f"\nSubmission {submission.submission_id}:")
            print(f"  Task: {task_title}")
            print(f"  Status: {submission.status}")
            print(f"  Freelancer: {freelancer_name}")
            
            submissions_data.append(submission_data)
        
        return Response({
            'success': True,
            'count': len(submissions_data),
            'submissions': submissions_data,
            'message': f'Found {len(submissions_data)} submissions for review'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"ERROR in employer_submissions: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return Response({
            'success': False,
            'error': f'Failed to fetch submissions: {str(e)}',
            'submissions': []
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

from django.utils import timezone  # ADD THIS IMPORT

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def approve_submission(request, submission_id):
    """
    POST /api/submissions/{submission_id}/approve/
    Approve a submission and mark task as completed
    """
    try:
        print(f"\n{'='*60}")
        print("APPROVE SUBMISSION API CALLED")
        print(f"{'='*60}")
        print(f"Submission ID: {submission_id}")
        print(f"Employer: {request.user.username}")
        
        # Get submission with related objects
        submission = get_object_or_404(
            Submission.objects.select_related('contract', 'task'),
            submission_id=submission_id,
            contract__employer=request.user  # Ensure employer owns the contract
        )
        
        print(f"Found submission: ID={submission.submission_id}, Status={submission.status}")
        print(f"Task: {submission.task.title if submission.task else 'No task'}")
        print(f"Contract: {submission.contract.contract_id if submission.contract else 'No contract'}")
        
        # Check if submission can be approved
        if submission.status not in ['submitted', 'under_review', 'resubmitted']:
            error_msg = f'Cannot approve submission with status: {submission.status}'
            print(f"ERROR: {error_msg}")
            return Response({
                'success': False,
                'error': error_msg
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Update submission status
        old_status = submission.status
        submission.status = 'approved'
        submission.revision_notes = None  # Clear any revision notes
        submission.save()
        
        print(f"✓ Submission status updated: {old_status} -> {submission.status}")
        
        # Update task status to completed
        task = submission.task
        if task:
            old_task_status = task.status
            task.status = 'completed'
            task.completed_at = timezone.now()  # LINE 50 - FIXED
            task.save()
            print(f"✓ Task status updated: {old_task_status} -> {task.status}")
        else:
            print("⚠️ No task associated with submission")
        
        # Update contract status
        contract = submission.contract
        if contract:
            old_contract_status = contract.status
            contract.status = 'completed'
            contract.is_completed = True
            contract.completed_date = timezone.now()  # LINE 59 - FIXED
            contract.save()
            print(f"✓ Contract status updated: {old_contract_status} -> {contract.status}")
        else:
            print("⚠️ No contract associated with submission")
        
        # TODO: Create payment order if needed
        # TODO: Send notification to freelancer
        # TODO: Create rating opportunity
        
        return Response({
            'success': True,
            'message': 'Submission approved successfully',
            'submission_id': submission.submission_id,
            'task_id': task.task_id if task else None,
            'contract_id': contract.contract_id if contract else None,
            'new_submission_status': 'approved',
            'new_task_status': 'completed',
            'new_contract_status': 'completed'
        }, status=status.HTTP_200_OK)
        
    except Submission.DoesNotExist:
        error_msg = f'Submission {submission_id} not found or unauthorized'
        print(f"ERROR: {error_msg}")
        return Response({
            'success': False,
            'error': error_msg
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"ERROR in approve_submission: {str(e)}")
        return Response({
            'success': False,
            'error': f'Failed to approve submission: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def request_revision(request, submission_id):
    """
    POST /api/submissions/{submission_id}/request-revision/
    Request revisions for a submission
    """
    try:
        print(f"\n{'='*60}")
        print("REQUEST REVISION API CALLED")
        print(f"{'='*60}")
        print(f"Submission ID: {submission_id}")
        print(f"Employer: {request.user.username}")
        
        # Get submission with related objects
        submission = get_object_or_404(
            Submission.objects.select_related('contract', 'task'),
            submission_id=submission_id,
            contract__employer=request.user  # Ensure employer owns the contract
        )
        
        print(f"Found submission: ID={submission.submission_id}, Status={submission.status}")
        
        # Check if submission can be revised
        if submission.status not in ['submitted', 'under_review', 'resubmitted']:
            error_msg = f'Cannot request revision for submission with status: {submission.status}'
            print(f"ERROR: {error_msg}")
            return Response({
                'success': False,
                'error': error_msg
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get revision notes from request
        notes = request.data.get('notes', '').strip()
        if not notes:
            error_msg = 'Revision notes are required'
            print(f"ERROR: {error_msg}")
            return Response({
                'success': False,
                'error': error_msg
            }, status=status.HTTP_400_BAD_REQUEST)
        
        print(f"Revision notes length: {len(notes)} characters")
        
        # Update submission status and notes
        old_status = submission.status
        submission.status = 'revisions_requested'
        submission.revision_notes = notes
        submission.save()
        
        print(f"✓ Submission status updated: {old_status} -> {submission.status}")
        print(f"✓ Revision notes saved")
        
        # Update task status back to in_progress so freelancer can resubmit
        task = submission.task
        if task:
            old_task_status = task.status
            task.status = 'in_progress'
            task.save()
            print(f"✓ Task status updated: {old_task_status} -> {task.status}")
        else:
            print("⚠️ No task associated with submission")
        
        # Update contract status if needed
        contract = submission.contract
        if contract and contract.status != 'in_progress':
            old_contract_status = contract.status
            contract.status = 'in_progress'
            contract.save()
            print(f"✓ Contract status updated: {old_contract_status} -> {contract.status}")
        
        # TODO: Send notification to freelancer with revision notes
        
        return Response({
            'success': True,
            'message': 'Revision requested successfully',
            'submission_id': submission.submission_id,
            'task_id': task.task_id if task else None,
            'contract_id': contract.contract_id if contract else None,
            'new_submission_status': 'revisions_requested',
            'new_task_status': 'in_progress',
            'new_contract_status': 'in_progress'
        }, status=status.HTTP_200_OK)
        
    except Submission.DoesNotExist:
        error_msg = f'Submission {submission_id} not found or unauthorized'
        print(f"ERROR: {error_msg}")
        return Response({
            'success': False,
            'error': error_msg
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"ERROR in request_revision: {str(e)}")
        return Response({
            'success': False,
            'error': f'Failed to request revision: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def freelancer_completed_tasks(request):
    """
    GET /api/tasks/freelancer/completed/
    Get completed/approved tasks for the logged-in freelancer
    """
    try:
        print(f"\n{'='*60}")
        print("FREELANCER COMPLETED TASKS API CALLED")
        print(f"{'='*60}")
        print(f"Freelancer: {request.user.username} (ID: {request.user.user_id})")
        
        current_user = request.user
        
        # Get completed tasks where this user is the freelancer via contracts
        completed_tasks = Task.objects.filter(
            Q(status='completed') | Q(completed_at__isnull=False),
            contract__freelancer=current_user,
            contract__is_active=True
        ).select_related('employer').prefetch_related(
            'contract_set'  # Get all contracts for this task
        ).distinct()
        
        print(f"Found {completed_tasks.count()} completed tasks for freelancer")
        
        data = []
        for task in completed_tasks:
            # Get the contract where this freelancer is involved
            freelancer_contract = None
            for contract in task.contract_set.all():
                if contract.freelancer == current_user:
                    freelancer_contract = contract
                    break
            
            # Get approved submission for this task (if exists)
            approved_submission = None
            if freelancer_contract:
                try:
                    approved_submission = Submission.objects.filter(
                        task=task,
                        contract=freelancer_contract,
                        status='approved'
                    ).order_by('-submitted_at').first()
                except Submission.DoesNotExist:
                    approved_submission = None
            
            # Get employer info
            employer_name = "Unknown"
            employer_email = ""
            if task.employer:
                employer_name = task.employer.username or task.employer.name or "Unknown"
                employer_email = task.employer.contact_email or ""
            
            task_data = {
                'task_id': task.task_id,
                'id': task.task_id,
                'title': task.title,
                'description': task.description,
                'status': task.status,
                'completed_at': task.completed_at.isoformat() if task.completed_at else None,
                'budget': str(task.budget) if task.budget else "0.00",
                'deadline': task.deadline.isoformat() if task.deadline else None,
                'employer': {
                    'name': employer_name,
                    'email': employer_email,
                },
                'has_approved_submission': approved_submission is not None,
                'submission_details': {
                    'submission_id': approved_submission.submission_id if approved_submission else None,
                    'submitted_at': approved_submission.submitted_at.isoformat() if approved_submission else None,
                    'approved_at': approved_submission.updated_at.isoformat() if approved_submission and approved_submission.status == 'approved' else None,
                } if approved_submission else None,
                'contract_id': freelancer_contract.contract_id if freelancer_contract else None,
                'is_fully_accepted': freelancer_contract.is_fully_accepted if freelancer_contract else False,
                'payment_status': freelancer_contract.is_paid if freelancer_contract else False,
            }
            data.append(task_data)
            
            print(f"  Task: {task.title} | Status: {task.status} | Completed: {task.completed_at}")
        
        return Response({
            'success': True,
            'count': len(data),
            'completed_tasks': data,
            'freelancer': {
                'id': current_user.user_id,
                'name': current_user.username,
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"ERROR in freelancer_completed_tasks: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'success': False,
            'error': f'Failed to fetch completed tasks: {str(e)}',
            'completed_tasks': []
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def submission_detail(request, submission_id):
    """
    GET /api/submissions/{submission_id}/
    Get detailed information about a specific submission
    """
    try:
        print(f"\n{'='*60}")
        print("SUBMISSION DETAIL API CALLED")
        print(f"{'='*60}")
        print(f"Submission ID: {submission_id}")
        print(f"Employer: {request.user.username}")
        
        # Get submission with all related objects
        submission = get_object_or_404(
            Submission.objects.select_related('contract', 'task', 'freelancer'),
            submission_id=submission_id,
            contract__employer=request.user  # Ensure employer owns the contract
        )
        
        print(f"Found submission: ID={submission.submission_id}")
        
        # Get freelancer details
        freelancer = submission.freelancer
        freelancer_name = 'Unknown'
        if hasattr(freelancer, 'name') and freelancer.name:
            freelancer_name = freelancer.name
        elif hasattr(freelancer, 'username') and freelancer.username:
            freelancer_name = freelancer.username
        elif hasattr(freelancer, 'first_name') and freelancer.first_name:
            freelancer_name = f"{freelancer.first_name} {freelancer.last_name or ''}".strip()
            if not freelancer_name:
                freelancer_name = freelancer.email
        else:
            freelancer_name = freelancer.email
        
        # Get task and contract
        task = submission.task
        contract = submission.contract
        
        # Build detailed response
        submission_data = {
            'submission_id': submission.submission_id,
            'contract_id': contract.contract_id if contract else None,
            'task_id': task.task_id if task else None,
            'task_title': task.title if task else 'Task',
            'task_description': task.description if task else None,
            'freelancer_id': freelancer.id,
            'freelancer_name': freelancer_name,
            'freelancer_email': freelancer.email,
            
            # Submission details
            'title': submission.title,
            'description': submission.description,
            'status': submission.status,
            'submitted_date': submission.submitted_at.isoformat() if submission.submitted_at else None,
            
            # URLs and links
            'repo_url': submission.repo_url,
            'live_demo_url': submission.live_demo_url,
            'staging_url': submission.staging_url,
            'apk_download_url': submission.apk_download_url,
            'testflight_link': submission.testflight_link,
            'commit_hash': submission.commit_hash,
            
            # Access details
            'admin_username': submission.admin_username,
            'access_instructions': submission.access_instructions,
            'deployment_instructions': submission.deployment_instructions,
            'test_instructions': submission.test_instructions,
            'release_notes': submission.release_notes,
            'revision_notes': submission.revision_notes,
            
            # Checklists
            'checklist_tests_passing': submission.checklist_tests_passing,
            'checklist_deployed_staging': submission.checklist_deployed_staging,
            'checklist_documentation': submission.checklist_documentation,
            'checklist_no_critical_bugs': submission.checklist_no_critical_bugs,
            
            # Contract and task status
            'contract_status': contract.status if contract else None,
            'task_status': task.status if task else None,
            'contract_created_date': contract.start_date.isoformat() if contract and contract.start_date else None,
            'task_due_date': task.due_date.isoformat() if task and task.due_date else None,
            
            # Permissions
            'can_approve': submission.status in ['submitted', 'under_review', 'resubmitted'],
            'can_request_revision': submission.status in ['submitted', 'under_review', 'resubmitted'],
        }
        
        # Add file URLs if they exist
        if hasattr(submission, 'zip_file') and submission.zip_file:
            submission_data['zip_file'] = request.build_absolute_uri(submission.zip_file.url)
        
        if hasattr(submission, 'video_demo') and submission.video_demo:
            submission_data['video_demo'] = request.build_absolute_uri(submission.video_demo.url)
        
        # Handle screenshots if they exist as a many-to-many field
        if hasattr(submission, 'screenshots') and submission.screenshots.exists():
            screenshot_urls = []
            for screenshot in submission.screenshots.all():
                if hasattr(screenshot, 'url'):
                    screenshot_urls.append(request.build_absolute_uri(screenshot.url))
            submission_data['screenshots'] = screenshot_urls
        
        print(f"✓ Returning detailed submission data")
        
        return Response({
            'success': True,
            'submission': submission_data,
            'message': 'Submission details fetched successfully'
        }, status=status.HTTP_200_OK)
        
    except Submission.DoesNotExist:
        error_msg = f'Submission {submission_id} not found or unauthorized'
        print(f"ERROR: {error_msg}")
        return Response({
            'success': False,
            'error': error_msg
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"ERROR in submission_detail: {str(e)}")
        return Response({
            'success': False,
            'error': f'Failed to fetch submission details: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)        
import secrets
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def pending_payment_orders(request):
    """
    Get all pending orders for the authenticated employer
    """
    try:
        print(f"\n{'='*60}")
        print("PENDING PAYMENT ORDERS API")
        print(f"{'='*60}")
        print(f"Employer: {request.user.username}")
        
        orders = Order.objects.filter(
            employer=request.user,
            status='pending'
        ).select_related('freelancer', 'freelancer__user', 'task')
        
        print(f"Found {orders.count()} pending orders")
        
        order_list = []
        for order in orders:
            print(f"\n{'='*40}")
            print(f"Processing order: {order.order_id}")
            print(f"Order amount: {order.amount}")
            
            freelancer_data = None
            if order.freelancer:
                print(f"Freelancer exists: Yes")
                print(f"Freelancer object: {order.freelancer}")
                print(f"Freelancer type: {type(order.freelancer)}")
                print(f"Freelancer ID: {order.freelancer.id}")
                print(f"Freelancer has id attr: {hasattr(order.freelancer, 'id')}")
                
                # Try different ways to get ID
                freelancer_id = None
                if hasattr(order.freelancer, 'id'):
                    freelancer_id = order.freelancer.id
                    print(f"Using freelancer.id: {freelancer_id}")
                elif hasattr(order.freelancer, 'pk'):
                    freelancer_id = order.freelancer.pk
                    print(f"Using freelancer.pk: {freelancer_id}")
                elif hasattr(order.freelancer, 'user') and order.freelancer.user:
                    if hasattr(order.freelancer.user, 'id'):
                        freelancer_id = order.freelancer.user.id
                        print(f"Using freelancer.user.id: {freelancer_id}")
                
                freelancer_data = {
                    'freelancer_id': freelancer_id,
                    'freelancer_id_str': str(freelancer_id) if freelancer_id else '',
                    'name': order.freelancer.name,
                    'email': order.freelancer.email,
                }
                print(f"Final freelancer_data: {freelancer_data}")
            else:
                print(f"Freelancer exists: No")
                freelancer_data = None

            order_data = {
                'order_id': str(order.order_id),
                'id': str(order.order_id),
                'amount': float(order.amount),
                'currency': order.currency,
                'status': order.status,
                'created_at': order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'task_title': order.task.title if order.task else None,
                'task_id': order.task.id if order.task else None,
                'freelancer': freelancer_data
            }
            
            print(f"Order data being sent: {order_data}")
            order_list.append(order_data)

        print(f"\nSending {len(order_list)} orders")
        
        return Response({
            'status': True,
            'orders': order_list,
            'count': len(order_list)
        }, status=200)

    except Exception as e:
        import traceback
        print(f"ERROR in pending_payment_orders: {str(e)}")
        print(f"Traceback: {traceback.format_exc()}")
        return Response({'status': False, 'message': str(e)}, status=500)
    
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
        
        # ✅ request.user is ALREADY an Employer instance!
        employer = request.user
        print(f"✅ Employer: {employer.username}")
        print(f"   Contact Email: {employer.contact_email}")
        print(f"   Employer ID: {employer.employer_id}")
        
        # ✅ Now query the order with the employer instance
        print(f"🔍 Looking for order {order_id} with employer {employer.username}")
        
        # Debug: Check all orders first
        all_orders = Order.objects.all()
        print(f"Total orders in DB: {all_orders.count()}")
        for o in all_orders:
            employer_name = o.employer.username if o.employer else 'None'
            print(f"  - {o.order_id} | Employer: {employer_name} | Status: {o.status}")
        
        # Get the specific order
        try:
            order = Order.objects.get(order_id=order_id, employer=employer)
            print(f"✅ Found order: {order.order_id}")
            print(f"   Amount: {order.amount} {order.currency}")
            print(f"   Status: {order.status}")
            print(f"   Task: {order.task.title if order.task else 'No task'}")
            print(f"   Freelancer: {order.freelancer.name if order.freelancer else 'None'}")
            
        except Order.DoesNotExist:
            print(f"❌ Order {order_id} not found OR not owned by employer {employer.username}")
            
            # Check if order exists at all
            order_exists = Order.objects.filter(order_id=order_id).exists()
            if order_exists:
                wrong_order = Order.objects.get(order_id=order_id)
                wrong_employer = wrong_order.employer.username if wrong_order.employer else 'None'
                print(f"   Order exists but belongs to: {wrong_employer}")
                return Response({
                    'status': False,
                    'message': 'Order found but you are not authorized to pay for it.'
                }, status=403)
            else:
                print(f"   Order {order_id} does not exist in database")
                return Response({
                    'status': False,
                    'message': f'Order {order_id} not found in database.'
                }, status=404)
        
        # Generate email if empty
        if not email:
            email = f"{employer.username.replace(' ', '.').lower()}@helawork.pay"
            print(f"✅ Generated email: {email}")
        
        # Calculate amount in CENTS (not kobo!)
        amount_ksh = float(order.amount)
        amount_cents = int(amount_ksh * 100)  # Convert KSH to cents
        print(f"💰 Amount: {amount_ksh} KSH = {amount_cents} cents")
        
        # Generate reference
        import secrets
        reference = f"HW_{order_id}_{secrets.token_hex(5)}"
        print(f"✅ Reference: {reference}")
        
        # Initialize Paystack payment
        paystack_service = PaystackService()
        
        print(f"🔄 Initializing Paystack transaction...")
        response = paystack_service.initialize_transaction(
            email=email,
            amount_cents=amount_cents,  # Pass in CENTS
            reference=reference,
            callback_url=f"{settings.FRONTEND_URL}/payment/callback?reference={reference}",
            currency="KES"
        )
        
        print(f"💰 Paystack response status: {response.get('status') if response else 'No response'}")
        print(f"💰 Paystack message: {response.get('message') if response else 'No message'}")
        
        if response and response.get('status'):
            # Create transaction record
            try:
                # PaymentTransaction doesn't have employer field, so don't include it
                transaction = PaymentTransaction.objects.create(
                    order=order,
                    paystack_reference=reference,
                    amount=order.amount,
                    platform_commission=Decimal('0.00'),
                    freelancer_share=order.amount,
                    status='pending',
                )
                print(f"✅ PaymentTransaction created: {transaction.id}")
                print(f"   Reference: {transaction.paystack_reference}")
                
            except Exception as e:
                print(f"⚠️ Could not create PaymentTransaction: {e}")
                import traceback
                traceback.print_exc()
            
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
                    'currency': 'KES',
                    'employer': employer.username
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
def get_order_for_contract(request, contract_id):
    """Get or create order for a contract"""
    try:
        print(f"🔍 DEBUG: Starting get_order_for_contract for contract_id: {contract_id}")
        
        # Get contract
        contract = get_object_or_404(Contract, contract_id=contract_id, employer=request.user)
        print(f"✅ Contract found: {contract}")
        
        # DEBUG: Check what type contract.freelancer is
        print(f"🔍 contract.freelancer type: {type(contract.freelancer)}")
        print(f"🔍 contract.freelancer: {contract.freelancer}")
        
        # DEBUG: Check if 'name' is an attribute or method
        print(f"🔍 Has 'name' attribute? {hasattr(contract.freelancer, 'name')}")
        print(f"🔍 Is 'name' callable? {callable(getattr(contract.freelancer, 'name', None))}")
        
        # Try to get the name safely
        freelancer_name = ""
        if hasattr(contract.freelancer, 'name'):
            if callable(contract.freelancer.name):
                # It's a method/property, call it
                freelancer_name = contract.freelancer.name()
            else:
                # It's an attribute
                freelancer_name = contract.freelancer.name
        elif hasattr(contract.freelancer, 'username'):
            freelancer_name = contract.freelancer.username
        elif hasattr(contract.freelancer, 'get_full_name'):
            freelancer_name = contract.freelancer.get_full_name()
        else:
            freelancer_name = "Freelancer"
        
        print(f"✅ Freelancer name determined: {freelancer_name}")
        
        # Check for existing order
        existing_order = Order.objects.filter(
            task=contract.task,
            employer=contract.employer,
            freelancer__user=contract.freelancer
        ).first()
        
        if existing_order:
            print(f"✅ Existing order found: {existing_order.order_id}")
            return Response({
                'status': True,
                'order': {
                    'order_id': str(existing_order.order_id),
                    'amount': float(existing_order.amount),
                    'currency': existing_order.currency,
                    'status': existing_order.status,
                    'freelancer_name': freelancer_name,  # Use the safely determined name
                    'task_title': contract.task.title,
                }
            })
        
        print(f"⚠ No existing order, creating new one...")
        
        # Create new order if none exists
        from decimal import Decimal
        import uuid
        
        # Get freelancer instance
        freelancer = Freelancer.objects.filter(user=contract.freelancer).first()
        
        if not freelancer:
            return Response({
                'status': False,
                'message': 'Freelancer profile not found'
            }, status=400)
        
        # Create order
        order = Order.objects.create(
            order_id=uuid.uuid4(),
            employer=contract.employer,
            task=contract.task,
            freelancer=freelancer,
            amount=Decimal(str(contract.task.budget or 0)),
            currency='KSH',
            status='pending'
        )
        
        print(f"✅ New order created: {order.order_id}")
        
        return Response({
            'status': True,
            'order': {
                'order_id': str(order.order_id),
                'amount': float(order.amount),
                'currency': order.currency,
                'status': order.status,
                'freelancer_name': freelancer_name,  # Use the safely determined name
                'task_title': contract.task.title,
            }
        })
        
    except Exception as e:
        print(f"❌ Error getting order for contract: {e}")
        import traceback
        traceback.print_exc()  # This will show the exact line causing the error
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)

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
 # Django wallet API views
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_wallet_data(request):
  
    try:
        freelancer = request.user.freelancer
        
        # Calculate balance
        completed_payments = Transaction.objects.filter(
            freelancer=freelancer,
            status='completed',
            transaction_type='payment'
        ).aggregate(
            total_earned=sum('freelancer_share')
        )
        
        pending_withdrawals = WithdrawalRequest.objects.filter(
            freelancer=freelancer,
            status__in=['pending', 'processing']
        ).aggregate(
            total_pending=sum('amount')
        )
        
        total_earned = completed_payments['total_earned'] or Decimal('0.00')
        pending_total = pending_withdrawals['total_pending'] or Decimal('0.00')
        available_balance = total_earned - pending_total
        
        # Get bank info
        bank_verified = False
        bank_name = None
        account_last_4 = None
        recipient_code = None
        
        if hasattr(freelancer, 'profile'):
            profile = freelancer.profile
            bank_verified = profile.bank_verified
            if bank_verified:
                bank_name = profile.bank_name
                account_last_4 = profile.bank_account_number[-4:] if profile.bank_account_number else None
                recipient_code = profile.paystack_recipient_code
        
        return Response({
            'status': True,
            'data': {
                'balance': float(available_balance),
                'total_earned': float(total_earned),
                'pending_withdrawals': float(pending_total),
                'bank_verified': bank_verified,
                'bank_name': bank_name,
                'account_last_4': account_last_4,
                'paystack_recipient_code': recipient_code,
                'currency': 'KES',
            }
        })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)
import traceback
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def register_bank(request):
    try:
        user = request.user
        print("=== BANK REGISTRATION STARTED ===")
        print(f"User: {user.name} (ID: {user.user_id})")
        
        if not hasattr(user, 'freelancer_profile'):
            print("ERROR: User has no freelancer_profile")
            return Response({
                'status': False,
                'message': 'User does not have a freelancer profile.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        freelancer = user.freelancer_profile
        print(f"Freelancer found: {freelancer.name}")
        
        account_number = request.data.get('account_number', '').strip()
        internal_bank_code = request.data.get('bank_code', '').strip()
        account_name = request.data.get('account_name', '').strip()
        
        print(f"Request data - Account: {account_number}, Bank Code: {internal_bank_code}, Name: {account_name}")
        
        if not account_number or not internal_bank_code or not account_name:
            print("ERROR: Missing required fields")
            return Response({
                'status': False,
                'message': 'All fields are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if len(account_number) < 10:
            print("ERROR: Account number too short")
            return Response({
                'status': False,
                'message': 'Account number must be at least 10 digits'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        internal_bank_name = get_bank_name(internal_bank_code)
        
        if internal_bank_name == 'Unknown Bank':
            print(f"ERROR: Invalid internal bank code: {internal_bank_code}")
            return Response({
                'status': False,
                'message': f'Invalid bank code: {internal_bank_code}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        print("=== BANK MAPPING PHASE ===")
        print(f"Internal Bank: '{internal_bank_name}' (Code: {internal_bank_code})")
        
        PAYSTACK_BANK_CODE_MAPPING = {
            'Equity Bank Kenya Ltd': '68',
            'Kenya Commercial Bank (Kenya) Ltd': '01',
            'Standard Chartered Bank Kenya': '02',
            'Absa Bank Kenya Plc': '03',
            'Co-operative Bank of Kenya Ltd': '11',
            'National Bank of Kenya Ltd': '12',
            'NCBA Bank Kenya': '07',
            'Diamond Trust Bank Kenya Ltd': '63',
        }
        
        if internal_bank_name not in PAYSTACK_BANK_CODE_MAPPING:
            print(f"ERROR: No Paystack mapping for bank: {internal_bank_name}")
            supported_banks = list(PAYSTACK_BANK_CODE_MAPPING.keys())
            return Response({
                'status': False,
                'message': f"Bank '{internal_bank_name}' is not currently supported.",
                'supported_banks': supported_banks
            }, status=status.HTTP_400_BAD_REQUEST)
        
        paystack_bank_code = PAYSTACK_BANK_CODE_MAPPING[internal_bank_name]
        
        print(f"SUCCESS: Mapped '{internal_bank_name}' to Paystack code: {paystack_bank_code}")
        
        print("=== VERIFYING ACCOUNT WITH PAYSTACK ===")
        paystack = PaystackService()
        
        verify_response = paystack.resolve_account_number(account_number, paystack_bank_code)
        
        print(f"Paystack verification response status: {verify_response.get('status') if verify_response else 'No response'}")
        
        if not verify_response or not verify_response.get('status'):
            error_msg = verify_response.get('message', 'Verification failed') if verify_response else 'No response from Paystack'
            print(f"Paystack verification failed: {error_msg}")
            return Response({
                'status': False,
                'message': f'Bank verification failed: {error_msg}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        verified_data = verify_response.get('data', {})
        verified_account_name = verified_data.get('account_name', '').strip()
        verified_account_number = verified_data.get('account_number', '').strip()
        
        if not verified_account_name:
            print("ERROR: No account name returned from Paystack")
            return Response({
                'status': False,
                'message': 'Could not verify account name from bank'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if verified_account_name.lower() != account_name.lower():
            print(f"Account name mismatch: Expected '{account_name}', Got '{verified_account_name}'")
            return Response({
                'status': False,
                'message': f'Account name does not match. Bank records show: {verified_account_name}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        print("=== CREATING TRANSFER RECIPIENT ===")
        recipient_data = {
            'type': 'kepss',
            'name': verified_account_name,
            'account_number': verified_account_number,
            'bank_code': paystack_bank_code,
            'currency': 'KES'
        }
        
        recipient_response = paystack.create_transfer_recipient(recipient_data)
        
        if not recipient_response or not recipient_response.get('status'):
            error_msg = recipient_response.get('message', 'Failed to create recipient') if recipient_response else 'No response'
            print(f"Failed to create transfer recipient: {error_msg}")
            return Response({
                'status': False,
                'message': f'Paystack setup failed: {error_msg}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        recipient_data = recipient_response.get('data', {})
        recipient_code = recipient_data.get('recipient_code')
        
        print("=== SAVING TO FREELANCER PROFILE ===")
        
        freelancer.bank_name = internal_bank_name
        freelancer.bank_code = internal_bank_code
        freelancer.account_number = verified_account_number
        freelancer.account_name = verified_account_name
        freelancer.business_name = verified_account_name
        
        if recipient_code:
            freelancer.paystack_subaccount_code = recipient_code
            freelancer.is_paystack_setup = True
            freelancer.paystack_setup_date = timezone.now()
            print(f"Saved Paystack recipient code: {recipient_code}")
        
        freelancer.save()
        
        print("BANK REGISTRATION COMPLETE")
        print(f"  Bank: {internal_bank_name}")
        print(f"  Account: {verified_account_number[-4:]}****")
        print(f"  Name: {verified_account_name}")
        
        return Response({
            'status': True,
            'message': 'Bank account verified and registered successfully',
            'data': {
                'bank_name': internal_bank_name,
                'account_number_masked': f"{verified_account_number[-4:]}****",
                'account_name': verified_account_name,
                'recipient_code': recipient_code,
                'is_verified': True,
                'verified_at': timezone.now().isoformat(),
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"UNEXPECTED ERROR in register_bank: {str(e)}")
        traceback.print_exc()
        
        return Response({
            'status': False,
            'message': f'Server error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_wallet_balance(request):
    """
    GET /api/wallet/balance/
    Returns only the balance (for backward compatibility)
    """
    try:
        freelancer = request.user.freelancer
        
        # Calculate available balance
        completed_payments = Transaction.objects.filter(
            freelancer=freelancer,
            status='completed',
            transaction_type='payment'
        ).aggregate(
            total_earned=sum('freelancer_share')
        )
        
        pending_withdrawals = WithdrawalRequest.objects.filter(
            freelancer=freelancer,
            status__in=['pending', 'processing']
        ).aggregate(
            total_pending=sum('amount')
        )
        
        total_earned = completed_payments['total_earned'] or Decimal('0.00')
        pending_total = pending_withdrawals['total_pending'] or Decimal('0.00')
        available_balance = total_earned - pending_total
        
        return Response({
            'status': True,
            'balance': float(available_balance),
            'currency': 'KES'
        })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def withdraw_funds(request):
    """
    POST /api/wallet/withdraw/
    Freelancer withdraws funds
    """
    try:
        freelancer = request.user.freelancer
        
        # Get amount from request
        amount = Decimal(str(request.data.get('amount', 0)))
        
        if amount <= 0:
            return Response({
                'status': False,
                'message': 'Amount must be greater than 0'
            }, status=400)
        
        # Check if freelancer has bank account
        if not hasattr(freelancer, 'profile') or not freelancer.profile.bank_verified:
            return Response({
                'status': False,
                'message': 'Please register your bank account first'
            }, status=400)
        
        # Calculate available balance
        completed_payments = Transaction.objects.filter(
            freelancer=freelancer,
            status='completed',
            transaction_type='payment'
        ).aggregate(
            total_earned=settings('freelancer_share')
        )
        
        pending_withdrawals = WithdrawalRequest.objects.filter(
            freelancer=freelancer,
            status__in=['pending', 'processing']
        ).aggregate(
            total_pending=sum('amount')
        )
        
        total_earned = completed_payments['total_earned'] or Decimal('0.00')
        pending_total = pending_withdrawals['total_pending'] or Decimal('0.00')
        available_balance = total_earned - pending_total
        
        # Check if enough balance
        if amount > available_balance:
            return Response({
                'status': False,
                'message': f'Insufficient balance. Available: KES {available_balance:.2f}'
            }, status=400)
        
        # Create withdrawal request
        withdrawal = WithdrawalRequest.objects.create(
            freelancer=freelancer,
            amount=amount,
            bank_name=freelancer.profile.bank_name,
            account_number=freelancer.profile.bank_account_number,
            account_name=freelancer.profile.bank_account_name,
            paystack_recipient_code=freelancer.profile.paystack_recipient_code,
            status='pending'
        )
        
        # TODO: Initiate Paystack transfer here
        # You would call Paystack's transfer API
        # For now, we'll just mark it as processing
        
        # Update status to processing (simulate)
        withdrawal.status = 'processing'
        withdrawal.save()
        
        # Create transaction record
        Transaction.objects.create(
            transaction_type='withdrawal',
            freelancer=freelancer,
            amount=amount,
            status='processing',
            metadata={
                'withdrawal_id': withdrawal.request_id,
                'bank_name': freelancer.profile.bank_name,
                'account_last_4': freelancer.profile.bank_account_number[-4:] if freelancer.profile.bank_account_number else None
            }
        )
        
        return Response({
            'status': True,
            'message': 'Withdrawal request submitted successfully',
            'data': {
                'withdrawal_id': withdrawal.request_id,
                'amount': float(amount),
                'status': 'processing',
                'estimated_completion': '24-48 hours'
            }
        })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def top_up_wallet(request):
    """
    POST /api/wallet/topup/
    Top up wallet balance
    """
    try:
        freelancer = request.user.freelancer
        
        # Get amount from request
        amount = Decimal(str(request.data.get('amount', 0)))
        
        if amount <= 0:
            return Response({
                'status': False,
                'message': 'Amount must be greater than 0'
            }, status=400)
        
        # Generate payment reference
        import secrets
        reference = f"TOPUP_{freelancer.user_id}_{secrets.token_hex(8).upper()}"
        
        # Initialize payment with Paystack
        from .paystack_service import PaystackService
        
        paystack_service = PaystackService()
        
        # Use freelancer's email or generate one
        email = freelancer.user.email or f"freelancer{freelancer.user_id}@helawork.com"
        
        # ✅ CORRECTED: Use your local IP for callback
        callback_url = f"http://192.168.100.188:8000/api/payment/verify/{reference}/"
        
        print(f"💰 Top-up payment request:")
        print(f"  Email: {email}")
        print(f"  Amount: {amount} KES ({int(amount * 100)} cents)")
        print(f"  Reference: {reference}")
        print(f"  Callback URL: {callback_url}")
        
        # Initialize regular transaction (not split)
        response = paystack_service.initialize_transaction(
            email=email,
            amount_cents=int(amount * 100),  # Convert to cents
            reference=reference,
            callback_url=callback_url,  # Use the corrected URL
            currency="KES"
        )
        
        print(f"💰 Paystack response: {response}")
        
        if not response or not response.get('status'):
            error_msg = response.get('message', 'Failed to initialize payment') if response else 'No response from Paystack'
            return Response({
                'status': False,
                'message': f'Payment initialization failed: {error_msg}'
            }, status=400)
        
        # Create pending transaction record
        Transaction.objects.create(
            transaction_type='topup',
            freelancer=freelancer,
            amount=amount,
            status='pending',
            paystack_reference=reference,
            metadata={
                'purpose': 'wallet_topup',
                'authorization_url': response['data']['authorization_url'],
                'access_code': response['data']['access_code'],
                'callback_url': callback_url,
                'email': email,
                'created_at': timezone.now().isoformat()
            }
        )
        
        return Response({
            'status': True,
            'message': 'Payment initialized successfully',
            'data': {
                'payment_link': response['data']['authorization_url'],
                'reference': reference,
                'amount': float(amount),
                'currency': 'KES',
                'email': email,
                'callback_url': callback_url
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
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_wallet_transactions(request):
    """
    GET /api/wallet/transactions/
    Get transaction history
    """
    try:
        freelancer = request.user.freelancer
        
        # Get pagination parameters
        page = int(request.GET.get('page', 1))
        limit = int(request.GET.get('limit', 20))
        offset = (page - 1) * limit
        
        # Get transactions
        transactions = Transaction.objects.filter(
            freelancer=freelancer
        ).order_by('-created_at')[offset:offset + limit]
        
        # Format response
        transactions_data = []
        for transaction in transactions:
            transactions_data.append({
                'transaction_id': transaction.transaction_id,
                'type': transaction.transaction_type,
                'amount': float(transaction.amount),
                'status': transaction.status,
                'created_at': transaction.created_at.isoformat() if transaction.created_at else None,
                'completed_at': transaction.completed_at.isoformat() if transaction.completed_at else None,
                'reference': transaction.paystack_reference,
                'metadata': transaction.metadata,
            })
        
        # Get total count for pagination
        total_count = Transaction.objects.filter(freelancer=freelancer).count()
        
        return Response({
            'status': True,
            'data': {
                'transactions': transactions_data,
                'pagination': {
                    'page': page,
                    'limit': limit,
                    'total': total_count,
                    'has_next': offset + limit < total_count,
                    'has_prev': page > 1
                }
            }
        })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)

@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_withdrawal_history(request):
    """
    GET /api/wallet/withdrawals/
    Get withdrawal history
    """
    try:
        freelancer = request.user.freelancer
        
        withdrawals = WithdrawalRequest.objects.filter(
            freelancer=freelancer
        ).order_by('-requested_at')
        
        withdrawals_data = []
        for withdrawal in withdrawals:
            withdrawals_data.append({
                'withdrawal_id': withdrawal.request_id,
                'amount': float(withdrawal.amount),
                'status': withdrawal.status,
                'bank_name': withdrawal.bank_name,
                'account_last_4': withdrawal.account_number[-4:] if withdrawal.account_number else None,
                'requested_at': withdrawal.requested_at.isoformat() if withdrawal.requested_at else None,
                'processed_at': withdrawal.processed_at.isoformat() if withdrawal.processed_at else None,
                'completed_at': withdrawal.completed_at.isoformat() if withdrawal.completed_at else None,
                'failure_reason': withdrawal.failure_reason,
            })
        
        return Response({
            'status': True,
            'data': withdrawals_data
        })
        
    except Exception as e:
        return Response({
            'status': False,
            'message': str(e)
        }, status=500)         