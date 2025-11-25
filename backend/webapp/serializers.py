from datetime import timezone
from rest_framework import serializers 
from rest_framework import serializers
from .models import Submission, TaskCompletion, Rating, Contract, Task
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
    class Meta:
        model = Task
        fields = '__all__'        




        
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



class SubmissionSerializer(serializers.ModelSerializer):
    freelancer_name = serializers.CharField(source='freelancer.get_full_name', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    employer_name = serializers.CharField(source='contract.employer.user.get_full_name', read_only=True)
    
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
        read_only_fields = ['submission_id', 'freelancer', 'contract', 'submitted_at', 'resubmitted_at']
    
    def validate(self, data):
        
        if not any([
            data.get('repo_url'),
            data.get('staging_url'), 
            data.get('live_demo_url'),
            data.get('apk_download_url'),
            data.get('zip_file')
        ]):
            raise serializers.ValidationError(
                "Please provide at least one of: repository URL, staging URL, live demo URL, APK download, or zip file."
            )
        return data

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
    """Simplified serializer for lists"""
    freelancer_name = serializers.CharField(source='freelancer.get_full_name', read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    
    class Meta:
        model = Submission
        fields = [
            'submission_id', 'task', 'task_title', 'freelancer_name', 'title',
            'status', 'submitted_at', 'staging_url', 'repo_url'
        ]        