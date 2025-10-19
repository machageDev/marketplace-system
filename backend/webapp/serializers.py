from datetime import timezone
from rest_framework import serializers 


from .models import Contract, Proposal, User, UserProfile
from .models import Employer, User
from .models import Task
from .models import EmployerRating, FreelancerRating

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



class EmployerRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployerRating
        fields = ['id', 'task', 'freelancer', 'employer', 'score', 'review', 'created_at']


class FreelancerRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = FreelancerRating
        fields = ['id', 'task', 'freelancer', 'employer', 'score', 'review', 'created_at']



class ProposalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Proposal
        fields = ['proposal_id', 'task', 'freelancer', 'cover_letter', 'bid_amount', 'submitted_at']
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
            employer.password = password  # You might want to hash this
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
            instance.password = password  # Hash password if needed
        
        instance.save()
        
        # Update or create profile
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
        read_only_fields = ['employer']  # Make employer read-only since we set it automatically

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

class FreelancerRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = FreelancerRating
        fields = '__all__'        