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

        # =======================
        # AUTHENTICATION
        # =======================
        auth = CustomTokenAuthentication()
        auth_result = auth.authenticate(request)

        if auth_result is None:
            print(" AUTHENTICATION FAILED")
            return JsonResponse(
                {"error": "Authentication failed"},
                status=401
            )

        request.user, request.auth = auth_result

        print(f" USER AUTHENTICATED: {request.user}")

        # =======================
        # INPUT DATA
        # =======================
        task_id = request.POST.get("task_id")
        bid_amount = request.POST.get("bid_amount")
        cover_letter_file = request.FILES.get("cover_letter_file")

        if not task_id:
            return JsonResponse(
                {"error": "Task ID is required"},
                status=400
            )

        if not cover_letter_file:
            return JsonResponse(
                {"error": "Cover letter PDF file is required"},
                status=400
            )

        # =======================
        # FETCH TASK
        # =======================
        try:
            task = Task.objects.get(pk=task_id)
            print(f" TASK FOUND: {task.title}")
        except Task.DoesNotExist:
            return JsonResponse(
                {"error": "Task not found"},
                status=404
            )

        # =======================
        #  TASK LOCK CHECK
        # =======================
        if task.status != 'open' or not task.is_active or task.assigned_user is not None:
            return JsonResponse(
                {"error": "This task has already been taken"},
                status=400
            )

        # =======================
        # DUPLICATE PROPOSAL CHECK
        # =======================
        if Proposal.objects.filter(task=task, freelancer=request.user).exists():
            return JsonResponse(
                {"error": "You have already submitted a proposal for this task"},
                status=400
            )

        # =======================
        # CREATE PROPOSAL
        # =======================
        proposal = Proposal.objects.create(
            task=task,
            freelancer=request.user,
            bid_amount=float(bid_amount) if bid_amount else 0.0,
            submitted_at=timezone.now()
        )

        # =======================
        # SAVE FILE
        # =======================
        proposal.cover_letter_file.save(
            cover_letter_file.name,
            cover_letter_file
        )

        proposal.save()

        print(f" PROPOSAL CREATED: {proposal.proposal_id}")

        # =======================
        # RESPONSE
        # =======================
        return JsonResponse({
            "id": proposal.proposal_id,
            "task_id": task.task_id,
            "freelancer_id": request.user.id,
            "bid_amount": float(proposal.bid_amount),
            "status": proposal.status,
            "task_title": task.title,
            "message": "Proposal submitted successfully"
        }, status=201)

    except Exception as e:
        print(f" ERROR: {str(e)}")
        import traceback
        print(traceback.format_exc())

        return JsonResponse(
            {"error": "Internal server error"},
            status=500
        )
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
                'status': task.status,  # 👈 MUST INCLUDE THIS
                'assigned_user': task.assigned_user.id if task.assigned_user else None,
                'created_at': task.created_at.isoformat() if task.created_at else None,
                'completed': False,
                'employer': {
                    'id': task.employer.employer_id,
                    'username': task.employer.user.username,  # Note: Changed from task.employer.username
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
    
    # Check if user is a freelancer
    if not hasattr(request.user, 'freelancer'):
        return Response(
            {"error": "Only freelancers can create submissions"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    try:
        # Get task ID from request data
        task_id = request.data.get('task')
        
        if not task_id:
            return Response(
                {"error": "Task ID is required. Send 'task' field with task ID."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get task
        task = get_object_or_404(Task, id=task_id)
        
        # Get contract for this task and freelancer
        try:
            contract = Contract.objects.get(task=task, freelancer=request.user)
        except Contract.DoesNotExist:
            return Response(
                {"error": "You are not assigned to this task or contract doesn't exist."}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Validate required fields from Flutter
        if not request.data.get('title'):
            return Response(
                {"error": "Title is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not request.data.get('description'):
            return Response(
                {"error": "Description is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        
        serializer = SubmissionCreateSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                # Save submission with automatic freelancer and contract assignment
                submission = serializer.save()
                
                # Ensure submission has correct relationships
                if submission.freelancer != request.user:
                    submission.freelancer = request.user
                    submission.save()
                
                if submission.contract != contract:
                    submission.contract = contract
                    submission.save()
                
                # Create or update TaskCompletion
                completion, created = TaskCompletion.objects.get_or_create(
                    user=request.user,
                    task=task,
                    defaults={
                        'submission': submission, 
                        'amount': task.budget,
                        'status': 'pending_review',
                        'completed_at': timezone.now()
                    }
                )
                
                if not created:
                    completion.submission = submission
                    completion.status = 'pending_review'
                    completion.completed_at = timezone.now()
                    completion.save()
                
                # Update task status if needed
                if task.status != 'in_progress':
                    task.status = 'in_progress'
                    task.save()
            
            # Return full submission details using main serializer
            full_serializer = SubmissionSerializer(
                submission, 
                context={'request': request}
            )
            
            return Response(
                {
                    "message": "Submission created successfully",
                    "submission_id": submission.submission_id,
                    "data": full_serializer.data
                },
                status=status.HTTP_201_CREATED
            )
        
        # Return validation errors
        return Response(
            {
                "error": "Validation failed",
                "details": serializer.errors
            }, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    except Exception as e:
        # Log the error for debugging
        print(f"Error creating submission: {str(e)}")
        return Response(
            {"error": f"Server error: {str(e)}"}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_submission_detail(request, submission_id):
    submission = get_object_or_404(Submission, submission_id=submission_id)
    
    
    user = request.user
    if not (user.is_staff or submission.freelancer == user or submission.contract.employer.user == user):
        return Response(
            {"error": "You don't have permission to view this submission"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    serializer = SubmissionSerializer(submission)
    return Response(serializer.data)

@api_view(['GET'])

def get_my_submissions(request):
   
    if not hasattr(request.user, 'freelancer'):
        return Response(
            {"error": "Only freelancers can view their submissions"}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    submissions = Submission.objects.filter(freelancer=request.user).order_by('-submitted_at')
    serializer = SubmissionSerializer(submissions, many=True)
    return Response(serializer.data)

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
    try:
        # Get the proposal
        proposal = get_object_or_404(Proposal, proposal_id=proposal_id)
        task = proposal.task

        # Authorization check
        if request.user != task.employer.user:
            return Response({"error": "Unauthorized - Only task employer can accept proposals"}, status=403)

        # CRITICAL: Prevent double acceptance
        if task.status != 'open':
            return Response({
                "error": "Task already assigned",
                "current_status": task.status,
                "assigned_to": task.assigned_user.id if task.assigned_user else None
            }, status=400)

        # CRITICAL: Check if task is already locked
        if task.assigned_user is not None:
            return Response({
                "error": "Task already assigned to another freelancer",
                "assigned_freelancer_id": task.assigned_user.id
            }, status=400)

        print(f" Accepting proposal {proposal_id} for task {task.task_id}")

        # 1. Accept this proposal
        proposal.status = 'accepted'
        proposal.save()

        # 2. Reject all other proposals for this task
        Proposal.objects.filter(task=task).exclude(proposal_id=proposal.proposal_id)\
            .update(status='rejected')

        # 3. CRITICAL: Lock the task
        task.assigned_user = proposal.freelancer
        task.status = 'in_progress'  # Change from 'open' to 'in_progress'
        task.is_active = False  # No longer available
        task.save()

        print(f" Task {task.task_id} locked. Assigned to: {proposal.freelancer.id}")

        # 4. Create contract
        contract = Contract.objects.create(
            task=task,
            freelancer=proposal.freelancer,
            employer=task.employer,
            employer_accepted=True
        )

        print(f" Contract created: {contract.contract_id}")

        # 5. Send notification to freelancer (optional but recommended)
        # You can implement this later

        return Response({
            "message": "Proposal accepted and task locked successfully",
            "task_id": task.task_id,
            "task_status": task.status,
            "assigned_freelancer_id": proposal.freelancer.id,
            "contract_id": contract.contract_id,
            "task_locked": True
        })

    except Exception as e:
        print(f" Error in accept_proposal: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return Response({"error": f"Internal server error: {str(e)}"}, status=500)
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
        