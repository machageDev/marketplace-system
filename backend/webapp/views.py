from decimal import Decimal
import hashlib
import hmac
from itertools import count
import secrets
import string
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
from webapp.matcher import SimpleJobMatcher, rank_jobs_for_freelancer
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
from django.db import transaction as django_transaction
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
    # Fix: Use username if name doesn't exist
    print(f"=== Submission by {getattr(request.user, 'username', 'Unknown')} ===")
    
    data = request.data.copy()
    
    if 'task_id' in data:
        data['task'] = data.get('task_id')

    # CRITICAL FIX: Pass the request context here!
    serializer = ProposalSerializer(data=data, context={'request': request})
    
    if serializer.is_valid():
        existing = Proposal.objects.filter(task_id=data['task'], freelancer=request.user).exists()
        if existing:
            return Response({"error": "You have already applied for this task"}, status=400)

        # Fix: Just call save(). The freelancer is handled inside serializer.create()
        proposal = serializer.save()
        
        return Response({
            "success": True,
            "message": "Proposal submitted successfully",
            "proposal": ProposalSerializer(proposal).data
        }, status=status.HTTP_201_CREATED)
    
    return Response({
        "success": False,
        "errors": serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)
from django.db.models import Avg, Prefetch, Sum
        
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
                'category': task.category,
                'is_approved': task.is_approved,
                'status': task.status,
                'overall_status': 'taken' if has_active_contract else task.status,
                'has_contract': has_active_contract,
                'is_taken': has_active_contract,
                'assigned_user': task.assigned_user.user_id if task.assigned_user else None,
                'assigned_freelancer': assigned_freelancer,
                'contract_count': 1 if has_active_contract else 0,
                'created_at': task.created_at.isoformat() if task.created_at else None,
                'completed': False,
                
                # HYBRID / MISSING FIELDS FIXED
                'service_type': task.service_type,
                'location_address': task.location_address,
                'latitude': task.latitude,
                'longitude': task.longitude,
                'payment_type': task.payment_type,
                'budget': str(task.budget) if task.budget else '0.00',
                'is_urgent': task.is_urgent,
                'deadline': task.deadline.isoformat() if task.deadline else None,
                'required_skills': task.required_skills,

                'employer': {
                    'id': task.employer.employer_id,
                    'username': task.employer.username,
                    'contact_email': task.employer.contact_email,
                    'profile_picture': employer_profile.profile_picture.url if employer_profile and employer_profile.profile_picture else None,
                    'phone_number': employer_profile.phone_number if employer_profile else None,
                    'company_name': getattr(employer_profile, 'company_name', task.employer.username) if employer_profile else task.employer.username,
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



@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_task(request):
    try:
        employer = request.user  # Employer instance from EmployerTokenAuthentication

        task_data = request.data.copy()

        # Accept 'skills' as an alias for required_skills
        if 'skills' in task_data and 'required_skills' not in task_data:
            task_data['required_skills'] = task_data.pop('skills')

        serializer = TaskCreateSerializer(data=task_data)
        if serializer.is_valid():
            task = serializer.save(employer=employer)
            return Response({
                'success': True,
                'message': 'Task created successfully',
                'task': TaskSerializer(task).data
            }, status=status.HTTP_201_CREATED)
        else:
            # Helpful debug logging for why validation failed
            print("Task Create Validation Errors:", serializer.errors)
            return Response({
                'success': False,
                'message': 'Validation Error',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

    except Employer.DoesNotExist:
        return Response({'success': False, 'message': 'Employer profile not found'}, status=400)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({'success': False, 'message': str(e)}, status=500)
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication,CustomTokenAuthentication])
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

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def approve_and_release_payout(request, task_id):
    """
    Called by Employer for REMOTE tasks to release escrowed funds.
    """
    try:
        # 1. Fetch task and verify ownership
        task = get_object_or_404(Task, task_id=task_id, employer=request.user)
        
        if task.service_type != 'remote':
            return Response({"error": "Use OTP verification for on-site tasks."}, status=400)
            
        if task.status == 'completed':
            return Response({"error": "Payment already released."}, status=400)

        # 2. Check if payment was actually escrowed
        if not task.is_paid: # Based on our webhook update
            return Response({"error": "No funds found in escrow for this task."}, status=400)

        # 3. Trigger Paystack Payout
        paystack = PaystackService()
        
        # Calculate Payout (e.g., Budget minus 10% platform fee)
        total_cents = int(task.budget * 100)
        freelancer_share = int(total_cents * 0.90) 
        
        # Get Freelancer's Recipient Code
        # Assuming you've stored this on the UserProfile after bank verification
        freelancer_profile = UserProfile.objects.get(user=task.assigned_user)
        recipient_code = freelancer_profile.paystack_recipient_code

        if not recipient_code:
            return Response({"error": "Freelancer has not set up bank details."}, status=400)

        # 4. Execute Transfer
        payout = paystack.transfer_to_subaccount(
            amount_cents=freelancer_share,
            recipient=recipient_code,
            reason=f"Payout for Remote Task: {task.title}"
        )

        if payout.get('status'):
            # 5. Finalize the Task and Contract
            task.status = 'completed'
            task.save()
            
            Contract.objects.filter(task=task).update(is_active=False)
            
            # Notify Freelancer
            Notification.objects.create(
                user=task.assigned_user,
                title="Payment Received!",
                message=f"Employer approved your work for '{task.title}'. Funds sent to your bank."
            )

            return Response({"success": True, "message": "Funds released to freelancer."}, status=200)
        
        return Response({"error": "Payout failed", "detail": payout}, status=500)

    except Exception as e:
        return Response({"error": str(e)}, status=500)
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_dashboard_api(request):
    print("=== Employer Dashboard API Called ===")
    
    try:
        employer = request.user  

        if employer is None:
            return Response({
                'success': False,
                'error': 'User is not associated with any employer account.'
            }, status=status.HTTP_403_FORBIDDEN)

        # 1. STATISTICS 
        all_tasks = Task.objects.filter(employer=employer)
        total_tasks = all_tasks.count()
        pending_proposals = Proposal.objects.filter(task__employer=employer, status='pending').count()
        ongoing_tasks = all_tasks.filter(status='in_progress').count()
        completed_tasks = all_tasks.filter(status='completed').count()
        
        # Calculate Total Spent (Sum of budget of completed tasks)
        total_spent_val = all_tasks.filter(status='completed').aggregate(Sum('budget'))['budget__sum'] or 0
        total_spent = str(total_spent_val)

        # 2. RECENT TASKS 
        recent_tasks = all_tasks.order_by('-created_at')[:5]
        recent_proposals = Proposal.objects.filter(
            task__employer=employer
        ).select_related('freelancer', 'task').order_by('-submitted_at')[:5]

        # 3. SERIALIZE DATA 
        tasks_data = [
            {
                'task_id': t.task_id,
                'title': t.title,
                'status': t.status,
                'created_at': t.created_at,
                'budget': str(t.budget) if t.budget else "0.00",
            }
            for t in recent_tasks
        ]

        proposals_data = []
        for p in recent_proposals:
            # FIX: Attempting to find the correct field name dynamically to prevent crash
            # Usually named 'bid', 'amount', or 'proposed_price'
            bid_val = getattr(p, 'bid_amount', 
                      getattr(p, 'bid', 
                      getattr(p, 'amount', "0.00")))

            proposals_data.append({
                'proposal_id': p.proposal_id,
                'freelancer_name': getattr(p.freelancer, 'username', 'Unknown'),
                'task_title': getattr(p.task, 'title', 'Unknown'),
                'bid_amount': str(bid_val),
                'status': p.status,
                'submitted_at': p.submitted_at,
            })

        # 4. RESPONSE 
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
                    'employer_id': getattr(employer, 'employer_id', None),
                    'username': employer.username,
                    'email': getattr(employer, 'contact_email', employer.contact_email),
                }
            }
        }

        return Response(response_data, status=status.HTTP_200_OK)

    except Exception as e:
        print(f"Dashboard API error: {e}")
        return Response({
            'success': False,
            'error': str(e),
            'data': {
                'statistics': {
                    'total_tasks': 0,
                    'pending_proposals': 0,
                    'ongoing_tasks': 0,
                    'completed_tasks': 0,
                    'total_spent': "0.00",
                },
                'recent_tasks': [],
                'recent_proposals': [],
                'employer_info': {},
            }
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def delete_task(request, task_id):
    try:
        # 1. Get task and ensure it belongs to this employer
        # We filter by both task_id and employer to ensure security
        task = Task.objects.get(task_id=task_id, employer=request.user)
        
        task_title = task.title
        task.delete()
        
        return Response({
            'success': True,
            'message': f'Task "{task_title}" deleted'
        }, status=status.HTTP_200_OK)

    except Task.DoesNotExist:
        return Response({
            'success': False, 
            'message': 'Task not found or you do not have permission'
        }, status=status.HTTP_404_NOT_FOUND)
        
    except Exception as e:
        return Response({
            'success': False, 
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_employer_tasks(request):
    print("\n=== Employer Tasks API Called ===")
    print(f"User: {request.user.username}")
    print(f"Request path: {request.get_full_path()}")

    try:
        employer = request.user
        tasks = Task.objects.filter(employer=employer).order_by('-created_at')

        # Print raw DB values per Task
        print(f"\n=== RAW TASK DATA FROM DATABASE ===")
        for task in tasks:
            print(f"Task {task.task_id}: '{task.title}'")
            print(f"  service_type (model): '{task.service_type}'")
            print(f"  location_address (model): '{task.location_address}'")

        # Serialize and print serializer output for debugging
        serializer = TaskSerializer(tasks, many=True)
        serialized = serializer.data

        # Print the full serialized payload (pretty)
        try:
            pretty = json.dumps(serialized, indent=2, ensure_ascii=False)
        except Exception:
            pretty = str(serialized)
        print(f"\n=== SERIALIZED TASKS (what the API will return) ===\n{pretty}")

        # Print each serialized task's important fields explicitly for quick comparison
        print(f"\n=== SERIALIZED TASKS SUMMARY ===")
        for i, t in enumerate(serialized):
            st = t.get('service_type')
            la = t.get('location_address')
            tid = t.get('task_id') or t.get('id') or f'index_{i}'
            title = t.get('title', '')
            print(f"Serialized Task {tid}: '{title}'")
            print(f"  service_type (serialized): '{st}'")
            print(f"  location_address (serialized): '{la}'")

        return Response({
            "success": True,
            "tasks": serialized,
            "count": len(serialized),
        }, status=status.HTTP_200_OK)

    except Exception as e:
        print(f"Error in get_employer_tasks: {str(e)}")
        return Response({
            "success": False,
            "error": str(e)
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
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_employer_profile(request):
    try:
        employer = request.user 
        profile = EmployerProfile.objects.filter(employer=employer).first()
        
        if not profile:
            return Response({
                'exists': False,
                'full_name': employer.username,
                'is_profile_complete': False
            }, status=200)

        # The crash is likely happening HERE
        try:
            serializer = EmployerProfileSerializer(profile)
            return Response(serializer.data, status=200)
        except Exception as ser_error:
            print(f"SERIALIZER CRASH: {str(ser_error)}")
            return Response({'error': f'Data Error: {str(ser_error)}'}, status=500)

    except Exception as e:
        return Response({'error': str(e)}, status=500)

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
    """
    Verify payment with Paystack and update all related records atomically.
    CRITICAL: Do not remove Paystack Split Payment logic or subaccount parameters.
    """
    try:
        # 1. Verify with Paystack API
        paystack = PaystackService()
        verification = paystack.verify_transaction(reference)
        
        if not verification or not verification.get('status'):
            return Response({
                'status': False,
                'message': 'Paystack verification failed',
                'data': {
                    'payment_status': 'failed',
                    'reference': reference
                }
            }, status=status.HTTP_400_BAD_REQUEST)
        
        transaction_data = verification['data']
        
        # 2. Use atomic transaction to ensure all updates succeed or fail together
        with transaction.atomic():
            try:
                # Lock the transaction row to prevent double-processing
                txn = Transaction.objects.select_for_update().get(paystack_reference=reference)
            except Transaction.DoesNotExist:
                return Response({
                    'status': False,
                    'message': 'Transaction not found'
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Check if already processed
            if txn.status == 'completed':
                return Response({
                    'status': True,
                    'message': 'Payment already verified',
                    'data': {
                        'payment_status': 'success',
                        'reference': reference
                    }
                })
            
            if transaction_data['status'] == 'success':
                print(f"\n{'='*60}")
                print(f"✅ PAYSTACK PAYMENT SUCCESS - Reference: {reference}")
                print(f"{'='*60}")
                
                # Update Transaction status (using 'completed' to match model choices)
                txn.status = 'completed'
                txn.save()
                print(f"✅ Transaction {txn.transaction_id} status updated to: completed")
                
                # Update Order status
                order = txn.order
                if not order:
                    print(f"⚠️ ERROR: Order not found for transaction {txn.transaction_id}")
                    return Response({
                        'status': False,
                        'message': 'Order not found for this transaction'
                    }, status=status.HTTP_404_NOT_FOUND)
                
                print(f"✅ Found Order: {order.order_id}")
                order.status = 'paid'
                order.save()
                print(f"✅ Order {order.order_id} status updated to: paid")
                
                # Update Task status
                if not order.task:
                    print(f"⚠️ WARNING: Task not found for order {order.order_id}")
                else:
                    task = order.task
                    print(f"✅ Found Task: {task.task_id} - {task.title}")
                    
                    # Check if this is an onsite task
                    is_onsite = task.service_type == 'on_site'
                    print(f"✅ Task service_type: {task.service_type} (is_onsite: {is_onsite})")
                    
                    # Update Task status to 'in_progress' for all tasks
                    old_task_status = task.status
                    task.status = 'in_progress'
                    task.save()
                    print(f"✅ Task {task.task_id} status updated: {old_task_status} -> in_progress")
                    
                    # Update Proposal status to 'paid'
                    # Find the proposal associated with this task and freelancer
                    if order.freelancer:
                        freelancer_user = order.freelancer.user if order.freelancer else None
                        print(f"✅ Order has freelancer: {order.freelancer}")
                        print(f"✅ Freelancer user: {freelancer_user}")
                        
                        if freelancer_user:
                            # Try to find proposal with status 'accepted' first, then 'paid' as fallback
                            from django.db.models import Q
                            proposal = Proposal.objects.filter(
                                task=task,
                                freelancer=freelancer_user
                            ).filter(
                                Q(status='accepted') | Q(status='paid')
                            ).first()
                            
                            if proposal:
                                old_proposal_status = proposal.status
                                proposal.status = 'paid'
                                proposal.save()
                                print(f"✅ Proposal {proposal.proposal_id} status updated: {old_proposal_status} -> paid")
                                print(f"   Task: {proposal.task.title}, Freelancer: {proposal.freelancer.name}")
                            else:
                                # Try without status filter
                                all_proposals = Proposal.objects.filter(
                                    task=task,
                                    freelancer=freelancer_user
                                )
                                print(f"⚠️ No proposal found with accepted/paid status. Found {all_proposals.count()} proposals:")
                                for p in all_proposals:
                                    print(f"   - Proposal {p.proposal_id}: status={p.status}, freelancer={p.freelancer.name}")
                                
                                # Update the first proposal if any exist
                                first_proposal = all_proposals.first()
                                if first_proposal:
                                    old_proposal_status = first_proposal.status
                                    first_proposal.status = 'paid'
                                    first_proposal.save()
                                    print(f"✅ Proposal {first_proposal.proposal_id} status updated: {old_proposal_status} -> paid (fallback)")
                        else:
                            print(f"⚠️ WARNING: Freelancer user is None for order {order.order_id}")
                    else:
                        print(f"⚠️ WARNING: Order {order.order_id} has no freelancer assigned")
                    
                    # Update Contract
                    try:
                        contract = Contract.objects.get(task=task)
                        print(f"✅ Found Contract: {contract.contract_id}")
                        
                        # Verify freelancer matches if we have it
                        if order.freelancer and order.freelancer.user:
                            contract_freelancer_match = contract.freelancer == order.freelancer.user
                            print(f"✅ Contract freelancer match: {contract_freelancer_match}")
                            print(f"   Contract freelancer: {contract.freelancer.name if contract.freelancer else 'None'}")
                            print(f"   Order freelancer user: {order.freelancer.user.name if order.freelancer.user else 'None'}")
                            
                            if contract_freelancer_match or not contract.freelancer:
                                if is_onsite:
                                    # Generate 6-digit OTP for onsite tasks
                                    import random
                                    import string
                                    otp = ''.join(random.choices(string.digits, k=6))
                                    
                                    # Store OTP in both Contract and PaymentTransaction
                                    contract.verification_otp = otp
                                    contract.otp_generated_at = timezone.now()
                                    old_contract_status = contract.status
                                    contract.status = 'pending_verification'  # Awaiting OTP verification
                                    contract.is_paid = True  # Payment received but held in escrow
                                    contract.is_active = False  # Not active until OTP verified
                                    contract.payment_date = txn.created_at
                                    contract.save()
                                    print(f"✅ Contract {contract.contract_id} status updated: {old_contract_status} -> pending_verification")
                                    print(f"✅ Contract {contract.contract_id} is_paid set to: True")
                                    
                                    # Also store in PaymentTransaction for client display
                                    try:
                                        payment_txn = PaymentTransaction.objects.filter(
                                            order=order,
                                            paystack_reference=reference
                                        ).first()
                                        if payment_txn:
                                            payment_txn.verification_otp = otp
                                            payment_txn.otp_generated_at = timezone.now()
                                            payment_txn.save()
                                            print(f"✅ PaymentTransaction OTP updated")
                                    except Exception as e:
                                        print(f"⚠️ Error updating PaymentTransaction OTP: {e}")
                                    
                                    # Update task payment status to escrowed
                                    task.payment_status = 'escrowed'
                                    task.amount_held_in_escrow = order.amount
                                    task.save()
                                    print(f"✅ Task {task.task_id} payment_status updated to: escrowed")
                                    print(f"✅ Generated OTP {otp} for onsite task {task.task_id}")
                                else:
                                    # Remote task - activate immediately
                                    old_contract_status = contract.status
                                    contract.status = 'active'
                                    contract.is_paid = True
                                    contract.is_active = True
                                    contract.payment_date = txn.created_at
                                    contract.save()
                                    print(f"✅ Contract {contract.contract_id} status updated: {old_contract_status} -> active")
                                    print(f"✅ Contract {contract.contract_id} is_paid set to: True")
                            else:
                                print(f"⚠️ Contract freelancer mismatch - skipping contract update")
                        else:
                            # If no freelancer info, still update based on task type
                            if is_onsite:
                                # Generate OTP
                                import random
                                import string
                                otp = ''.join(random.choices(string.digits, k=6))
                                contract.verification_otp = otp
                                contract.otp_generated_at = timezone.now()
                                contract.status = 'pending_verification'
                                contract.is_paid = True
                                contract.is_active = False
                                contract.payment_date = txn.created_at
                                contract.save()
                                print(f"✅ Contract {contract.contract_id} updated for onsite task (no freelancer match)")
                            else:
                                old_contract_status = contract.status
                                contract.status = 'active'
                                contract.is_paid = True
                                contract.is_active = True
                                contract.payment_date = txn.created_at
                                contract.save()
                                print(f"✅ Contract {contract.contract_id} status updated: {old_contract_status} -> active (no freelancer match)")
                    except Contract.DoesNotExist:
                        # Contract might not exist yet, log but don't fail
                        print(f"⚠️ Contract not found for task {task.task_id}")
                    except Contract.MultipleObjectsReturned:
                        # Shouldn't happen with OneToOne, but handle it
                        contracts = Contract.objects.filter(task=task)
                        if order.freelancer and order.freelancer.user:
                            contracts = contracts.filter(freelancer=order.freelancer.user)
                        contract = contracts.first()
                        if contract:
                            if is_onsite:
                                import random
                                import string
                                otp = ''.join(random.choices(string.digits, k=6))
                                contract.verification_otp = otp
                                contract.otp_generated_at = timezone.now()
                                contract.status = 'pending_verification'
                                contract.is_paid = True
                                contract.is_active = False
                                contract.payment_date = txn.created_at
                                contract.save()
                                print(f"✅ Contract {contract.contract_id} updated (multiple contracts found)")
                            else:
                                old_contract_status = contract.status
                                contract.status = 'active'
                                contract.is_paid = True
                                contract.is_active = True
                                contract.payment_date = txn.created_at
                                contract.save()
                                print(f"✅ Contract {contract.contract_id} status updated: {old_contract_status} -> active (multiple contracts found)")
                        else:
                            print(f"⚠️ No matching contract found in multiple contracts")
                
                print(f"\n{'='*60}")
                print(f"✅ PAYMENT VERIFICATION COMPLETE")
                print(f"{'='*60}\n")
                
                # Serialize response data
                transaction_serializer = TransactionSerializer(txn)
                order_serializer = OrderSerializer(order) if order else None
                
                # Get OTP and contract info if onsite task
                response_data = {
                    'transaction': transaction_serializer.data,
                    'order': order_serializer.data if order_serializer else None,
                    'payment_status': 'success'
                }
                
                # Include OTP for onsite tasks
                if order and order.task and order.task.service_type == 'on_site':
                    try:
                        contract = Contract.objects.get(task=order.task)
                        if contract.verification_otp:
                            response_data['verification_otp'] = contract.verification_otp
                            response_data['is_onsite'] = True
                            response_data['message'] = 'Payment verified. Please provide this OTP to the freelancer in person.'
                        else:
                            response_data['is_onsite'] = True
                            response_data['message'] = 'Payment verified for onsite task.'
                    except Contract.DoesNotExist:
                        pass
                else:
                    response_data['is_onsite'] = False
                    response_data['message'] = 'Payment verified successfully. All records updated.'
                
                return Response({
                    'status': True,
                    **response_data
                })
            else:
                # Payment failed
                txn.status = 'failed'
                txn.save()
                
                return Response({
                    'status': False,
                    'message': 'Payment failed or was cancelled',
                    'data': {
                        'payment_status': 'failed',
                        'reference': reference
                    }
                })
            
    except Exception as e:
        import traceback
        traceback.print_exc()
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
                
                paystack = PaystackService()
                verification = paystack.verify_transaction(reference)
                
                if verification and verification.get('status'):
                    transaction_data = verification['data']
                    
                    if transaction_data['status'] == 'success':
                        # 1. Update the Transaction record
                        transaction = Transaction.objects.get(paystack_reference=reference)
                        transaction.status = 'completed'
                        transaction.save()
                        
                        # 2. Update the Task (Assuming Transaction has a FK to Task)
                        task = transaction.task
                        task.is_paid = True
                        task.amount_held_in_escrow = transaction.amount
                        task.payment_status = 'escrowed'
                        
                        # 3. BRANCH LOGIC: On-site vs Remote
                        if task.service_type == 'on_site':
                            # ONSITE: Generate OTP. Do NOT pay worker yet.
                            task.generate_otp() 
                            # Logic to notify Employer of their code
                            print(f"On-site Task Verified. OTP: {task.verification_code}")
                        else:
                            # REMOTE: Normal flow. Mark as in_progress/escrowed.
                            # Payment waits for a 'Submission' approval.
                            print(f"Remote Task Verified. Awaiting Submission.")
                        
                        task.save()

            return Response({'status': 'success'})
            
        except Exception as e:
            return Response({'status': 'error', 'message': str(e)}, status=400)
        


@api_view(['POST'])
@csrf_exempt
def paystack_webhook(request):
    """
    Handle Paystack webhook notifications for payment events.
    This is called by Paystack when payment status changes.
    """
    try:
        # 1️⃣ Verify webhook signature for security
        payload = request.body
        signature = request.headers.get('x-paystack-signature')
        
        if not signature:
            return Response({"status": "error", "message": "No signature provided"}, status=400)
        
        # Compute HMAC SHA512 signature
        computed_signature = hmac.new(
            settings.PAYSTACK_SECRET_KEY.encode('utf-8'),
            payload,
            hashlib.sha512
        ).hexdigest()
        
        # Verify signature matches
        if not hmac.compare_digest(computed_signature, signature):
            return Response({"status": "error", "message": "Invalid signature"}, status=400)

        # 2️⃣ Parse payload
        data = json.loads(payload)
        event = data.get('event')
        
        if event != 'charge.success':
            # We only care about successful charges
            return Response({"status": "ignored", "message": f"Event {event} not handled"})

        # 3️⃣ Extract transaction details
        transaction_data = data.get('data', {})
        reference = transaction_data.get('reference')
        
        if not reference:
            return Response({"status": "error", "message": "No reference provided"}, status=400)

        # 4️⃣ Verify with Paystack API for double confirmation
        paystack = PaystackService()
        verification = paystack.verify_transaction(reference)
        
        if not verification or not verification.get('status'):
            return Response({"status": "error", "message": "Paystack verification failed"}, status=400)
        
        verified_data = verification.get('data', {})
        
        if verified_data.get('status') != 'success':
            return Response({"status": "error", "message": "Transaction not successful"}, status=400)

        # 5️⃣ Find and update transaction record
        try:
            transaction = Transaction.objects.get(paystack_reference=reference, status='pending')
        except Transaction.DoesNotExist:
            return Response({"status": "error", "message": "Transaction not found"}, status=404)

        # Update transaction
        transaction.status = 'completed'
        transaction.completed_at = timezone.now()
        transaction.metadata = {
            'paystack_webhook': data,
            'verification_response': verification,
            'amount_paid': verified_data.get('amount', 0) / 100  # Convert from cents
        }
        transaction.save()

        # 6️⃣ Get related objects
        task = transaction.task
        order = transaction.order
        contract = transaction.contract
        employer = transaction.employer
        freelancer = transaction.freelancer

        if not all([task, order, contract, employer, freelancer]):
            return Response({"status": "error", "message": "Missing related objects"}, status=400)

        # 7️⃣ Update order
        order.status = 'paid'
        order.payment_reference = reference
        order.paid_at = timezone.now()
        order.save()

        # 8️⃣ Update task - funds now in escrow
        task.is_paid = True
        task.amount_held_in_escrow = transaction.amount
        task.payment_status = 'escrowed'
        task.paystack_reference = reference
        
        # 9️⃣ Activate contract
        contract.activate_after_payment()
        contract.mark_as_paid()

        # 🔟 BRANCH LOGIC: On-site vs Remote
        if task.service_type == 'on_site':
            # ON-SITE TASK: Generate OTP for employer
            otp_code = task.generate_otp()
            task.status = 'in_progress'
            
            # Notify employer with OTP
            Notification.objects.create(
                user=employer.user,
                title='OTP Generated for On-site Task',
                message=f'Task "{task.title}" is now active. Use OTP: {otp_code} to verify completion on site.',
                notification_type='onsite_otp',
                related_id=task.task_id
            )
            
            # Notify freelancer
            Notification.objects.create(
                user=freelancer.user,
                title='Task Funds Secured',
                message=f'Payment for task "{task.title}" is secured in escrow. Complete the work and ask employer for OP to receive payment.',
                notification_type='funds_secured'
            )
            
        else:
            # REMOTE TASK: Mark as in progress
            task.status = 'in_progress'
            
            # Notify freelancer to start work
            Notification.objects.create(
                user=freelancer.user,
                title='Start Your Work',
                message=f'Payment for task "{task.title}" is secured in escrow. You can now start working and submit your deliverables.',
                notification_type='start_work'
            )
        
        task.save()

        # 11️⃣ Notify employer payment successful
        Notification.objects.create(
            user=employer.user,
            title='Payment Successful',
            message=f'Payment of KSh {transaction.amount:.2f} for task "{task.title}" is secured in escrow.',
            notification_type='payment_successful'
        )

        print(f"✅ Webhook processed: Reference {reference}, Task: {task.title}, Type: {task.service_type}")
        
        return Response({"status": "success", "message": "Payment processed successfully"})

    except json.JSONDecodeError:
        return Response({"status": "error", "message": "Invalid JSON payload"}, status=400)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({"status": "error", "message": str(e)}, status=500)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_onsite_completion(request):
    """
    Employer verifies onsite task completion with OTP.
    Expects: {'task_id': int, 'otp_code': str}
    """
    try:
        task_id = request.data.get('task_id')
        otp_code = request.data.get('otp_code')
        
        if not task_id or not otp_code:
            return Response({
                "success": False, 
                "error": "task_id and otp_code are required"
            }, status=400)
        
        # Get task
        task = get_object_or_404(Task, task_id=task_id)
        
        # Verify employer owns the task
        employer = Employer.objects.get(pk=request.user.employer_id)
        if task.employer != employer:
            return Response({
                "success": False, 
                "error": "Unauthorized - only task employer can verify completion"
            }, status=403)
        
        # Check if task requires onsite verification
        if not task.requires_onsite_verification:
            return Response({
                "success": False, 
                "error": "This task does not require onsite verification"
            }, status=400)
        
        # Verify OTP
        is_valid, message = task.check_otp(otp_code)
        
        if is_valid:
            # Release payment to freelancer
            contract = Contract.objects.get(task=task)
            freelancer = task.assigned_user
            
            # In real implementation, you would call Paystack transfer here
            # For now, we'll just mark as released
            task.payment_status = 'released'
            task.save()
            
            contract.mark_as_completed()
            contract.mark_as_paid()
            
            # Notify freelancer
            Notification.objects.create(
                user=freelancer,
                title='Payment Released!',
                message=f'Payment for task "{task.title}" has been released to your account.',
                notification_type='payment_released'
            )
            
            return Response({
                "success": True,
                "message": "Task completed and payment released successfully",
                "task_id": task.task_id,
                "task_title": task.title,
                "task_status": task.status,
                "payment_status": task.payment_status
            })
        else:
            return Response({
                "success": False,
                "error": message,
                "attempts_remaining": 5 - task.verification_attempts
            }, status=400)
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({"success": False, "error": str(e)}, status=500)
        
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
# In your Django view
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def recommended_jobs(request):
    """Get recommended jobs for a freelancer - SIMPLE VERSION"""
    try:
        # Get the authenticated freelancer
        freelancer_user = request.user
        
        if not freelancer_user:
            return Response({"status": False, "message": "User not found"}, status=404)
        
        # Get freelancer profile
        try:
            freelancer_profile = UserProfile.objects.get(user=freelancer_user)
        except UserProfile.DoesNotExist:
            return Response({
                "status": False,
                "message": "Freelancer profile not found. Please complete your profile."
            }, status=404)
        
        print(f"\n=== API CALL: Recommended Jobs ===")
        print(f"Freelancer: {freelancer_user.name}")
        print(f"Freelancer skills: '{freelancer_profile.skills}'")
        
        # Get ALL active tasks (no skill filtering initially)
        active_tasks = Task.objects.filter(
            Q(status='open') | Q(status='pending'),
            is_active=True,
            is_approved=True
        ).select_related('employer').order_by('-created_at')
        
        print(f"Found {active_tasks.count()} active tasks")
        
        # If no active tasks, get any tasks
        if not active_tasks.exists():
            active_tasks = Task.objects.filter(
                is_active=True
            ).select_related('employer').order_by('-created_at')[:50]
            print(f"No 'open' tasks. Showing {active_tasks.count()} total tasks")
        
        # Convert to list for processing
        tasks_list = list(active_tasks)
        
        if not tasks_list:
            return Response({
                "status": True,
                "message": "No tasks available at the moment",
                "recommended": []
            })
        
        # Show sample tasks for debugging
        print(f"\n=== SAMPLE TASKS (first 5) ===")
        for i, task in enumerate(tasks_list[:5]):
            print(f"Task {i}: '{task.title}'")
            print(f"  ID: {task.task_id}")
            print(f"  Skills: '{task.required_skills}'")
            print(f"  Category: {task.category}")
            print(f"  Status: {task.status}")
        
        # Use SIMPLE matcher
        recommendations = SimpleJobMatcher.rank_jobs_for_freelancer(
            freelancer_profile, 
            tasks_list, 
            top_n=50
        )
        
        print(f"\n=== MATCHING RESULTS ===")
        print(f"Generated {len(recommendations)} recommendations")
        
        # Process recommendations
        recommended_jobs_data = []
        
        for rec in recommendations:
            try:
                # Find the task
                task = next(t for t in tasks_list if t.task_id == rec["job_id"])
                
                # Prepare job data
                job_data = {
                    "task_id": task.task_id,
                    "title": task.title,
                    "description": task.description[:200] + "..." if len(task.description) > 200 else task.description,
                    "budget": float(task.budget) if task.budget else 0,
                    "category": task.category,
                    "service_type": task.service_type,
                    "status": task.status,
                    "created_at": task.created_at,
                    "required_skills": task.required_skills,
                    "match_score": rec["score"],  # Percentage score
                    "skill_overlap": rec["skill_overlap"],
                    "common_skills": rec["common_skills"],
                    "freelancer_skills": rec["all_freelancer_skills"],
                    "job_skills": rec["all_job_skills"],
                    "employer": {
                        "employer_id": task.employer.employer_id,
                        "username": task.employer.username,
                        "contact_email": task.employer.contact_email,
                    } if task.employer else None
                }
                
                recommended_jobs_data.append(job_data)
                
            except (StopIteration, AttributeError) as e:
                print(f"Error processing recommendation: {e}")
                continue
        
        # Sort by match score
        recommended_jobs_data.sort(key=lambda x: x["match_score"], reverse=True)
        
        print(f"\n=== FINAL RESULT ===")
        print(f"Returning {len(recommended_jobs_data)} jobs")
        
        return Response({
            "status": True,
            "message": f"Found {len(recommended_jobs_data)} recommended jobs",
            "recommended": recommended_jobs_data
        })
        
    except Exception as e:
        print(f"ERROR in recommended_jobs: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            "status": False,
            "message": f"Server error: {str(e)}"
        }, status=500)
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def accept_proposal(request):
    try:
        with transaction.atomic():
            # 1. Get Employer
            employer = request.user
            print(f"✅ DEBUG: Using employer: {employer.username}, ID: {employer.employer_id}")

            # 2. Get Proposal & Task
            proposal_id = request.data.get('proposal_id')
            proposal = get_object_or_404(Proposal, pk=proposal_id)
            task = proposal.task 

            if task.status != 'open':
                return Response({"success": False, "error": f"Task is {task.status}, not open"}, status=400)

            # 3. Get or Create Freelancer Profile (FIXED with get_or_create)
            freelancer_profile, created = Freelancer.objects.get_or_create(
                user=proposal.freelancer,
                defaults={
                    'business_name': f"{proposal.freelancer.name} Freelancing",
                    'is_verified': False,
                    'is_paystack_setup': False,
                    'total_earnings': 0.00,
                    'pending_payout': 0.00
                }
            )
            
            if created:
                print(f"✅ DEBUG: Created new freelancer profile for {proposal.freelancer.name}")
            else:
                print(f"✅ DEBUG: Found existing freelancer profile for {proposal.freelancer.name}")

            # 4. Status Updates
            proposal.status = 'accepted'
            proposal.save()
            print(f"✅ DEBUG: Proposal {proposal_id} marked as accepted")
            
            # Reject other proposals
            rejected_count = Proposal.objects.filter(task=task).exclude(pk=proposal.pk).update(status='rejected')
            print(f"✅ DEBUG: Rejected {rejected_count} other proposals")
            
            # Assign user to task
            task.assigned_user = proposal.freelancer
            task.status = 'awaiting_payment'
            task.save()
            print(f"✅ DEBUG: Task {task.task_id} assigned to {proposal.freelancer.name}")

            # 5. Create Contract
            contract = Contract.objects.create(
                task=task,
                freelancer=proposal.freelancer,
                employer=employer,
                status='pending',
                start_date=timezone.now()
            )
            print(f"✅ DEBUG: Created contract ID: {contract.contract_id}")

            # 6. Create Order
            order, created = Order.objects.get_or_create(
                task=task,
                employer=employer,
                freelancer=freelancer_profile,
                defaults={
                    'order_id': uuid.uuid4(), # Pure UUID object
                    'amount': Decimal(str(task.budget or 0)),
                    'currency': 'KSH',
                    'status': 'pending'
                }
            )
            print(f"✅ DEBUG: {'Created' if created else 'Found existing'} order: {order.order_id}")

            # 7. Return payload for Flutter
            return Response({
                "success": True,
                "order_id": str(order.order_id), # Send as string to Flutter
                "amount": float(order.amount),
                "contract_id": contract.contract_id,
                "task_title": task.title,
                "contact_email": employer.contact_email,
                "freelancer_name": freelancer_profile.name,
                "currency": "KSH",
                "requires_payment": True,
                "message": f"Proposal accepted! Order {order.order_id} created."
            })

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({"success": False, "error": str(e)}, status=500)
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def reject_contract(request, contract_id):
    contract = get_object_or_404(Contract, contract_id=contract_id)
    
    if request.user != contract.freelancer:
        return Response({"error": "Unauthorized"}, status=403)

    # Instead of contract.delete(), change status
    contract.status = 'rejected'
    contract.is_active = False
    contract.save()

    return Response({
        "status": True,
        "message": "Contract rejected. Client can now see rejection status and request refund.",
        "is_paid": contract.is_paid
    })
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def accept_contract(request, contract_id):
    contract = get_object_or_404(Contract, contract_id=contract_id)

    if request.user != contract.freelancer:
        return Response({"error": "Unauthorized"}, status=403)

    contract.freelancer_accepted = True
    contract.status = 'accepted' # Update the status string too
    contract.activate_contract() # Assuming this sets is_active = True
    contract.save()

    return Response({
        "status": True,
        "message": "Contract accepted",
        "is_active": contract.is_active,
        "freelancer_accepted": contract.freelancer_accepted
    })
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def freelancer_contracts(request):
    try:
        # Get all contracts where this user is the freelancer
        contracts = Contract.objects.filter(
            freelancer=request.user
        ).select_related('task', 'employer')

        all_contracts_data = []
        pending_contracts = []
        active_contracts = []

        for contract in contracts:
            contract_data = {
                "contract_id": contract.contract_id,
                "task": {
                    "task_id": contract.task.task_id,
                    "title": contract.task.title,
                    "description": contract.task.description,
                    "budget": float(contract.task.budget) if contract.task.budget else 0.0,
                    "deadline": contract.task.deadline.isoformat() if contract.task.deadline else None,
                    "status": contract.task.status,
                    "service_type": getattr(contract.task, 'service_type', 'remote'), # Crucial for UI
                },
                "employer": {
                    "id": contract.employer.employer_id,
                    "name": contract.employer.username,
                    "username": contract.employer.username,
                    "email": getattr(contract.employer, 'contact_email', ''),
                },
                "start_date": contract.start_date.isoformat(),
                "end_date": contract.end_date.isoformat() if contract.end_date else None,
                "employer_accepted": contract.employer_accepted,
                "freelancer_accepted": contract.freelancer_accepted,
                "is_active": contract.is_active,
                "status": contract.status,
            }

            # LOGIC FIX: If freelancer hasn't accepted, it belongs in pending
            if not contract.freelancer_accepted:
                pending_contracts.append(contract_data)
            # If both have accepted, it is active
            elif contract.employer_accepted and contract.freelancer_accepted:
                active_contracts.append(contract_data)
            
            all_contracts_data.append(contract_data)

        return Response({
            "status": True,
            "contracts": all_contracts_data, # Flutter looks for this key
            "pending_contracts": pending_contracts,
            "active_contracts": active_contracts,
            "pending_count": len(pending_contracts),
            "active_count": len(active_contracts),
        })

    except Exception as e:
        return Response({"status": False, "error": str(e)}, status=500)  
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


from rest_framework import status  
@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def employer_contracts(request):
    try:
        print(f"\n{'='*60}")
        print(f"FETCHING CONTRACTS FOR: {request.user.username}")
        print(f"{'='*60}")
        
        # Removed select_related to prevent 'user' join errors
        contracts = Contract.objects.filter(
            employer=request.user
        ).order_by('-start_date')
        
        contracts_data = []
        
        for contract in contracts:
            # 1. Resolve Order ID
            order_id = None
            try:
                order = Order.objects.filter(task=contract.task, employer=contract.employer).first()
                if order:
                    order_id = str(order.order_id)
            except Exception: 
                pass

            # 2. STATUS MAPPING LOGIC (KEEPING YOUR EXACT LOGIC)
            status_text = "Unknown"

            if contract.status == 'cancelled':
                status_text = 'Cancelled'
            elif contract.is_completed and contract.is_paid:
                status_text = 'Completed & Paid'
            elif not contract.freelancer_accepted and not contract.is_active:
                status_text = 'Rejected'
            elif contract.is_paid:
                if contract.status == 'pending_verification':
                    status_text = 'Awaiting OTP Verification'
                elif contract.status == 'accepted' or contract.status == 'active':
                    status_text = 'Accepted & Paid'
                else:
                    status_text = 'In Escrow'
            elif not contract.is_paid:
                if not contract.freelancer_accepted:
                    status_text = 'Awaiting Freelancer'
                else:
                    status_text = 'Awaiting Payment'

            # 3. CONSTRUCT DATA (Ensuring all fields match Flutter ContractModel)
            contract_data = {
                'contract_id': contract.contract_id,
                'order_id': order_id,
                'order_status': 'paid' if contract.is_paid else 'pending',
                'task_id': contract.task.task_id if contract.task else 0,
                'task_title': contract.task.title if contract.task else 'Unknown',
                'task_description': contract.task.description if contract.task else '',
                'task_category': contract.task.category if contract.task else 'other',
                'freelancer_id': contract.freelancer.user_id if contract.freelancer else 0,
                'freelancer_name': contract.freelancer.name if contract.freelancer else 'Unknown',
                'freelancer_email': contract.freelancer.email if contract.freelancer else '',
                'amount': float(contract.task.budget) if contract.task and contract.task.budget else 0.0,
                'status': status_text,
                'is_active': contract.is_active,
                'is_completed': contract.is_completed,
                'is_paid': contract.is_paid,
                'employer_accepted': contract.employer_accepted,
                'freelancer_accepted': contract.freelancer_accepted,
                'service_type': contract.task.service_type if contract.task else 'remote',
                'start_date': contract.start_date.strftime('%Y-%m-%d') if contract.start_date else None,
                'payment_date': contract.payment_date.strftime('%Y-%m-%d') if contract.payment_date else None,
                'completed_date': contract.completed_date.strftime('%Y-%m-%d') if contract.completed_date else None,
                'verification_code': contract.completion_code, 
                'completion_code': contract.completion_code,
                'location_address': contract.task.location_address if contract.task else '',
                'deadline': contract.task.deadline.strftime('%Y-%m-%d') if contract.task and hasattr(contract.task, 'deadline') and contract.task.deadline else None,
            }
            contracts_data.append(contract_data)
            
            print(f"ID: {contract.contract_id} | UI: {status_text} | DB: {contract.status}")

        return Response({
            'status': True,
            'contracts': contracts_data,
        }, status=status.HTTP_200_OK)

    except Exception as e:
        print(f"❌ API ERROR: {str(e)}")
        return Response({'status': False, 'error': str(e)}, status=500)
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def request_refund(request, contract_id):
    # 1. Get the contract
    contract = get_object_or_404(Contract, contract_id=contract_id)

    # 2. Authorization: Only the Employer (Client) who paid can request the refund
    if request.user != contract.employer:
        return Response({"status": False, "message": "Unauthorized"}, status=403)

    # 3. Validation: Only refund if Freelancer rejected AND payment was made
    if contract.status != 'rejected':
        return Response({"status": False, "message": "Refund only available for rejected contracts."}, status=400)
    
    if not contract.is_paid:
        return Response({"status": False, "message": "No payment found for this contract."}, status=400)

    if contract.status == 'refunded':
        return Response({"status": False, "message": "Refund already processed."}, status=400)

    # 4. Process Refund (Atomic Transaction)
    try:
        with transaction.atomic():
            # Get Client's Wallet
            wallet, created = Wallet.objects.get_or_create(user=request.user)
            
            # Add funds back to client wallet
            wallet.balance += contract.amount
            wallet.save()

            # Update contract status so it can't be refunded again
            contract.status = 'refunded'
            contract.is_active = False
            contract.save()

            return Response({
                "status": True, 
                "message": f"KES {contract.amount} has been refunded to your wallet balance."
            })
            
    except Exception as e:
        return Response({"status": False, "message": f"Refund failed: {str(e)}"}, status=500)
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
def release_payment(request):
    """
    POST /api/contracts/release-payment/
    Release payment to freelancer for a completed contract
    """
    try:
        print(f"\n{'='*60}")
        print("RELEASE PAYMENT API CALLED")
        print(f"{'='*60}")
        
        contract_id = request.data.get('contract_id')
        if not contract_id:
            return Response({
                'status': False,
                'message': 'contract_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        print(f"Releasing payment for contract: {contract_id}")
        
        # Get the contract
        try:
            contract = Contract.objects.get(
                contract_id=contract_id,
                employer=request.user
            )
        except Contract.DoesNotExist:
            return Response({
                'status': False,
                'message': 'Contract not found or you do not have permission'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Check if contract is paid
        if not contract.is_paid:
            return Response({
                'status': False,
                'message': 'Contract is not paid yet. Please pay into escrow first.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if already completed
        if contract.is_completed:
            return Response({
                'status': False,
                'message': 'Payment has already been released for this contract.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if task exists
        if not contract.task:
            return Response({
                'status': False,
                'message': 'Associated task not found'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Start database transaction
        with transaction.atomic():
            # Mark contract as completed
            contract.is_completed = True
            contract.completed_date = timezone.now()
            contract.status = 'completed'
            contract.save()
            
            # Update task status
            task = contract.task
            task.status = 'completed'
            task.payment_status = 'released'
            task.save()
            
            # Get freelancer and update their wallet
            freelancer = contract.freelancer
            if freelancer:
                amount = task.budget if task.budget else 0
                
                # Update freelancer's wallet balance
                freelancer.wallet_balance += amount
                freelancer.save()
                
                # Update freelancer profile earnings if exists
                try:
                    freelancer_profile = Freelancer.objects.get(user=freelancer)
                    freelancer_profile.total_earnings += amount
                    freelancer_profile.save()
                except Freelancer.DoesNotExist:
                    pass
                
                # Update order status if exists
                try:
                    order = Order.objects.filter(
                        task=task,
                        employer=contract.employer
                    ).first()
                    if order:
                        order.status = 'completed'
                        order.save()
                except Exception as e:
                    print(f"⚠️ Error updating order status: {e}")
                
                print(f"✅ Payment of {amount} released to freelancer: {freelancer.name}")
                
                return Response({
                    'status': True,
                    'success': True,
                    'message': f'Payment of KES {amount} released to {freelancer.name}',
                    'amount': float(amount),
                    'freelancer_name': freelancer.name,
                    'contract_id': contract.contract_id,
                    'completed_date': contract.completed_date.strftime('%Y-%m-%d %H:%M:%S')
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'status': False,
                    'success': False,
                    'message': 'Freelancer not found for this contract'
                }, status=status.HTTP_400_BAD_REQUEST)
                
    except Exception as e:
        print(f"❌ Error in release_payment: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'success': False,
            'message': f'Failed to release payment: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
# Note the added contract_id=None to catch URL parameters safely
def generate_verification_code(request, contract_id=None):
    """
    POST /api/contracts/generate-verification-code/
    OR POST /api/contracts/<id>/generate-verification-code/
    """
    try:
        print(f"\n{'='*60}")
        print("GENERATE VERIFICATION CODE")
        print(f"{'='*60}")
        
        # 1. Get ID from URL or from request body
        final_contract_id = contract_id or request.data.get('contract_id')
        
        if not final_contract_id:
            return Response({
                'status': False,
                'message': 'contract_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        print(f"Generating code for contract: {final_contract_id}")
        
        # 2. Get the contract (Secured by employer=request.user)
        try:
            contract = Contract.objects.get(
                contract_id=final_contract_id,
                employer=request.user
            )
        except (Contract.DoesNotExist, ValueError):
            return Response({
                'status': False,
                'message': 'Contract not found or unauthorized'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # 3. Business Logic Validations
        if not contract.task or contract.task.service_type != 'on_site':
            return Response({
                'status': False,
                'message': 'Only on-site tasks require verification codes'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not contract.is_paid:
            return Response({
                'status': False,
                'message': 'Contract must be paid before generating verification code'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if contract.is_completed:
            return Response({
                'status': False,
                'message': 'Contract is already completed'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # 4. Generate 6-digit code
        code = ''.join(random.choices('0123456789', k=6))
        
        # 5. Save to contract model
        contract.completion_code = code
        contract.save()
        
        print(f"✅ Generated verification code: {code} for contract {final_contract_id}")
        
        return Response({
            'status': True,
            'success': True,
            'message': 'Verification code generated',
            'verification_code': code,
            'contract_id': final_contract_id,
            'task_title': contract.task.title if contract.task else 'Unknown Task'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'status': False,
            'message': f'Failed to generate code: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_on_site_completion(request, contract_id):
    """
    POST /api/contracts/<int:contract_id>/verify-otp/
    Verify OTP and mark on-site contract as completed
    """
    try:
        print(f"\n{'='*60}")
        print(f"VERIFY ON-SITE COMPLETION FOR CONTRACT {contract_id}")
        print(f"{'='*60}")
        
        verification_code = request.data.get('verification_code')
        if not verification_code:
            return Response({
                'status': False,
                'success': False,
                'message': 'verification_code is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get the contract
        try:
            contract = Contract.objects.get(
                contract_id=contract_id,
                employer=request.user
            )
        except Contract.DoesNotExist:
            return Response({
                'status': False,
                'success': False,
                'message': 'Contract not found or not an on-site task'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Check if it's an on-site task
        if not contract.task or contract.task.service_type != 'on_site':
            return Response({
                'status': False,
                'success': False,
                'message': 'Only on-site tasks require verification'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if code matches
        if not contract.completion_code or str(contract.completion_code) != str(verification_code):
            return Response({
                'status': False,
                'success': False,
                'message': 'Invalid verification code'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Mark as completed
        with transaction.atomic():
            contract.is_completed = True
            contract.completed_date = timezone.now()
            contract.status = 'completed'
            contract.save()
            
            # Update task
            task = contract.task
            task.status = 'completed'
            task.payment_status = 'released'
            task.save()
            
            # Release payment to freelancer
            freelancer = contract.freelancer
            amount = task.budget if task.budget else 0
            
            if freelancer:
                freelancer.wallet_balance += amount
                freelancer.save()
                
                # Update freelancer profile
                try:
                    freelancer_profile = Freelancer.objects.get(user=freelancer)
                    freelancer_profile.total_earnings += amount
                    freelancer_profile.save()
                except Freelancer.DoesNotExist:
                    pass
                
                # Update order status
                try:
                    order = Order.objects.filter(
                        task=task,
                        employer=contract.employer
                    ).first()
                    if order:
                        order.status = 'completed'
                        order.save()
                except Exception as e:
                    print(f"⚠️ Error updating order status: {e}")
            
            print(f"✅ On-site contract {contract_id} verified and completed")
            
            return Response({
                'status': True,
                'success': True,
                'message': f'Contract completed! Payment of KES {amount} released to {freelancer.name if freelancer else "freelancer"}',
                'contract_id': contract_id,
                'completed': True
            }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"❌ Error in verify_on_site_completion: {str(e)}")
        return Response({
            'status': False,
            'success': False,
            'message': f'Failed to verify completion: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)    
    
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

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_order_payment(request, order_id):
    """
    Verify that an order is ready for payment.
    """
    try:
        # STEP 1: CAST STRING TO UUID (Fixes Postgres Error)
        try:
            order_uuid = uuid.UUID(str(order_id))
        except (ValueError, TypeError):
            return Response({'status': False, 'message': 'Invalid UUID format'}, status=400)

        # STEP 2: Query using the UUID object
        order = get_object_or_404(Order, order_id=order_uuid)

        freelancer_id = request.GET.get('freelancer_id')
        if not freelancer_id:
            return Response({'status': False, 'message': 'Freelancer ID required'}, status=400)

        # Verify freelancer assignment
        if not order.freelancer or str(order.freelancer.user.id) != str(freelancer_id):
            return Response({'status': False, 'message': 'Freelancer mismatch'}, status=400)

        # Get profile for paystack subaccount info
        freelancer_user = order.freelancer.user
        # Use filter().first() to avoid DoesNotExist crashes
        freelancer_profile = UserProfile.objects.filter(user=freelancer_user).first()

        return Response({
            'status': True,
            'message': 'Payment verified successfully',
            'data': {
                'order_id': str(order.order_id),
                'freelancer_id': freelancer_user.id,
                'freelancer_name': f"{freelancer_user.first_name} {freelancer_user.last_name}",
                'freelancer_email': freelancer_user.email,
                'freelancer_paystack_account': getattr(freelancer_profile, 'paystack_account_id', 'default_account') if freelancer_profile else 'default_account',
                'amount': float(order.amount),
                'currency': order.currency,
                'order_status': order.status,
            }
        })
    except Exception as e:
        traceback.print_exc()
        return Response({'status': False, 'message': f"Verification Error: {str(e)}"}, status=500)

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
    Verify that an order is ready for payment.
    """
    try:
        # STEP 1: CAST STRING TO UUID
        try:
            order_uuid = uuid.UUID(str(order_id))
        except (ValueError, TypeError):
            return Response({'status': False, 'message': 'Invalid UUID format'}, status=400)

        # STEP 2: Query using the UUID object with order_id field
        order = get_object_or_404(Order, order_id=order_uuid, employer=request.user)

        freelancer_id = request.GET.get('freelancer_id')
        if not freelancer_id:
            return Response({'status': False, 'message': 'Freelancer ID required'}, status=400)

        # Verify freelancer assignment
        if not order.freelancer or str(order.freelancer.user.id) != str(freelancer_id):
            return Response({'status': False, 'message': 'Freelancer mismatch'}, status=400)

        # Get profile for paystack subaccount info
        freelancer_user = order.freelancer.user
        freelancer_profile = UserProfile.objects.filter(user=freelancer_user).first()

        return Response({
            'status': True,
            'message': 'Payment verified successfully',
            'data': {
                'order_id': str(order.order_id),
                'freelancer_id': freelancer_user.id,
                'freelancer_name': f"{freelancer_user.first_name} {freelancer_user.last_name}",
                'freelancer_email': freelancer_user.email,
                'freelancer_paystack_account': getattr(freelancer_profile, 'paystack_account_id', 'default_account') if freelancer_profile else 'default_account',
                'amount': float(order.amount),
                'currency': order.currency,
                'order_status': order.status,
            }
        })
    except Exception as e:
        traceback.print_exc()
        return Response({'status': False, 'message': f"Verification Error: {str(e)}"}, status=500)

@api_view(['POST'])
@authentication_classes([EmployerTokenAuthentication])
@permission_classes([IsAuthenticated])
def initialize_payment(request):
    try:
        data = request.data
        order_id_raw = data.get('order_id')
        email = data.get('email')
        freelancer_paystack_account = data.get('freelancer_paystack_account', 'default_account')

        # CRITICAL: CASTING TO UUID OBJECT
        try:
            order_uuid = uuid.UUID(str(order_id_raw))
            # FIX: Query using order_id field with UUID object
            order = Order.objects.get(order_id=order_uuid)
        except (Order.DoesNotExist, ValueError):
            return Response({'status': False, 'message': 'Order not found'}, status=404)

        # Verify the order belongs to the authenticated employer
        if order.employer != request.user:
            return Response({'status': False, 'message': 'Unauthorized access to order'}, status=403)

        task = order.task
        is_onsite = (task.service_type == 'on_site') if task else False
        amount_cents = int(order.amount * 100)

        # Generate Paystack Reference
        random_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
        # Use str(order_uuid) to get string representation
        paystack_reference = f"HW_{str(order_uuid)[:8]}_{random_suffix}"

        paystack_service = PaystackService()
        
        if freelancer_paystack_account != 'default_account':
            platform_amount = int(amount_cents * 0.1)
            freelancer_amount = amount_cents - platform_amount
            subaccounts = [
                {"subaccount": freelancer_paystack_account, "share": freelancer_amount},
                {"subaccount": settings.PAYSTACK_PLATFORM_SUBACCOUNT, "share": platform_amount}
            ]
            paystack_response = paystack_service.initialize_split_transaction(
                email=email, amount_cents=amount_cents, reference=paystack_reference,
                subaccounts=subaccounts, callback_url=f"{settings.FRONTEND_URL}/payment/callback", currency="KES"
            )
        else:
            paystack_response = paystack_service.initialize_transaction(
                email=email, amount_cents=amount_cents, reference=paystack_reference,
                callback_url=f"{settings.FRONTEND_URL}/payment/callback", currency="KES"
            )

        if not paystack_response.get('status'):
            return Response({'status': False, 'message': paystack_response.get('message')}, status=400)

        paystack_data = paystack_response['data']
        
        with django_transaction.atomic():
            # Create the transaction record
            payment_transaction = PaymentTransaction.objects.create(
                order=order,  # Pass the object, not the ID string
                paystack_reference=paystack_data.get('reference'),
                amount=order.amount,
                platform_commission=Decimal(str(float(order.amount) * 0.1)),
                freelancer_share=Decimal(str(float(order.amount) * 0.9)),
                status='pending'
            )
            order.status = 'pending_payment'
            order.save()

        return Response({
            'status': True,
            'message': 'Payment initialized successfully',
            'data': {
                'authorization_url': paystack_data.get('authorization_url'),
                'reference': paystack_data.get('reference'),
                'transaction_id': str(payment_transaction.id),
                'is_onsite': is_onsite
            }
        })

    except Exception as e:
        print("!!! SERVER ERROR LOG !!!")
        traceback.print_exc()
        return Response({'status': False, 'message': f"Server Error: {str(e)}"}, status=500)

@api_view(['GET'])
@authentication_classes([EmployerTokenAuthentication]) 
@permission_classes([IsAuthenticated])
def verify_payment(request, reference):
    try:
        print(f"🔍 DEBUG Django: Looking for reference: {reference}")
        
        paystack_service = PaystackService()
        verification = paystack_service.verify_transaction(reference)
        
        print(f"🔍 DEBUG Django: Paystack verification response: {verification}")
        
        if not verification or not verification.get('status'):
            return Response({'status': False, 'message': 'Paystack verification failed'}, status=400)

        data = verification['data']
        
        with django_transaction.atomic():
            try:
                # Find transaction
                txn = PaymentTransaction.objects.select_for_update().get(paystack_reference=reference)
                print(f"✅ DEBUG Django: Found transaction: {txn.id}")
            except PaymentTransaction.DoesNotExist:
                print(f"❌ DEBUG Django: No transaction found with reference: {reference}")
                return Response({'status': False, 'message': 'Transaction not found'}, status=404)

            if txn.status == 'success':
                print(f"ℹ️ DEBUG Django: Transaction already processed")
                return Response({'status': True, 'message': 'Already processed', 'data': {'order_id': txn.order.order_id}})

            if data['status'] == 'success':
                # ============ 1. UPDATE TRANSACTION ============
                txn.status = 'success'
                txn.save()
                print(f"✅ DEBUG Django: Transaction marked as success")

                # ============ 2. UPDATE ORDER ============
                order = txn.order
                order.status = 'paid'
                order.save()
                print(f"✅ DEBUG Django: Order {order.order_id} marked as paid")

                # ============ 3. GET TASK ============
                task = order.task
                if not task:
                    print(f"❌ DEBUG Django: No task associated with order {order.order_id}")
                    return Response({'status': False, 'message': 'No task found for this order'}, status=400)
                
                print(f"✅ DEBUG Django: Task found: {task.title}")

                # ============ 4. UPDATE TASK ============
                task.is_paid = True
                task.payment_status = 'escrowed'
                task.amount_held_in_escrow = order.amount
                task.status = 'in_progress'
                task.save()
                print(f"✅ DEBUG Django: Task updated: paid=True, status=in_progress")

                # ============ 5. UPDATE PROPOSAL ============
                try:
                    proposal = Proposal.objects.get(task=task, status='accepted')
                    proposal.status = 'paid'
                    proposal.save()
                    print(f"✅ DEBUG Django: Proposal {proposal.proposal_id} marked as paid")
                except Proposal.DoesNotExist:
                    # Try alternative: find proposal by freelancer
                    if order.freelancer:
                        try:
                            proposal = Proposal.objects.get(
                                task=task,
                                freelancer=order.freelancer.user  # Use freelancer.user
                            )
                            proposal.status = 'paid'
                            proposal.save()
                            print(f"✅ DEBUG Django: Proposal found via freelancer, marked as paid")
                        except Proposal.DoesNotExist:
                            print(f"⚠️ DEBUG Django: No proposal found for task {task.task_id}")

                # ============ 6. UPDATE/CREATE CONTRACT ============
                # FIX: Use order.freelancer.user instead of order.freelancer
                freelancer_user = order.freelancer.user if order.freelancer else None
                
                if freelancer_user and order.employer:
                    # Try to get existing contract
                    contract = Contract.objects.filter(
                        task=task,
                        freelancer=freelancer_user,  # ✅ CORRECT: User instance
                        employer=order.employer
                    ).first()
                    
                    if contract:
                        # Update existing contract
                        contract.is_paid = True
                        contract.is_active = True
                        contract.status = 'active'
                        contract.payment_date = timezone.now()
                        contract.save()
                        print(f"✅ DEBUG Django: Existing contract updated")
                    else:
                        # Create new contract
                        contract = Contract.objects.create(
                            task=task,
                            freelancer=freelancer_user,  # ✅ CORRECT: User instance
                            employer=order.employer,
                            is_paid=True,
                            is_active=True,
                            status='active',
                            payment_date=timezone.now()
                        )
                        print(f"✅ DEBUG Django: New contract created")

                # ============ 7. CHECK IF ONSITE ============
                is_onsite = (task.service_type == 'on_site')
                verification_otp = None
                
                if is_onsite:
                    print(f"🔍 DEBUG Django: This is an ONSITE task")
                    otp = task.generate_otp()
                    verification_otp = otp
                    
                    # Save OTP to transaction
                    txn.verification_otp = otp
                    txn.otp_generated_at = timezone.now()
                    txn.save()
                    
                    # Save OTP to contract if exists
                    if 'contract' in locals() and contract:
                        contract.verification_otp = otp
                        contract.otp_generated_at = timezone.now()
                        contract.save()
                    
                    print(f"✅ DEBUG Django: Generated OTP: {otp}")

                return Response({
                    'status': True,
                    'message': 'Payment verified successfully',
                    'data': {
                        'order_id': str(order.order_id),
                        'task_id': task.task_id,
                        'is_onsite': is_onsite,
                        'verification_otp': verification_otp,
                        'proposal_status': 'paid',
                        'task_status': task.status,
                        'payment_status': task.payment_status,
                        'contract_updated': 'contract' in locals()
                    }
                })
            else:
                # Payment failed
                txn.status = 'failed'
                txn.save()
                print(f"❌ DEBUG Django: Payment failed at gateway")
                return Response({'status': False, 'message': 'Payment failed at gateway'})

    except Exception as e:
        print(f"❌ DEBUG Django: Verification Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({'status': False, 'message': str(e)}, status=500)
        

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
        
        # FIXED: Use get_or_create instead of checking for existence
        freelancer, created = Freelancer.objects.get_or_create(
            user=user,
            defaults={
                'business_name': f"{user.name} Freelancing",
                'is_verified': False,
                'is_paystack_setup': False,
                'total_earnings': 0.00,
                'pending_payout': 0.00
            }
        )
        
        if created:
            print(f"✅ Created new freelancer profile for {user.name}")
        else:
            print(f"✅ Found existing freelancer profile for {user.name}")
        
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
                'profile_created': created  # Let the frontend know if profile was just created
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
              
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def getemployer_profile(request, employer_id):
    """Get employer profile for freelancers to view"""
    try:
        # Convert employer_id to integer
        try:
            employer_id_int = int(employer_id)
        except ValueError:
            return Response({
                'success': False,
                'message': 'Invalid employer ID format'
            }, status=400)
        
        # FIX: Get from Employer table, NOT User table
        try:
            employer = Employer.objects.get(employer_id=employer_id_int)
        except Employer.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Employer not found'
            }, status=404)
        
        # Get employer profile
        try:
            profile = EmployerProfile.objects.get(employer=employer)
        except EmployerProfile.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Employer profile not found'
            }, status=404)
        
        # Get employer statistics
        try:
            total_tasks = Task.objects.filter(employer=employer).count()
        except:
            total_tasks = 0
        
        try:
            total_spent_result = Contract.objects.filter(
                task__employer=employer,
                status='completed'
            ).aggregate(total_spent=Sum('price'))
            total_spent = total_spent_result['total_spent'] or 0
        except:
            total_spent = 0
        
        # Get average rating
        try:
            # Need to get the User object for this employer to find ratings
            # Since ratings are linked to User model, not Employer model
            # First, check if there's a related User for this employer
            avg_rating = 0
            # This might need adjustment based on your rating logic
        except:
            avg_rating = 0
        
        # Build profile picture URL
        profile_picture_url = None
        if profile.profile_picture:
            profile_picture_url = request.build_absolute_uri(profile.profile_picture.url)
        
        # Build response data
        profile_data = {
            'employer_id': employer.employer_id,
            'username': employer.username,
            'contact_email': employer.contact_email,
            'phone_number': employer.phone_number,
            'full_name': profile.full_name,
            'profile_picture': profile_picture_url,
            'address': profile.address,
            'city': profile.city,
            'profession': profile.profession,
            'skills': profile.skills,
            'bio': profile.bio,
            'linkedin_url': profile.linkedin_url,
            'twitter_url': profile.twitter_url,
            'created_at': profile.created_at.strftime('%Y-%m-%d') if profile.created_at else None,
            
            # Additional profile fields
            'alternate_phone': profile.alternate_phone,
            'email_verified': profile.email_verified,
            'phone_verified': profile.phone_verified,
            'id_verified': profile.id_verified,
            'verification_status': profile.verification_status,
            'id_number': profile.id_number,
            
            # Statistics
            'total_tasks': total_tasks,
            'total_spent': float(total_spent),
            'avg_freelancer_rating': float(profile.avg_freelancer_rating),
            'total_projects_posted': profile.total_projects_posted,
        }
        
        return Response({
            'success': True,
            'profile': profile_data
        })
        
    except Employer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Employer not found'
        }, status=404)
    except Exception as e:
        print(f"Error in get_employer_profile: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response({
            'success': False,
            'message': f'Server error: {str(e)}'
        }, status=500)

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def generate_task_otp(request, task_id):
    """Generate OTP for onsite task verification"""
    try:
        task = Task.objects.get(task_id=task_id)
        
        # Check if user is authorized (employer or assigned freelancer)
        user = request.user
        
        is_employer = hasattr(user, 'employer') and user.employer == task.employer
        is_assigned_freelancer = task.assigned_user == user
        
        if not (is_employer or is_assigned_freelancer):
            return Response({
                "success": False,
                "message": "Not authorized to generate OTP for this task"
            }, status=403)
        
        # Check if task is onsite
        if task.service_type != 'on_site':
            return Response({
                "success": False,
                "message": "OTP only available for onsite tasks"
            }, status=400)
        
        # Generate OTP
        otp_code = task.generate_otp()
        
        # In production, send via SMS/Email
        print(f"DEBUG: OTP for task {task_id}: {otp_code}")
        
        return Response({
            "success": True,
            "message": "OTP generated successfully",
            "task_id": task.task_id,
            "task_title": task.title,
            "location": task.location_address,
            "note": "Share this OTP with the worker to verify task completion"
        })
        
    except Task.DoesNotExist:
        return Response({
            "success": False,
            "message": "Task not found"
        }, status=404)
    except Exception as e:
        return Response({
            "success": False,
            "message": f"Error: {str(e)}"
        }, status=500)
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_work_otp(request):
    """
    Verify OTP for onsite payment release.
    Called by freelancer after receiving OTP from client in person.
    If OTP matches, contract is marked as completed and Paystack transfer is triggered.
    """
    try:
        # Get OTP and contract_id from request
        otp_code = request.data.get('otp_code', '').strip()
        contract_id = request.data.get('contract_id')
        
        if not otp_code:
            return Response({
                "success": False,
                "message": "OTP code is required"
            }, status=400)
        
        if not contract_id:
            return Response({
                "success": False,
                "message": "Contract ID is required"
            }, status=400)
        
        # Get contract
        try:
            contract = Contract.objects.get(contract_id=contract_id)
        except Contract.DoesNotExist:
            return Response({
                "success": False,
                "message": "Contract not found"
            }, status=404)
        
        # Verify freelancer is authorized
        if contract.freelancer != request.user:
            return Response({
                "success": False,
                "message": "You are not authorized to verify this contract"
            }, status=403)
        
        # Verify contract is in pending_verification status
        if contract.status != 'pending_verification':
            return Response({
                "success": False,
                "message": f"Contract is not in pending verification status. Current status: {contract.status}"
            }, status=400)
        
        # Verify OTP matches
        if not contract.verification_otp or str(contract.verification_otp) != str(otp_code):
            return Response({
                "success": False,
                "message": "Invalid OTP code. Please verify the code with the client."
            }, status=400)
        
        # Check if OTP is expired (24 hours)
        if contract.otp_generated_at:
            time_diff = timezone.now() - contract.otp_generated_at
            if time_diff.total_seconds() > 86400:  # 24 hours
                return Response({
                    "success": False,
                    "message": "OTP has expired. Please contact the client to generate a new one."
                }, status=400)
        
        # All checks passed - Use atomic transaction to update all records and trigger transfer
        with transaction.atomic():
            # Update Contract status to completed
            contract.status = 'completed'
            contract.is_completed = True
            contract.is_active = True
            contract.completed_date = timezone.now()
            contract.save()
            
            # Update Task status
            task = contract.task
            if task:
                task.status = 'completed'
                task.payment_status = 'released'
                task.save()
            
            # Get order and freelancer for Paystack transfer
            order = Order.objects.filter(task=task, status='paid').first()
            if not order:
                return Response({
                    "success": False,
                    "message": "Order not found for this contract"
                }, status=404)
            
            # Get freelancer profile
            try:
                freelancer_profile = Freelancer.objects.get(user=contract.freelancer)
            except Freelancer.DoesNotExist:
                return Response({
                    "success": False,
                    "message": "Freelancer profile not found"
                }, status=404)
            
            # Check if freelancer has Paystack setup (subaccount or recipient code)
            # First check for recipient code in UserProfile
            recipient_code = None
            try:
                user_profile = UserProfile.objects.get(user=contract.freelancer)
                recipient_code = user_profile.paystack_recipient_code if hasattr(user_profile, 'paystack_recipient_code') else None
            except UserProfile.DoesNotExist:
                pass
            
            # If no recipient code, check if we have bank details to create one
            if not recipient_code:
                if freelancer_profile.bank_code and freelancer_profile.account_number:
                    # Create transfer recipient
                    paystack_service = PaystackService()
                    recipient_data = {
                        'type': 'nuban',
                        'name': freelancer_profile.account_name or freelancer_profile.business_name or contract.freelancer.name,
                        'account_number': freelancer_profile.account_number,
                        'bank_code': freelancer_profile.bank_code,
                        'currency': 'KES'
                    }
                    recipient_response = paystack_service.create_transfer_recipient(recipient_data)
                    
                    if recipient_response and recipient_response.get('status'):
                        recipient_code = recipient_response.get('data', {}).get('recipient_code')
                        # Save recipient code for future use
                        try:
                            user_profile, _ = UserProfile.objects.get_or_create(user=contract.freelancer)
                            user_profile.paystack_recipient_code = recipient_code
                            user_profile.save()
                        except Exception as e:
                            print(f"⚠️ Error saving recipient code: {e}")
                elif freelancer_profile.paystack_subaccount_code:
                    # If we have subaccount code, we might be able to use it directly
                    # But Paystack transfers typically need recipient codes
                    recipient_code = freelancer_profile.paystack_subaccount_code
                    # Try to use it, but it may not work
                    print(f"⚠️ Using subaccount code as recipient: {recipient_code}")
            
            if not recipient_code:
                return Response({
                    "success": False,
                    "message": "Freelancer has not set up bank details or Paystack account. Please complete payment setup first."
                }, status=400)
            
            # Calculate freelancer share (90% of order amount, 10% platform fee)
            total_amount_cents = int(float(order.amount) * 100)
            platform_fee_cents = int(total_amount_cents * 0.10)
            freelancer_share_cents = total_amount_cents - platform_fee_cents
            
            # Trigger Paystack transfer to freelancer
            paystack_service = PaystackService()
            transfer_response = paystack_service.transfer_to_subaccount(
                amount_cents=freelancer_share_cents,
                recipient=recipient_code,
                reason=f"Payment release for onsite task: {task.title if task else 'Task'}"
            )
            
            # Check transfer response
            if not transfer_response or not transfer_response.get('status'):
                # Transfer failed, but contract is already marked as completed
                # Log the error and notify admin
                error_message = transfer_response.get('message', 'Unknown error') if transfer_response else 'No response from Paystack'
                print(f"⚠️ Paystack transfer failed for contract {contract_id}: {error_message}")
                
                # Update freelancer pending payout (for manual processing)
                freelancer_profile.pending_payout += Decimal(str(order.amount)) * Decimal('0.90')
                freelancer_profile.save()
                
                return Response({
                    "success": True,
                    "message": "OTP verified and contract completed. Payment transfer initiated but may need manual verification.",
                    "contract_id": contract.contract_id,
                    "task_id": task.task_id if task else None,
                    "transfer_status": "pending_verification",
                    "transfer_error": error_message
                })
            
            # Transfer successful
            # Update freelancer earnings
            freelancer_profile.total_earnings += Decimal(str(order.amount)) * Decimal('0.90')
            freelancer_profile.save()
            
            # Create Transaction record for the transfer
            try:
                Transaction.objects.create(
                    transaction_type='withdrawal',
                    freelancer=freelancer_profile,
                    contract=contract,
                    task=task,
                    amount=Decimal(str(order.amount)),
                    freelancer_share=Decimal(str(order.amount)) * Decimal('0.90'),
                    platform_fee=Decimal(str(order.amount)) * Decimal('0.10'),
                    status='completed',
                    paystack_transfer_code=transfer_response.get('data', {}).get('transfer_code', ''),
                    metadata=transfer_response,
                    notes=f"Onsite task payment release - OTP verified"
                )
            except Exception as e:
                print(f"⚠️ Error creating Transaction record: {e}")
            
            return Response({
                "success": True,
                "message": "OTP verified successfully! Payment has been released to your account.",
                "contract_id": contract.contract_id,
                "task_id": task.task_id if task else None,
                "amount_transferred": float(freelancer_share_cents / 100),
                "transfer_code": transfer_response.get('data', {}).get('transfer_code', ''),
                "status": "completed"
            })
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            "success": False,
            "message": f"Error verifying OTP: {str(e)}"
        }, status=500)

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def verify_task_otp(request, task_id):
    """Verify OTP for onsite task completion"""
    try:
        task = Task.objects.get(task_id=task_id)
        
        # Get OTP from request
        otp_code = request.data.get('otp_code', '').strip()
        
        if not otp_code:
            return Response({
                "success": False,
                "message": "OTP code is required"
            }, status=400)
        
        # Verify OTP
        is_valid, message = task.check_otp(otp_code)
        
        if is_valid:
            # ======= ADD THIS LOGIC FROM THE FIRST VIEW =======
            # 1. TRIGGER PAYSTACK SPLIT HERE
            # Since task.payment_status is now 'released', 
            # call your existing Paystack function to move money 
            # from escrow to the worker's wallet/bank.
            
            # 2. Create a TaskCompletion record for the history
            TaskCompletion.objects.create(
                user=task.assigned_user,
                task=task,
                amount=task.budget,
                status='approved',
                paid=True,
                payment_date=timezone.now()
            )
            # ==================================================
            
            return Response({
                "success": True,
                "message": "Task verified successfully! Payment released.",
                "task_id": task.task_id,
                "task_title": task.title,
                "verified_at": task.onsite_verified_at,
                "status": task.status,
                "payment_status": task.payment_status
            })
        else:
            return Response({
                "success": False,
                "message": message,
                "attempts_remaining": 5 - task.verification_attempts
            }, status=400)
        
    except Task.DoesNotExist:
        return Response({
            "success": False,
            "message": "Task not found"
        }, status=404)
    except Exception as e:
        return Response({
            "success": False,
            "message": f"Error: {str(e)}"
        }, status=500)