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
from .models import Contract, Employer, EmployerProfile, EmployerRating, FreelancerRating, Proposal, Task, UserProfile
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
from webapp.serializers import ContractSerializer, EmployerRatingSerializer, LoginSerializer, RegisterSerializer, TaskSerializer, UserProfileSerializer
from .authentication import CustomTokenAuthentication
from .permissions import IsAuthenticated  
from .models import UserProfile
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
    """Temporary endpoint to test authentication"""
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
    """
    GET: List all employer ratings
    POST: Create a new employer rating
    """
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
    """
    GET: Get specific employer rating
    PUT: Update employer rating
    DELETE: Delete employer rating
    """
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
    """
    GET: Get all ratings submitted by the current employer
    """
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
    """
    GET: Get all ratings for a specific freelancer
    """
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
            "task_id": proposal.task.id,
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

import stripe
from django.conf import settings
from django.http import JsonResponse

stripe.api_key = settings.STRIPE_SECRET_KEY

def create_payment_intent(request):
    data = json.loads(request.body)
    amount = data.get("amount")  # in cents
    currency = "usd"

    intent = stripe.PaymentIntent.create(
        amount=amount,
        currency=currency,
        automatic_payment_methods={"enabled": True},
    )

    return JsonResponse({
        "clientSecret": intent.client_secret
    })
