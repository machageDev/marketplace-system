from django.utils import timezone  
from rest_framework import serializers 
from rest_framework import serializers
from .models import Freelancer, Notification, Order, Submission, TaskCompletion, Rating, Contract, Task
from .models import Contract, Proposal, TaskCompletion, Transaction, User, UserProfile, Wallet
from .models import Employer, User
from .models import Task, Skill, UserSkill, PortfolioItem


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = "__all__"


class SkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = Skill
        fields = ['id', 'name', 'category', 'description']

class UserSkillSerializer(serializers.ModelSerializer):
    skill = SkillSerializer(read_only=True)
    badge_color = serializers.SerializerMethodField()
    
    class Meta:
        model = UserSkill
        fields = ['id', 'skill', 'verification_status', 'verification_evidence', 'date_verified', 'badge_color']
    
    def get_badge_color(self, obj):
        return obj.get_badge_color()

class PortfolioItemSerializer(serializers.ModelSerializer):
    skills_used = SkillSerializer(many=True, read_only=True)
    image = serializers.SerializerMethodField()
    
    class Meta:
        model = PortfolioItem
        fields = ['id', 'title', 'description', 'image', 'video_url', 'project_url', 
                  'client_quote', 'skills_used', 'completion_date', 'created_at']
    
    def get_image(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None

class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    verified_skills = serializers.SerializerMethodField()
    portfolio_items = serializers.SerializerMethodField()
    work_passport_data = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = [
            "user",
            "bio", 
            "skills",
            "experience",
            "portfolio_link", 
            "hourly_rate",
            "profile_picture",
            "verified_skills",
            "portfolio_items",
            "work_passport_data",
        ]
        read_only_fields = ("user",)
    
    def get_verified_skills(self, obj):
        user_skills = UserSkill.objects.filter(user=obj.user).select_related('skill')
        return UserSkillSerializer(user_skills, many=True).data
    
    def get_portfolio_items(self, obj):
        portfolio_items = PortfolioItem.objects.filter(user=obj.user).prefetch_related('skills_used')
        request = self.context.get('request')
        return PortfolioItemSerializer(portfolio_items, many=True, context={'request': request}).data
    
    def get_work_passport_data(self, obj):
        # Calculate work passport data from completed tasks
        from .models import TaskCompletion, Rating, UserSkill, Contract
        from django.utils import timezone
        from datetime import timedelta
        
        completed_tasks = TaskCompletion.objects.filter(user=obj.user, status='approved')
        total_earnings = sum(float(task.amount) for task in completed_tasks)
        
        ratings = Rating.objects.filter(rated_user=obj.user)
        avg_rating = 0
        review_count = ratings.count()
        if ratings.exists():
            avg_rating = sum(r.score for r in ratings) / review_count
        
        # Count verified skills (test_passed or verified status)
        verified_skills_count = UserSkill.objects.filter(
            user=obj.user,
            verification_status__in=['test_passed', 'verified']
        ).count()
        
        # Calculate platform tenure (days since first contract or task completion)
        platform_tenure_days = 0
        try:
            # Try to get earliest contract or task completion
            earliest_contract = Contract.objects.filter(freelancer=obj.user).order_by('start_date').first()
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
        
        return {
            "total_earnings": total_earnings,
            "completed_tasks": completed_tasks.count(),
            "avg_rating": round(avg_rating, 2),
            "review_count": review_count,
            "verified_skills_count": verified_skills_count,
            "platform_tenure_days": platform_tenure_days,
            "client_satisfaction_summary": satisfaction_summary
        }

    def create(self, validated_data):
        print(f"\n=== SERIALIZER CREATE ===")
        print(f"Validated data keys: {validated_data.keys()}")
        
        # Extract user from validated_data (it's already there from view)
        user = validated_data.get('user')
        if not user:
            raise serializers.ValidationError({"user": "User is required"})
        
        print(f"Creating profile for: {user.name}")
        
        # Check if profile already exists
        if hasattr(user, 'worker_profile'):
            raise serializers.ValidationError({"user": "User already has a profile"})
        
        # Create the profile
        return UserProfile.objects.create(**validated_data)

    def update(self, instance, validated_data):
        # Remove user if present (can't change user)
        validated_data.pop('user', None)
        
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class EmployerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Employer
        fields = '__all__'

from rest_framework import serializers
from .models import Task
from django.utils import timezone

class TaskCreateSerializer(serializers.ModelSerializer):
    # Allow 'YYYY-MM-DD' as well as full ISO datetime strings
    deadline = serializers.DateTimeField(
        required=False,
        allow_null=True,
        input_formats=[
            '%Y-%m-%d',                 # date-only
            '%Y-%m-%dT%H:%M:%S.%fZ',    # ISO with Z
            '%Y-%m-%dT%H:%M:%S.%f',     # ISO without Z
            '%Y-%m-%dT%H:%M:%S',        # ISO without fractional
        ]
    )

    class Meta:
        model = Task
        fields = [
            'employer', 'title', 'description', 'category', 'service_type', 'payment_type',
            'budget', 'deadline', 'required_skills', 'is_urgent', 'location_address',
            'latitude', 'longitude'
        ]
        read_only_fields = ['employer']

    def validate(self, data):
        # Ensure service_type values match the model choices
        st = data.get('service_type')
        loc = (data.get('location_address') or '').strip()

        # enforce allowed values to avoid typos like 'on-site' or 'onsite'
        if st not in ('remote', 'on_site'):
            raise serializers.ValidationError({'service_type': 'Invalid service_type. Use "remote" or "on_site".'})

        # if on_site, require a real location
        if st == 'on_site':
            if not loc:
                raise serializers.ValidationError({'location_address': 'location_address is required for on_site tasks.'})
            # optionally further checks: reject 'none', 'null', 'remote' etc.
            lower_loc = loc.lower()
            if lower_loc in ('none', 'null', 'no location provided', 'remote'):
                raise serializers.ValidationError({'location_address': 'Provide a valid physical location for on_site tasks.'})

        return data 

class TaskSerializer(serializers.ModelSerializer):
    is_taken = serializers.SerializerMethodField()
    service_type_display = serializers.CharField(source='get_service_type_display', read_only=True)
    employer_name = serializers.CharField(source='employer.username', read_only=True) # Changed to username to match model
    employer_id = serializers.IntegerField(source='employer.employer_id', read_only=True)

    class Meta:
        model = Task
        fields = [
            'task_id', 'employer', 'employer_id', 'employer_name', 'title', 'description', 'category',
            'service_type', 'service_type_display', 'payment_type', 
            'budget', 'location_address', 'latitude', 'longitude',
            'deadline', 'required_skills', 'is_urgent', 'status', 
            'payment_status', 'is_paid', 'assigned_user', 
            'is_taken', 'created_at', 'is_approved', 'is_active',
            'attachments' # Added attachments as it was in model
        ]
        read_only_fields = ['payment_status', 'is_paid', 'status', 'is_approved', 'is_active', 'created_at', 'task_id']

    def create(self, validated_data):
        # Create task object
        task = Task(**validated_data)
        task.save()
        return task

    def get_is_taken(self, obj):
        return obj.status != 'open' or obj.assigned_user is not None

        
class RegisterSerializer(serializers.ModelSerializer):
    
    phone_number = serializers.CharField(source='phoneNo', required=True)

    class Meta:
        model = User
        fields = ['name', 'email', 'phone_number','password', ]  
        extra_kwargs = {
            "password": {"write_only": True},  
        }


    def to_internal_value(self, data):
        
        if "phoneNo" in data and "phone_number" not in data:
            data["phone_number"] = data["phoneNo"]
        return super().to_internal_value(data)

        
class LoginSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['name','password']  


class ContractSerializer(serializers.ModelSerializer):
    task_title = serializers.CharField(source="task.title", read_only=True)
    freelancer_name = serializers.CharField(source="freelancer.get_full_name", read_only=True)
    employer_name = serializers.CharField(source="employer.user.get_full_name", read_only=True)
    can_complete = serializers.SerializerMethodField()
    completion_status = serializers.SerializerMethodField()
    order_id = serializers.SerializerMethodField()  # ✅ ADD THIS
    order_status = serializers.SerializerMethodField()  # ✅ ADD THIS
    
    class Meta:
        model = Contract
        fields = [
            "contract_id",
            "task",
            "task_title",
            "freelancer",
            "freelancer_name",
            "employer",
            "employer_name",
            "start_date",
            "end_date",
            "is_active",
            "is_completed",
            "is_paid",
            "status",
            "completed_date",
            "payment_date",
            "can_complete",
            "completion_status",
            "employer_accepted",
            "freelancer_accepted",
            "is_fully_accepted",
            "order_id",  # ✅ ADD THIS
            "order_status",  # ✅ ADD THIS
        ]
        read_only_fields = ["contract_id", "created_at"]
    
    def get_can_complete(self, obj):
        """Check if contract can be marked as completed"""
        return obj.is_paid and not obj.is_completed and obj.is_fully_accepted
    
    def get_completion_status(self, obj):
        """Get human-readable completion status"""
        if obj.is_completed:
            return 'Completed'
        elif obj.is_paid:
            return 'Paid - Ready for Completion'
        elif obj.is_fully_accepted:
            return 'Active - Awaiting Payment'
        else:
            return 'Pending Acceptance'
    
    # ✅ ADD THESE METHODS
    def get_order_id(self, obj):
        """Get the associated order ID for this contract"""
        try:
            # Find order linked to this contract's task and freelancer
            order = Order.objects.filter(
                task=obj.task,
                employer=obj.employer,
                freelancer__user=obj.freelancer,
                status='pending'
            ).first()
            
            if order:
                return str(order.order_id)
            
            # If no pending order, check for any order
            order = Order.objects.filter(
                task=obj.task,
                employer=obj.employer,
                freelancer__user=obj.freelancer
            ).first()
            
            return str(order.order_id) if order else None
            
        except Exception as e:
            print(f"Error getting order ID for contract {obj.contract_id}: {e}")
            return None
    
    def get_order_status(self, obj):
        """Get the status of the associated order"""
        try:
            order = Order.objects.filter(
                task=obj.task,
                employer=obj.employer,
                freelancer__user=obj.freelancer
            ).first()
            
            return order.status if order else None
            
        except Exception as e:
            print(f"Error getting order status for contract {obj.contract_id}: {e}")
            return None
class ContractCompletionSerializer(serializers.ModelSerializer):
    """Serializer for marking contract as completed"""
    class Meta:
        model = Contract
        fields = ['is_completed', 'completed_date', 'status']
        read_only_fields = ['completed_date', 'status']
    
    def update(self, instance, validated_data):
        # Only allow marking as completed, not un-completing
        if validated_data.get('is_completed'):
            instance.is_completed = True
            instance.status = 'completed'
            instance.completed_date = timezone.now()
            instance.save()
        return instance

class EmployerContractSerializer(serializers.ModelSerializer):
    """Serializer for employer to see their contracts"""
    task_details = serializers.SerializerMethodField()
    freelancer_details = serializers.SerializerMethodField()
    actions_available = serializers.SerializerMethodField()
    order_id = serializers.SerializerMethodField()  # ✅ ADD THIS
    payment_ready = serializers.SerializerMethodField()  # ✅ ADD THIS
    
    class Meta:
        model = Contract
        fields = [
            'contract_id',
            'task_details',
            'freelancer_details',
            'start_date',
            'status',
            'is_paid',
            'is_completed',
            'payment_date',
            'actions_available',
            'order_id',  # ✅ ADD THIS
            'payment_ready',  # ✅ ADD THIS
        ]
    
    def get_task_details(self, obj):
        return {
            'id': obj.task.id,
            'title': obj.task.title,
            'budget': obj.task.budget,
            'task_id': obj.task.task_id,  # ✅ Include task_id too
        }
    
    def get_freelancer_details(self, obj):
        return {
            'id': obj.freelancer.id,
            'name': obj.freelancer.get_full_name(),
            'email': obj.freelancer.email,
            'user_id': obj.freelancer.user_id,  # ✅ Include user_id
        }
    
    def get_actions_available(self, obj):
        """What actions can employer take on this contract"""
        actions = []
        
        if not obj.is_paid and obj.is_fully_accepted:
            actions.append('make_payment')
        
        if obj.is_paid and not obj.is_completed:
            actions.append('mark_completed')
        
        if not obj.is_completed:
            actions.append('view_submission')
        
        return actions
    
    # ✅ ADD THIS METHOD
    def get_order_id(self, obj):
        """Get the order ID for payment"""
        try:
            # Get the order for this contract
            order = Order.objects.filter(
                task=obj.task,
                employer=obj.employer,
                freelancer__user=obj.freelancer
            ).first()
            
            if order:
                return str(order.order_id)
            
            # If no order exists, check if we should create one
            if not obj.is_paid and obj.is_fully_accepted:
                # Create order on the fly
                from decimal import Decimal
                import uuid
                
                # Get freelancer instance
                freelancer = Freelancer.objects.filter(user=obj.freelancer).first()
                
                if freelancer:
                    order = Order.objects.create(
                        order_id=uuid.uuid4(),
                        employer=obj.employer,
                        task=obj.task,
                        freelancer=freelancer,
                        amount=Decimal(str(obj.task.budget or 0)),
                        currency='KSH',
                        status='pending'
                    )
                    return str(order.order_id)
            
            return None
            
        except Exception as e:
            print(f"Error getting order ID: {e}")
            return None
    
    # ✅ ADD THIS METHOD
    def get_payment_ready(self, obj):
        """Check if payment is ready to be made"""
        return not obj.is_paid and obj.is_fully_accepted and self.get_order_id(obj) is not None           
from .models import Employer, EmployerProfile
class EmployerLoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()


class EmployerProfileSerializer(serializers.ModelSerializer):
    display_name = serializers.CharField(source='get_display_name', read_only=True)
    password = serializers.CharField(write_only=True, required=False)
    is_fully_verified = serializers.BooleanField(read_only=True)  # FIXED: Removed source parameter
    verification_progress = serializers.IntegerField(source='get_verification_progress', read_only=True)
    
    class Meta:
        model = EmployerProfile
        fields = [
            'id',
            'employer',
            'full_name',
            'profile_picture',
            'contact_email',
            'phone_number',
            'alternate_phone',
            'email_verified',
            'phone_verified',
            'id_verified',
            'id_number',
            'city',           # FIXED: city instead of country
            'address',
            'profession',
            'skills',
            'bio',
            'linkedin_url',
            'twitter_url',
            'verification_status',
            'total_projects_posted',
            'total_spent',
            'avg_freelancer_rating',
            'notification_preferences',
            'created_at',
            'updated_at',
            'display_name',
            'is_fully_verified',
            'verification_progress',
            'password',       # FIXED: Added to fields list
        ]
        read_only_fields = [
            'id',
            'employer',
            'email_verified',
            'phone_verified',
            'id_verified',
            'id_verified_by',
            'id_verified_at',
            'verification_status',
            'total_projects_posted',
            'total_spent',
            'avg_freelancer_rating',
            'created_at',
            'updated_at',
            'display_name',
            'is_fully_verified',
            'verification_progress',
        ]
        extra_kwargs = {
            'password': {'write_only': True},
        }
    
    def validate_contact_email(self, value):
        """Ensure email is unique"""
        # Exclude current instance during updates
        if self.instance:
            if EmployerProfile.objects.filter(contact_email=value).exclude(id=self.instance.id).exists():
                raise serializers.ValidationError("This email is already registered.")
        else:
            if EmployerProfile.objects.filter(contact_email=value).exists():
                raise serializers.ValidationError("This email is already registered.")
        return value
    
    def validate_phone_number(self, value):
        """Basic phone number validation"""
        if not value:
            raise serializers.ValidationError("Phone number is required.")
        # Add more validation as needed
        return value
    
    # FIXED: Add create and update methods to handle password
    def create(self, validated_data):
        # Remove password from validated_data if present
        validated_data.pop('password', None)
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        # Remove password from validated_data if present
        validated_data.pop('password', None)
        return super().update(instance, validated_data)
class EmployerProfileCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating employer profile"""
    id_number = serializers.CharField(
        required=True,
        allow_blank=False,
        error_messages={
            'required': 'ID number is required.',
            'blank': 'ID number cannot be blank.'
        }
    )
    
    linkedin_url = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=200,
        error_messages={
            'max_length': 'LinkedIn URL is too long.'
        }
    )
    
    twitter_url = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=200,
        error_messages={
            'max_length': 'Twitter URL is too long.'
        }
    )
    
    class Meta:
        model = EmployerProfile
        fields = [
            'full_name',
            'profile_picture',
            'contact_email',
            'phone_number',
            'alternate_phone',
            'city',
            'address',
            'profession',
            'skills',
            'bio',
            'linkedin_url',
            'twitter_url',
            'notification_preferences',
            'id_number',
        ]
        extra_kwargs = {
            'full_name': {'required': True},
            'contact_email': {'required': True},
            'phone_number': {'required': True},
            'city': {'required': True},
            'address': {'required': True},
            'id_number': {'required': True},
        }
    
    def validate_linkedin_url(self, value):
        """Preprocess LinkedIn URL"""
        if not value or value.strip() == '':
            return ''
        
        value = value.strip()
        
        # If it's just a LinkedIn username without full URL
        if '/' not in value and not value.startswith(('http://', 'https://')):
            return f'https://linkedin.com/in/{value}'
        
        # Ensure it has a protocol
        if not value.startswith(('http://', 'https://')):
            return f'https://{value}'
        
        return value
    
    def validate_twitter_url(self, value):
        """Preprocess Twitter/X URL"""
        if not value or value.strip() == '':
            return ''
        
        value = value.strip()
        print(f"Processing Twitter URL: '{value}'")
        
        # Handle empty
        if value == '':
            return ''
        
        # Convert @username to x.com URL
        if value.startswith('@'):
            return f'https://x.com/{value[1:]}'
        
        # Ensure it starts with https://
        if not value.startswith(('http://', 'https://')):
            # If it's x.com or twitter.com, add https://
            if value.startswith(('x.com/', 'twitter.com/')):
                return f'https://{value}'
            # Otherwise assume username
            return f'https://x.com/{value}'
        
        # Convert twitter.com to x.com if needed
        if 'twitter.com/' in value:
            value = value.replace('twitter.com/', 'x.com/')
        
        # Return as is - NO STRICT VALIDATION
        return value
    
    def validate(self, data):
        """Additional validation"""
        # Validate ID number length
        id_number = data.get('id_number', '')
        if id_number and len(id_number.strip()) < 5:
            raise serializers.ValidationError({
                'id_number': 'ID number is too short. Minimum 5 characters required.'
            })
        
        return data
    
    def create(self, validated_data):
        """Create employer profile - using employer from context"""
        try:
            # Get employer from context (passed by view)
            employer = self.context.get('employer')
            
            if not employer:
                raise serializers.ValidationError({
                    'detail': 'No employer provided in context.'
                })
            
            # Check if profile already exists
            if EmployerProfile.objects.filter(employer=employer).exists():
                raise serializers.ValidationError({
                    'detail': 'Profile already exists for this employer. Use update instead.'
                })
            
            # Add employer to validated data
            validated_data['employer'] = employer
            
            # Create the profile
            return super().create(validated_data)
            
        except serializers.ValidationError:
            # Re-raise validation errors
            raise
        except Exception as e:
            # Log the error for debugging
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error creating employer profile: {str(e)}")
            raise serializers.ValidationError({
                'detail': f'Failed to create profile: {str(e)}'
            })
class EmployerProfileUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating employer profile"""
    linkedin_url = serializers.URLField(
        required=False,
        allow_blank=True,
        error_messages={
            'invalid': 'Enter a valid LinkedIn URL.'
        }
    )
    
    twitter_url = serializers.URLField(
        required=False,
        allow_blank=True,
        error_messages={
            'invalid': 'Enter a valid Twitter URL.'
        }
    )
    
    class Meta:
        model = EmployerProfile
        fields = [
            'full_name',
            'profile_picture',
            'phone_number',
            'alternate_phone',
            'city',
            'address',
            'profession',
            'skills',
            'bio',
            'linkedin_url',
            'twitter_url',
            'notification_preferences',
        ]
        extra_kwargs = {
            'full_name': {'required': False},
            'phone_number': {'required': False},
            'city': {'required': False},
            'address': {'required': False},
        }
    
    def validate_linkedin_url(self, value):
        """Preprocess LinkedIn URL"""
        if not value or value.strip() == '':
            return ''
        
        value = value.strip()
        
        if not value.startswith(('http://', 'https://')):
            return f'https://{value}'
        
        return value
    
    def validate_twitter_url(self, value):
        """Preprocess Twitter/X URL"""
        if not value or value.strip() == '':
            return ''
        
        value = value.strip()
        
        # Handle various Twitter URL formats
        if value.startswith('@'):
            return f'https://x.com/{value[1:]}'
        
        if not value.startswith(('http://', 'https://')):
            # Check if it looks like a domain
            if '.' in value:
                return f'https://{value}'
            else:
                # Assume it's a username
                return f'https://x.com/{value}'
        
        return value                

class EmployerSerializer(serializers.ModelSerializer):
    profile = EmployerProfileSerializer(required=False)
    
    class Meta:
        model = Employer
        fields = [
            'employer_id',
            'username', 
            'password', 
            'contact_email', 
            'phone_number',
            'profile'
        ]
        extra_kwargs = {
            'password': {'write_only': True},
            'employer_id': {'read_only': True}
        }
    
    def create(self, validated_data):
        profile_data = validated_data.pop('profile', None)
        password = validated_data.pop('password', None)
        
        employer = Employer.objects.create(**validated_data)
        
        if password:
            employer.password = password 
            employer.save()
        
        if profile_data:
            EmployerProfile.objects.create(employer=employer, **profile_data)
        
        return employer
    
    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', None)
        password = validated_data.pop('password', None)
        
        # Update employer fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        if password:
            instance.password = password 
        
        instance.save()
        
        if profile_data:
            profile, created = EmployerProfile.objects.get_or_create(
                employer=instance,
                defaults=profile_data
            )
            if not created:
                for attr, value in profile_data.items():
                    setattr(profile, attr, value)
                profile.save()
        
        return instance 
class IDNumberUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating ID number"""
    class Meta:
        model = EmployerProfile
        fields = ['id_number']
        extra_kwargs = {
            'id_number': {
                'required': True,
                'allow_null': False,
                'allow_blank': False,
                'error_messages': {
                    'required': 'ID number is required.',
                    'blank': 'ID number cannot be blank.'
                }
            }
        }
    
    def validate_id_number(self, value):
        """Validate ID number format"""
        if not value or value.strip() == '':
            raise serializers.ValidationError("ID number cannot be empty.")
        
        # Add ID number length validation (adjust for your country)
        if len(value) < 5:
            raise serializers.ValidationError("ID number seems too short.")
        
        # Check for duplicates (optional - remove if not needed)
        if self.instance:
            if EmployerProfile.objects.filter(id_number=value).exclude(id=self.instance.id).exists():
                raise serializers.ValidationError("This ID number is already registered.")
        
        return value.strip()

class EmployerRegisterSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=255)
    password = serializers.CharField(max_length=128)
    contact_email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
   

class WalletSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wallet
        fields = ['id', 'balance', 'updated_at']        

class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = '__all__'        

# In your serializers.py file - REPLACE JUST THE SubmissionSerializer class

class SubmissionSerializer(serializers.ModelSerializer):
    freelancer_name = serializers.CharField(source='freelancer.get_full_name', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    employer_name = serializers.CharField(source='contract.employer.user.get_full_name', read_only=True)
    
    # ADD THESE: Explicitly define file fields for proper handling
    zip_file = serializers.FileField(required=False, allow_null=True)
    screenshots = serializers.FileField(required=False, allow_null=True)
    video_demo = serializers.FileField(required=False, allow_null=True)
    
    class Meta:
        model = Submission
        fields = [
            'submission_id', 'task', 'contract', 'freelancer', 'freelancer_name',
            'title', 'description', 'submitted_at', 'repo_url', 'commit_hash',
            'staging_url', 'live_demo_url', 'apk_download_url', 'testflight_link',
            'admin_username', 'admin_password', 'access_instructions', 'status',
            'zip_file', 'screenshots', 'video_demo', 'deployment_instructions',
            'test_instructions', 'release_notes', 'checklist_tests_passing',
            'checklist_deployed_staging', 'checklist_documentation',
            'checklist_no_critical_bugs', 'revision_notes', 'resubmitted_at',
            'task_title', 'employer_name'
        ]
        read_only_fields = [
            'submission_id', 'freelancer', 'contract', 
            'submitted_at', 'resubmitted_at', 'status'  # Added status as read_only
        ]
        # ADD THIS: Define required fields explicitly
        extra_kwargs = {
            'title': {'required': True, 'allow_blank': False},
            'description': {'required': True, 'allow_blank': False},
            'task': {'required': True}
        }
    
    def validate(self, data):
        """
        Enhanced validation to match Flutter's submission format
        """
        request = self.context.get('request')
        
        # Check for at least ONE submission method
        # Consider both data dict and request.FILES
        has_url = any([
            data.get('repo_url'),
            data.get('staging_url'), 
            data.get('live_demo_url'),
            data.get('apk_download_url'),
            data.get('testflight_link')
        ])
        
        # Check for files in both data dict and request
        has_file_in_data = any([
            data.get('zip_file'),
            data.get('screenshots'),
            data.get('video_demo')
        ])
        
        has_file_in_request = False
        if request and hasattr(request, 'FILES'):
            has_file_in_request = any([
                request.FILES.get('zip_file'),
                request.FILES.get('screenshots'),
                request.FILES.get('video_demo')
            ])
        
        if not (has_url or has_file_in_data or has_file_in_request):
            raise serializers.ValidationError({
                "submission_method": "Please provide at least one submission method: "
                "repository URL, staging URL, live demo URL, APK download, TestFlight link, "
                "or uploaded file (zip, screenshots, video)."
            })
        
        # Validate that task exists (if provided as ID)
        task_value = data.get('task')
        if task_value:
            # Handle if task is provided as ID (from Flutter)
            if isinstance(task_value, int):
                try:
                    task = Task.objects.get(id=task_value)
                    data['task'] = task  # Replace ID with Task instance
                except Task.DoesNotExist:
                    raise serializers.ValidationError({
                        "task": "Task does not exist."
                    })
        
        # Validate checklist fields are boolean
        checklist_fields = [
            'checklist_tests_passing',
            'checklist_deployed_staging',
            'checklist_documentation',
            'checklist_no_critical_bugs'
        ]
        
        for field in checklist_fields:
            if field in data and not isinstance(data[field], bool):
                raise serializers.ValidationError({
                    field: f"{field.replace('_', ' ').title()} must be true or false."
                })
        
        # Validate URLs if provided
        url_fields = [
            'repo_url', 'staging_url', 'live_demo_url',
            'apk_download_url', 'testflight_link'
        ]
        
        for field in url_fields:
            value = data.get(field)
            if value and value != '':
                if not (value.startswith('http://') or value.startswith('https://')):
                    raise serializers.ValidationError({
                        field: "URL must start with http:// or https://"
                    })
        
        return data
    
    def create(self, validated_data):
        """
        Custom create to handle file uploads and set relationships
        """
        request = self.context.get('request')
        
        # Handle files from request.FILES if not in validated_data
        if request and hasattr(request, 'FILES'):
            if 'zip_file' not in validated_data and 'zip_file' in request.FILES:
                validated_data['zip_file'] = request.FILES['zip_file']
            if 'screenshots' not in validated_data and 'screenshots' in request.FILES:
                validated_data['screenshots'] = request.FILES['screenshots']
            if 'video_demo' not in validated_data and 'video_demo' in request.FILES:
                validated_data['video_demo'] = request.FILES['video_demo']
        
        # Set freelancer from request user
        if 'freelancer' not in validated_data and request and request.user:
            validated_data['freelancer'] = request.user
        
        # Set contract automatically based on task and freelancer
        if 'contract' not in validated_data:
            task = validated_data.get('task')
            freelancer = validated_data.get('freelancer')
            
            if task and freelancer:
                try:
                    contract = Contract.objects.get(
                        task=task,
                        freelancer=freelancer
                    )
                    validated_data['contract'] = contract
                except Contract.DoesNotExist:
                    # If no contract exists, create one
                    # You might need to adjust this based on your business logic
                    employer = task.employer if hasattr(task, 'employer') else None
                    if employer:
                        contract = Contract.objects.create(
                            task=task,
                            freelancer=freelancer,
                            employer=employer,
                            start_date=timezone.now(),
                            is_active=True
                        )
                        validated_data['contract'] = contract
        
        # Create the submission
        submission = Submission.objects.create(**validated_data)
        
        return submission
    
    def to_representation(self, instance):
        """
        Customize the response format
        """
        representation = super().to_representation(instance)
        
        # Add full URLs for files
        request = self.context.get('request')
        
        if request:
            if instance.zip_file:
                representation['zip_file_url'] = request.build_absolute_uri(
                    instance.zip_file.url
                )
            if instance.screenshots:
                representation['screenshots_url'] = request.build_absolute_uri(
                    instance.screenshots.url
                )
            if instance.video_demo:
                representation['video_demo_url'] = request.build_absolute_uri(
                    instance.video_demo.url
                )
        
        # Add checklist summary
        checklist_complete = all([
            instance.checklist_tests_passing,
            instance.checklist_deployed_staging,
            instance.checklist_documentation,
            instance.checklist_no_critical_bugs
        ])
        representation['checklist_complete'] = checklist_complete
        
        return representation

class SubmissionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Submission
        fields = [
            'title', 'description',
            'repo_url', 'commit_hash', 'staging_url', 'live_demo_url',
            'apk_download_url', 'testflight_link', 'admin_username',
            'admin_password', 'access_instructions', 'deployment_instructions',
            'test_instructions', 'release_notes', 'revision_notes',
            'checklist_tests_passing', 'checklist_deployed_staging',
            'checklist_documentation', 'checklist_no_critical_bugs',
            'zip_file', 'screenshots', 'video_demo'
        ]
        extra_kwargs = {
            'title': {'required': True},
            'description': {'required': True},
            # All other fields are optional
            'repo_url': {'required': False, 'allow_blank': True},
            'commit_hash': {'required': False, 'allow_blank': True},
            'staging_url': {'required': False, 'allow_blank': True},
            'live_demo_url': {'required': False, 'allow_blank': True},
            'apk_download_url': {'required': False, 'allow_blank': True},
            'testflight_link': {'required': False, 'allow_blank': True},
            'admin_username': {'required': False, 'allow_blank': True},
            'admin_password': {'required': False, 'allow_blank': True},
            'access_instructions': {'required': False, 'allow_blank': True},
            'deployment_instructions': {'required': False, 'allow_blank': True},
            'test_instructions': {'required': False, 'allow_blank': True},
            'release_notes': {'required': False, 'allow_blank': True},
            'revision_notes': {'required': False, 'allow_blank': True},
            'checklist_tests_passing': {'required': False},
            'checklist_deployed_staging': {'required': False},
            'checklist_documentation': {'required': False},
            'checklist_no_critical_bugs': {'required': False},
            'zip_file': {'required': False},
            'screenshots': {'required': False},
            'video_demo': {'required': False},
        }
    
    def create(self, validated_data):
        print(f"\n=== SERIALIZER CREATE ===")
        
        # Get task, freelancer, and contract from context
        task = self.context.get('task')
        freelancer = self.context.get('freelancer')
        contract = self.context.get('contract')
        is_resubmission = self.context.get('is_resubmission', False)
        
        print(f"Context - Task ID: {task.task_id if task else None}")
        print(f"Context - Freelancer User ID: {freelancer.user_id if freelancer else None}")
        print(f"Context - Contract ID: {contract.contract_id if contract else None}")
        print(f"Context - Is Resubmission: {is_resubmission}")
        
        if not task:
            raise serializers.ValidationError({"task": "Task is required"})
        if not freelancer:
            raise serializers.ValidationError({"freelancer": "Freelancer is required"})
        if not contract:
            raise serializers.ValidationError({"contract": "Contract is required"})
        
        try:
            print(f"Creating submission with task={task.task_id}, freelancer={freelancer.user_id}, contract={contract.contract_id}")
            
            # Determine submission status
            if is_resubmission:
                status = 'resubmitted'
                print(f"Setting status to 'resubmitted' for revision")
            else:
                status = 'submitted'
                print(f"Setting status to 'submitted' for new submission")
            
            # Create submission
            submission = Submission.objects.create(
                task=task,
                freelancer=freelancer,
                contract=contract,
                status=status,  # Set the status explicitly
                **validated_data
            )
            
            print(f"✓ Submission created: ID={submission.submission_id}")
            print(f"✓ Submission status: {submission.status}")
            print(f"✓ Submission submitted_at: {submission.submitted_at}")
            
            # ✅ CRITICAL: Update Task status to 'submitted'
            # This is what makes it show up in the employer's rating UI
            if not is_resubmission or task.status != 'submitted':
                print(f"Updating Task {task.task_id} status from '{task.status}' to 'submitted'")
                task.status = 'submitted'
                task.save()
                print(f"✓ Task status updated to 'submitted'")
            else:
                print(f"Task already in 'submitted' status, no update needed")
            
            return submission
            
        except Exception as e:
            print(f"✗ Error creating submission: {e}")
            import traceback
            print(f"Create traceback: {traceback.format_exc()}")
            raise serializers.ValidationError({"detail": f"Error creating submission: {str(e)}"})

class TaskCompletionSerializer(serializers.ModelSerializer):
    submission_details = SubmissionSerializer(source='submission', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    
    class Meta:
        model = TaskCompletion
        fields = [
            'completion_id', 'user', 'user_name', 'task', 'task_title', 'submission',
            'submission_details', 'amount', 'completed_at', 'paid', 'status',
            'employer_notes', 'freelancer_notes', 'payment_date', 'payment_reference'
        ]
        read_only_fields = ['completion_id', 'completed_at', 'payment_date']
import json
from rest_framework import serializers
from .models import Rating, Contract

import json
from rest_framework import serializers
from .models import Rating, Contract
import json
from rest_framework import serializers
from .models import Rating, Contract

import json
from rest_framework import serializers
from .models import Rating, Contract, Employer, User, EmployerProfile

class RatingSerializer(serializers.ModelSerializer):
    """
    Handles name resolution by checking Employer, User, and Profile models.
    """
    rater_name = serializers.SerializerMethodField()
    rated_user_name = serializers.SerializerMethodField()
    task_title = serializers.CharField(source='task.title', read_only=True)
    contract = serializers.PrimaryKeyRelatedField(queryset=Contract.objects.all(), required=False)
    can_rate = serializers.SerializerMethodField(read_only=True)
    details = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Rating
        fields = [
            'rating_id', 'task', 'contract', 'task_title', 
            'rater', 'rater_name', 'rated_user', 'rated_user_name',
            'rating_type', 'score', 'review', 'created_at', 'can_rate',
            'details'
        ]
        read_only_fields = ['rating_id', 'created_at', 'rating_type', 'can_rate']

    def get_rater_name(self, obj):
        try:
            # 1. Identify the rater object (Employer or User)
            # Your Rating model likely has a ForeignKey to either Employer or User
            rater_obj = getattr(obj, 'rater_employer', None) or getattr(obj, 'rater', None)
            
            if not rater_obj:
                return "Client"

            # 2. Check if it's an Employer instance (from your shared models)
            if isinstance(rater_obj, Employer):
                # Try to get the name from the linked EmployerProfile
                if hasattr(rater_obj, 'profile') and rater_obj.profile:
                    p_name = rater_obj.profile.full_name
                    if p_name and p_name != 'Not provided':
                        return p_name
                # Fallback to the Employer's username
                return rater_obj.username

            # 3. Check if it's a User instance (Freelancer)
            if isinstance(rater_obj, User):
                # Your User model has a 'name' field
                return rater_obj.name if rater_obj.name else "Freelancer"

            return "Anonymous"
        except Exception as e:
            print(f"DEBUG: get_rater_name error: {e}")
            return "Anonymous"

    def get_rated_user_name(self, obj):
        try:
            user = obj.rated_user
            if user:
                # Use the 'name' field from your User model
                return user.name if user.name else "User"
            return "User"
        except Exception:
            return "User"

    def get_details(self, obj):
        """Extracts the JSON blob hidden in the review text"""
        if obj.review and "__EXTENDED_DATA__:" in obj.review:
            try:
                parts = obj.review.split("__EXTENDED_DATA__:")
                if len(parts) > 1:
                    return json.loads(parts[1])
            except:
                return None
        return None

    def to_representation(self, instance):
        """Clean the review text for the UI response"""
        data = super().to_representation(instance)
        review = data.get('review')
        if review and "__EXTENDED_DATA__:" in review:
            data['review'] = review.split("__EXTENDED_DATA__:")[0].strip()
        return data

    def get_can_rate(self, obj):
        try:
            if not obj.contract: return False
            # Matching the field names in your Contract model
            return (obj.contract.is_completed and obj.contract.is_paid)
        except:
            return False
# serializers.py - Add this
class CreateRatingSerializer(serializers.ModelSerializer):
    rated_user = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        required=True,
        error_messages={
            'required': 'rated_user is required.',
            'does_not_exist': 'The user you are trying to rate does not exist.'
        }
    )
    
    class Meta:
        model = Rating
        fields = [
            'task', 'contract', 'rater', 'rated_user',
            'rating_type', 'score', 'review'
        ]
        read_only_fields = ['rater', 'rating_type']
    
    def validate(self, data):
        # Ensure rated_user is not the same as rater
        if data['rated_user'] == self.context['request'].user:
            raise serializers.ValidationError({
                'rated_user': 'You cannot rate yourself.'
            })
        return data        
class EmployerRatingSerializer(serializers.ModelSerializer):
    employer_name = serializers.CharField(source='rater.name', read_only=True)
    freelancer_name = serializers.CharField(source='rated_user.name', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    contract = serializers.PrimaryKeyRelatedField(
        queryset=Contract.objects.all(), 
        required=True
    )
    
    class Meta:
        model = Rating
        fields = [
            'rating_id', 'task', 'contract', 'submission', 'task_title',
            'rater', 'employer_name', 'rated_user', 'freelancer_name',
            'score', 'review', 'created_at', 'rating_type'
        ]
        read_only_fields = ['rating_id', 'created_at', 'rating_type', 'submission']
    
    def validate(self, data):
        request = self.context.get('request')
        task = data.get('task')
        rated_user = data.get('rated_user')
        contract = data.get('contract')
        
        # Check required fields
        if not task:
            raise serializers.ValidationError({"task": "Task is required"})
        
        if not rated_user:
            raise serializers.ValidationError({"rated_user": "Freelancer is required"})
        
        if not contract:
            raise serializers.ValidationError({"contract": "Contract is required"})
        
        # Verify contract belongs to this task and freelancer
        if contract.task != task or contract.freelancer != rated_user:
            raise serializers.ValidationError({
                "contract": "Contract does not match the task and freelancer"
            })
        
        # Check if task belongs to the employer
        if request and hasattr(request.user, 'employer_id'):
            employer = request.user
            if task.employer != employer:
                raise serializers.ValidationError({
                    "task": "You can only rate freelancers on your own tasks"
                })
        
        # Check if task is in submitted status
        if task.status != 'submitted':
            raise serializers.ValidationError({
                "task": f"Task must be in 'submitted' status. Current status: {task.status}"
            })
        
        return data
    
    def create(self, validated_data):
        # Get request context
        request = self.context.get('request')
        
        # Get the submission for this task and freelancer
        submission = Submission.objects.filter(
            task=validated_data['task'],
            freelancer=validated_data['rated_user']
        ).first()
        
        if submission:
            validated_data['submission'] = submission
        
        # Create the rating
        rating = super().create(validated_data)
        
        # Update task status to 'completed'
        task = rating.task
        task.status = 'completed'
        task.save()
        
        # Update submission status to 'accepted'
        if submission:
            submission.status = 'accepted'
            submission.save()
        
        return rating
class SimpleSubmissionSerializer(serializers.ModelSerializer):
   
    freelancer_name = serializers.CharField(source='freelancer.get_full_name', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    
    class Meta:
        model = Submission
        fields = [
            'submission_id', 'task', 'task_title', 'freelancer_name', 'title',
            'status', 'submitted_at', 'staging_url', 'repo_url'
        ]        
class NotificationSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'notification_id',
            'user',
            'user_name',
            'title',
            'message',
            'notification_type',
            'is_read',
            'created_at',
            'time_ago',
            'related_id'
        ]
        read_only_fields = ['notification_id', 'created_at']
    
    def get_time_ago(self, obj):
        from django.utils import timezone
        from django.utils.timesince import timesince
        
        now = timezone.now()
        if obj.created_at:
            return timesince(obj.created_at, now) + ' ago'
        return ''        
class OrderSerializer(serializers.ModelSerializer):
    # Change these lines - your current ones might be wrong
    freelancer_name = serializers.SerializerMethodField()
    service_title = serializers.SerializerMethodField()
    task_title = serializers.SerializerMethodField()
    employer_name = serializers.SerializerMethodField()
    contract_id = serializers.SerializerMethodField()
    
    class Meta:
        model = Order
        fields = [
            'order_id', 
            'employer', 
            'task', 
            'freelancer', 
            'amount', 
            'currency',
            'status', 
            'created_at', 
            'freelancer_name',
            'task_title',
            'employer_name',
            'contract_id',
        ]
    
    def get_freelancer_name(self, obj):
        if obj.freelancer and obj.freelancer.user:
            return obj.freelancer.user.name
        return None
    
    def get_task_title(self, obj):
        if obj.task:
            return obj.task.title
        return None
    
    def get_employer_name(self, obj):
        if obj.employer:
            return obj.employer.username
        return None
    
    def get_contract_id(self, obj):
        """Get contract ID for this order"""
        if obj.task and obj.employer and obj.freelancer:
            try:
                contract = Contract.objects.filter(
                    task=obj.task,
                    employer=obj.employer,
                    freelancer=obj.freelancer.user
                ).first()
                
                return contract.contract_id if contract else None
            except:
                return None
        return None
class PaymentInitializeSerializer(serializers.Serializer):
    order_id = serializers.CharField(max_length=50)
    email = serializers.EmailField()
    
    def validate_order_id(self, value):
        try:
            Order.objects.get(order_id=value)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Order does not exist")
        return value

class PaymentVerificationSerializer(serializers.Serializer):
    reference = serializers.CharField(max_length=100)        
    
class ProposalSerializer(serializers.ModelSerializer):
    # --- READ ONLY FIELDS (GET) ---
    task_id = serializers.IntegerField(source='task.task_id', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    freelancer_id = serializers.IntegerField(source='freelancer.user_id', read_only=True)
    freelancer_name = serializers.CharField(source='freelancer.name', read_only=True)
    employer_name = serializers.CharField(source='task.employer.username', read_only=True)
    
    # CRITICAL FIX: Pull the UUID order_id for the Flutter Payment flow
    order_id = serializers.SerializerMethodField(read_only=True)
    
    # MOCK FIELD: Pulls the fixed budget from the Task model 
    bid_amount = serializers.ReadOnlyField(source='task.budget')
    
    # --- WRITE ONLY FIELDS (POST) ---
    task = serializers.PrimaryKeyRelatedField(
        queryset=Task.objects.all(), 
        write_only=True,
        help_text="Task ID"
    )
    
    cover_letter_file = serializers.FileField(
        required=True,
        write_only=True,
        help_text="PDF cover letter file"
    )
    
    cover_letter_file_url = serializers.SerializerMethodField(read_only=True)
    
    class Meta:
        model = Proposal
        fields = [
            'proposal_id', 'task', 'task_id', 'task_title',
            'freelancer_id', 'freelancer_name', 'employer_name',
            'cover_letter_file', 'cover_letter_file_url',
            'bid_amount', 'order_id', # <--- UUID included here
            'cover_letter', 'status',
            'estimated_days', 'submitted_at'
        ]
        read_only_fields = ['proposal_id', 'submitted_at', 'freelancer']

    def get_order_id(self, obj):
        """
        Retrieves the UUID from the Order table.
        This allows the 'Pay Now' button to work by using the UUID string
        instead of the integer proposal_id.
        """
        # Look for a pending or paid order associated with this specific task
        order = Order.objects.filter(task=obj.task).first()
        if order:
            return str(order.order_id) # Returns the UUID (e.g., 5ec282ed...)
        return None

    def get_cover_letter_file_url(self, obj):
        if obj.cover_letter_file:
            return obj.cover_letter_file.url
        return None
    
    def validate(self, data):
        task = data.get('task')
        request = self.context.get('request')
        
        if task.status != 'open':
            raise serializers.ValidationError(f"Task '{task.title}' is not open")
        
        if not task.is_active:
            raise serializers.ValidationError(f"Task '{task.title}' is not active")
        
        if task.assigned_user is not None:
            raise serializers.ValidationError(f"Task '{task.title}' is already assigned")
        
        if request and request.user:
            existing = Proposal.objects.filter(task=task, freelancer=request.user).exists()
            if existing:
                raise serializers.ValidationError("You have already submitted a proposal")
        
        return data
    
    def create(self, validated_data):
        request = self.context.get('request')
        cover_letter_file = validated_data.pop('cover_letter_file', None)
        
        proposal = Proposal.objects.create(
            **validated_data,
            freelancer=request.user,
            submitted_at=timezone.now()
        )
        
        if cover_letter_file:
            proposal.cover_letter_file.save(cover_letter_file.name, cover_letter_file)
            proposal.save()
        
        return proposal