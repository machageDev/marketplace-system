from datetime import timezone
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
        
        return UserProfile.objects.create(**validated_data)

    def update(self, instance, validated_data):
        
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
    class Meta:
        model = EmployerProfile
        fields = [
            'company_name', 
            'contact_email', 
            'phone_number', 
            'profile_picture'
        ]
        extra_kwargs = {
            'profile_picture': {'required': False, 'allow_null': True}
        }

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

class EmployerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployerProfile
        fields = ['id', 'employer', 'company_name', 'contact_email', 'phone_number', 'profile_picture']    
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
    # Add all fields that Flutter is sending
    class Meta:
        model = Submission
        fields = [
            'title', 'description',
            'repo_url', 'commit_hash', 'staging_url', 'live_demo_url',
            'apk_download_url', 'testflight_link', 'admin_username',
            'admin_password', 'access_instructions', 'deployment_instructions',
            'test_instructions', 'release_notes', 'revision_notes',  # Make sure this matches
            'checklist_tests_passing', 'checklist_deployed_staging',
            'checklist_documentation', 'checklist_no_critical_bugs',
            'zip_file', 'screenshots', 'video_demo'
        ]
    
    def create(self, validated_data):
        # Get task, freelancer, and contract from context
        task = self.context.get('task')
        freelancer = self.context.get('freelancer')
        contract = self.context.get('contract')
        
        if not all([task, freelancer, contract]):
            raise serializers.ValidationError(
                "Missing required context: task, freelancer, or contract"
            )
        
        print(f"Creating submission with validated data keys: {validated_data.keys()}")
        print(f"Context - Task: {task}, Freelancer: {freelancer}, Contract: {contract}")
        
        # Create submission
        submission = Submission.objects.create(
            task=task,
            freelancer=freelancer,
            contract=contract,
            **validated_data
        )
        
        print(f"Submission created: {submission.id}")
        return submission

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