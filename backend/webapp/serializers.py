from django.utils import timezone  
from rest_framework import serializers 
from rest_framework import serializers
from .models import Order, Submission, TaskCompletion, Rating, Contract, Task
from .models import Contract, Proposal, TaskCompletion, Transaction, User, UserProfile, Wallet
from .models import Employer, User
from .models import Task


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = "__all__"


class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

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
        ]
        read_only_fields = ("user",)

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

class TaskSerializer(serializers.ModelSerializer):
    is_taken = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            'task_id',
            'title',
            'description',
            'budget',
            'status',
            'assigned_user',
            'is_taken',
            'created_at'
        ]

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







class ProposalSerializer(serializers.ModelSerializer):
    task = TaskSerializer(read_only=True)  
    freelancer = UserSerializer(read_only=True) 

    class Meta:
        model = Proposal
        fields = [
            'proposal_id',
            'task',
            'freelancer',
            'cover_letter',
            'bid_amount',
            'submitted_at'
        ]
        read_only_fields = ['proposal_id', 'submitted_at']

class ContractSerializer(serializers.ModelSerializer):
    task_title = serializers.CharField(source="task.title", read_only=True)
    freelancer_name = serializers.CharField(source="freelancer.username", read_only=True)
    employer_name = serializers.CharField(source="employer.username", read_only=True)

    class Meta:
        model = Contract
        fields = [
            "contract_id",
            "task_title",
            "freelancer_name",
            "employer_name",
            "start_date",
            "end_date",
            "is_active",
        ]        
        
from .models import Employer, EmployerProfile
class EmployerLoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField()



class EmployerProfileSerializer(serializers.ModelSerializer):
    display_name = serializers.CharField(source='get_display_name', read_only=True)
    is_fully_verified = serializers.BooleanField(source='is_fully_verified', read_only=True)
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
            'id_document',
            'country',
            'city',
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
from rest_framework import serializers
from .models import Employer, EmployerProfile

class EmployerProfileSerializer(serializers.ModelSerializer):
    """Serializer for reading employer profile details"""
    class Meta:
        model = EmployerProfile
        fields = '__all__'
        read_only_fields = ['employer', 'created_at', 'updated_at']
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
        """Preprocess Twitter/X URL - FIXED for x.com"""
        if not value or value.strip() == '':
            return ''
        
        value = value.strip()
        print(f"Validating Twitter URL: '{value}'")  # Debug log
        
        # If empty after stripping, return empty
        if value == '':
            return ''
        
        # Handle @username format
        if value.startswith('@'):
            return f'https://x.com/{value[1:]}'
        
        # Handle x.com without protocol
        if value.startswith('x.com/'):
            return f'https://{value}'
        
        # Handle twitter.com without protocol
        if value.startswith('twitter.com/'):
            return f'https://x.com/{value[12:]}'  # Convert twitter.com to x.com
        
        # If it's just a username (no dots, no slashes)
        if '.' not in value and '/' not in value:
            return f'https://x.com/{value}'
        
        # If it has a dot but no protocol, add https://
        if '.' in value and not value.startswith(('http://', 'https://')):
            return f'https://{value}'
        
        # If it already has http:// or https://, ensure twitter.com is converted to x.com
        if value.startswith(('http://', 'https://')):
            if 'twitter.com/' in value:
                # Replace twitter.com with x.com
                if value.startswith('http://twitter.com/'):
                    return value.replace('http://twitter.com/', 'https://x.com/')
                elif value.startswith('https://twitter.com/'):
                    return value.replace('https://twitter.com/', 'https://x.com/')
        
        return value
    
    def validate(self, data):
        """Additional validation"""
        # Validate ID number length
        id_number = data.get('id_number', '')
        if id_number and len(id_number.strip()) < 5:
            raise serializers.ValidationError({
                'id_number': 'ID number is too short. Minimum 5 characters required.'
            })
        
        # Optional: Validate URLs after preprocessing
        from django.core.validators import URLValidator
        from django.core.exceptions import ValidationError
        
        validator = URLValidator()
        
        # Validate LinkedIn URL if present
        linkedin_url = data.get('linkedin_url', '')
        if linkedin_url:
            try:
                validator(linkedin_url)
            except ValidationError:
                # Try to fix common issues
                if linkedin_url.startswith('linkedin.com/'):
                    linkedin_url = f'https://{linkedin_url}'
                    try:
                        validator(linkedin_url)
                        data['linkedin_url'] = linkedin_url
                    except ValidationError:
                        raise serializers.ValidationError({
                            'linkedin_url': 'Please enter a valid LinkedIn URL.'
                        })
        
        # Validate Twitter URL if present
        twitter_url = data.get('twitter_url', '')
        if twitter_url:
            try:
                validator(twitter_url)
            except ValidationError as e:
                print(f"Twitter URL validation failed: {e}")
                # Don't raise error - we're being permissive with Twitter URLs
                # Just ensure it's at least a string that can be stored
        
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

class EmployerRegisterSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=255)
    password = serializers.CharField(max_length=128)
    contact_email = serializers.EmailField()
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)

   
# In your serializers.py
class TaskCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            'employer', 'title', 'description', 'category', 
            'budget', 'deadline', 'required_skills', 'is_urgent'
        ]
        read_only_fields = ['employer']  

class TaskSerializer(serializers.ModelSerializer):
    employer_name = serializers.CharField(source='employer.company_name', read_only=True)
    employer_id = serializers.IntegerField(source='employer.employer_id', read_only=True)
    
    class Meta:
        model = Task
        fields = [
            'task_id', 'employer', 'employer_id', 'employer_name', 'title', 'description', 
            'category', 'budget', 'deadline', 'required_skills', 
            'is_urgent', 'status', 'is_approved', 'is_active',
            'assigned_user', 'created_at'
        ]
        read_only_fields = ['task_id', 'status', 'is_approved', 'is_active', 'assigned_user', 'created_at']       

   

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
        freelancer = self.context.get('freelancer')  # This is User object
        contract = self.context.get('contract')
        
        print(f"Context - Task ID: {task.task_id if task else None}")
        print(f"Context - Freelancer User ID: {freelancer.user_id if freelancer else None}")
        print(f"Context - Freelancer Name: {freelancer.name if freelancer else None}")
        print(f"Context - Contract ID: {contract.contract_id if contract else None}")
        
        if not task:
            raise serializers.ValidationError({"task": "Task is required"})
        if not freelancer:
            raise serializers.ValidationError({"freelancer": "Freelancer is required"})
        if not contract:
            raise serializers.ValidationError({"contract": "Contract is required"})
        
        try:
            print(f"Creating submission with task={task.task_id}, freelancer={freelancer.user_id}, contract={contract.contract_id}")
            
            # Create submission
            submission = Submission.objects.create(
                task=task,
                freelancer=freelancer,  # User object
                contract=contract,
                **validated_data
            )
            
            print(f"✓ Submission created: ID={submission.submission_id}")
            print(f"✓ Submission status: {submission.status}")
            print(f"✓ Submission submitted_at: {submission.submitted_at}")
            
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

class RatingSerializer(serializers.ModelSerializer):
    rater_name = serializers.CharField(source='rater.get_full_name', read_only=True)
    rated_user_name = serializers.CharField(source='rated_user.get_full_name', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    
    class Meta:
        model = Rating
        fields = [
            'rating_id', 'task', 'task_title', 'submission', 'rater', 'rater_name',
            'rated_user', 'rated_user_name', 'rating_type', 'score', 'review',
            'created_at'
        ]
        read_only_fields = ['rating_id', 'created_at', 'rating_type']
    
    def validate(self, data):
       
        if data['rater'] == data['rated_user']:
            raise serializers.ValidationError("You cannot rate yourself.")
        
       
        task = data['task']
        if not TaskCompletion.objects.filter(task=task, status='approved').exists():
            raise serializers.ValidationError("You can only rate completed tasks.")
        
        return data

class SimpleSubmissionSerializer(serializers.ModelSerializer):
   
    freelancer_name = serializers.CharField(source='freelancer.get_full_name', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    
    class Meta:
        model = Submission
        fields = [
            'submission_id', 'task', 'task_title', 'freelancer_name', 'title',
            'status', 'submitted_at', 'staging_url', 'repo_url'
        ]        
        
class OrderSerializer(serializers.ModelSerializer):
    freelancer_name = serializers.CharField(source='service.freelancer.user.get_full_name', read_only=True)
    service_title = serializers.CharField(source='service.title', read_only=True)
    
    class Meta:
        model = Order
        fields = ['order_id', 'client', 'service', 'amount', 'status', 'created_at', 'freelancer_name', 'service_title']        
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
    # For read operations (GET) - these fields are read-only
    task_id = serializers.IntegerField(source='task.task_id', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    freelancer_id = serializers.IntegerField(source='freelancer.user_id', read_only=True)
    freelancer_name = serializers.CharField(source='freelancer.name', read_only=True)
    employer_name = serializers.CharField(source='task.employer.username', read_only=True)
    
    # For write operations (POST) - these accept IDs
    task = serializers.PrimaryKeyRelatedField(
        queryset=Task.objects.all(), 
        write_only=True,
        help_text="Task ID (not task_id field)"
    )
    
    # File handling
    cover_letter_file = serializers.FileField(
        required=True,
        write_only=True,
        help_text="PDF cover letter file"
    )
    
    # For API responses
    cover_letter_file_url = serializers.SerializerMethodField(read_only=True)
    
    class Meta:
        model = Proposal
        fields = [
            'proposal_id', 'task', 'task_id', 'task_title',
            'freelancer_id', 'freelancer_name', 'employer_name',
            'cover_letter_file', 'cover_letter_file_url',
            'bid_amount', 'cover_letter', 'status',
            'estimated_days', 'submitted_at'
        ]
        read_only_fields = ['proposal_id', 'submitted_at', 'freelancer']
    
    def get_cover_letter_file_url(self, obj):
        if obj.cover_letter_file:
            return obj.cover_letter_file.url
        return None
    
    def validate_bid_amount(self, value):
        """Ensure bid amount is positive"""
        if value <= 0:
            raise serializers.ValidationError("Bid amount must be positive")
        return value
    
    def validate(self, data):
        """Custom validation for the entire proposal"""
        task = data.get('task')
        request = self.context.get('request')
        
        # Check task is open and active
        if task.status != 'open':
            raise serializers.ValidationError(
                f"Task '{task.title}' is not open (status: {task.status})"
            )
        
        if not task.is_active:
            raise serializers.ValidationError(
                f"Task '{task.title}' is not active"
            )
        
        if task.assigned_user is not None:
            raise serializers.ValidationError(
                f"Task '{task.title}' is already assigned"
            )
        
        # Check for duplicate proposal
        if request and request.user:
            existing = Proposal.objects.filter(
                task=task, 
                freelancer=request.user
            ).exists()
            
            if existing:
                raise serializers.ValidationError(
                    "You have already submitted a proposal for this task"
                )
        
        return data
    
    def create(self, validated_data):
        """Create proposal with the authenticated user as freelancer"""
        request = self.context.get('request')
        
        # Extract file separately
        cover_letter_file = validated_data.pop('cover_letter_file', None)
        
        # Create proposal
        proposal = Proposal.objects.create(
            **validated_data,
            freelancer=request.user,  # Set from authenticated user
            submitted_at=timezone.now()
        )
        
        # Save file if provided
        if cover_letter_file:
            proposal.cover_letter_file.save(
                cover_letter_file.name,
                cover_letter_file
            )
            proposal.save()
        
        return proposal    