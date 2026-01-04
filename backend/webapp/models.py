from django.db import models
from django.contrib.auth.hashers import make_password, check_password
from django.utils import timezone
import uuid
from django.db import models

#freelancer (for workers)
class User(models.Model):
    user_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=100, default="Anonymous")
    email = models.EmailField(unique=True)
    phoneNo = models.CharField(max_length=13, null=True, blank=True)
    password = models.CharField(max_length=128, null=True, blank=True)
    wallet_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00) 

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password)

    def __str__(self):
        return self.name


class UserToken(models.Model):
    user = models.OneToOneField("User", on_delete=models.CASCADE)
    key = models.CharField(max_length=40, unique=True, default=uuid.uuid4)
    created = models.DateTimeField(auto_now_add=True)

# Employer (for clients)

class Employer(models.Model):
    employer_id = models.AutoField(primary_key=True)
    username = models.CharField(max_length=255)
    password = models.CharField(max_length=128, null=True, blank=True)
    contact_email = models.EmailField(unique=True)
    phone_number = models.CharField(unique=True, null=True, blank=True)

    def __str__(self):
        return self.username
class EmployerToken(models.Model):
    employer = models.OneToOneField(Employer, on_delete=models.CASCADE)
    key = models.UUIDField(default=uuid.uuid4, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
from django.db import models
from django.utils import timezone
from django.conf import settings

class EmployerProfile(models.Model):
    # User relationship
    employer = models.OneToOneField(
        'Employer', 
        on_delete=models.CASCADE, 
        related_name='profile',
        null=True,
        blank=True
    )
    
    # ============ BASIC INFO ============
    full_name = models.CharField(max_length=255, default='Not provided')
    profile_picture = models.ImageField(upload_to='employer_profiles/', blank=True, null=True)
    
    # ============ CONTACT INFO ============
    contact_email = models.EmailField(default='not-provided@example.com')
    phone_number = models.CharField(max_length=20, default='Not provided')
    alternate_phone = models.CharField(max_length=20, blank=True, null=True)
    
    # ============ EMAIL VERIFICATION ============
    email_verified = models.BooleanField(default=False)
    email_verification_token = models.CharField(max_length=100, blank=True, null=True)
    email_verified_at = models.DateTimeField(blank=True, null=True)
    
    # ============ PHONE VERIFICATION ============
    phone_verified = models.BooleanField(default=False)
    phone_verification_code = models.CharField(max_length=6, blank=True, null=True)
    phone_verification_sent_at = models.DateTimeField(blank=True, null=True)
    phone_verified_at = models.DateTimeField(blank=True, null=True)
    
    # ============ ID VERIFICATION (UPDATED: Uses ID number) ============
    id_verified = models.BooleanField(default=False)
    id_number = models.CharField(
        max_length=50, 
        blank=True, 
        null=True, 
        help_text="National ID, Passport or Driver's License number"
    )
    id_verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='verified_employers'
    )
    id_verified_at = models.DateTimeField(blank=True, null=True)
    
    # ============ LOCATION (COUNTRY FIELD REMOVED) ============
    city = models.CharField(max_length=100, default='Not provided')
    address = models.TextField(default='Not provided')
    
    # ============ PROFESSIONAL INFO ============
    profession = models.CharField(max_length=100, blank=True, null=True)
    skills = models.TextField(blank=True, null=True, help_text="Comma-separated list of skills")
    
    # ============ ABOUT/ BIO ============
    bio = models.TextField(blank=True, null=True, help_text="Tell about yourself and what services you need")
    
    # ============ SOCIAL MEDIA (Optional) ============
    linkedin_url = models.URLField(blank=True, null=True)
    twitter_url = models.URLField(blank=True, null=True)
    
    # ============ VERIFICATION STATUS ============
    verification_status = models.CharField(
        max_length=20,
        default='unverified',
        choices=[
            ('unverified', 'Unverified'),
            ('pending', 'Pending Review'),
            ('verified', 'Verified'),
            ('rejected', 'Rejected'),
        ]
    )
    
    # ============ STATS ============
    total_projects_posted = models.IntegerField(default=0)
    total_spent = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    avg_freelancer_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    
    # ============ PREFERENCES ============
    notification_preferences = models.JSONField(
        default=dict,
        help_text="User's notification preferences"
    )
    
    # ============ TIMESTAMPS ============
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # ============ HELPER METHODS ============
    def get_display_name(self):
        return self.full_name or f"User #{self.id}"
    
    def is_fully_verified(self):
        """Check if user is fully verified"""
        return (
            self.email_verified and 
            self.phone_verified and 
            self.id_verified and 
            self.verification_status == 'verified'
        )
    
    def get_verification_progress(self):
        """Get verification progress percentage"""
        steps_completed = 0
        total_steps = 3
        
        if self.email_verified:
            steps_completed += 1
        if self.phone_verified:
            steps_completed += 1
        if self.id_number:  # ID number provided (even if not verified yet)
            steps_completed += 1
        
        return int((steps_completed / total_steps) * 100)
    
    # ============ META ============
    class Meta:
        verbose_name = "Employer Profile"
        verbose_name_plural = "Employer Profiles"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['contact_email']),
            models.Index(fields=['phone_number']),
            models.Index(fields=['verification_status']),
        ]
    
    def __str__(self):
        return self.get_display_name()
    
class Task(models.Model):
    TASK_CATEGORIES = [
        ('web', 'Web Development'),
        ('mobile', 'Mobile Development'),
        ('design', 'Design'),
        ('writing', 'Content Writing'),
        ('marketing', 'Digital Marketing'),
        ('other', 'Other'),
    ]
    
    TASK_STATUS = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    task_id = models.AutoField(primary_key=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    
    
    category = models.CharField(max_length=50, choices=TASK_CATEGORIES, default='other')
    budget = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    deadline = models.DateField(null=True, blank=True)
    required_skills = models.CharField(max_length=255, blank=True)
    is_urgent = models.BooleanField(default=False)
    
    
    is_approved = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)  
    status = models.CharField(max_length=20, choices=TASK_STATUS, default='open')
    created_at = models.DateTimeField(auto_now_add=True)

    employer = models.ForeignKey(Employer, on_delete=models.CASCADE, related_name="tasks")
    assigned_user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return self.title
    
    @property
    def is_open(self):
        return self.status == 'open' and self.is_active
    
    @property
    def has_assigned_freelancer(self):
        return self.assigned_user is not None

class TaskCompletion(models.Model):
    completion_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    task = models.ForeignKey(Task, on_delete=models.CASCADE)
    submission = models.OneToOneField('Submission', on_delete=models.CASCADE, null=True, blank=True)  # ADD THIS LINE
    amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    completed_at = models.DateTimeField(auto_now_add=True)
    paid = models.BooleanField(default=False)
    
    STATUS_CHOICES = [
        ('pending_review', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending_review')
    
    employer_notes = models.TextField(blank=True, null=True)
    freelancer_notes = models.TextField(blank=True, null=True)
    
    payment_date = models.DateTimeField(blank=True, null=True)
    payment_reference = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"{self.user.username} - {self.task.title} - {'Paid' if self.paid else 'Unpaid'}"

    @property
    def is_approved(self):
        return self.status == 'approved'
    
    @property
    def is_pending(self):
        return self.status == 'pending_review'
    
    def mark_as_paid(self, reference=None):
        self.paid = True
        self.payment_date = timezone.now()
        if reference:
            self.payment_reference = reference
        self.save()
    
    def approve_completion(self, notes=None):
        self.status = 'approved'
        if notes:
            self.employer_notes = notes
        self.save()
    
    def reject_completion(self, notes=None):
        self.status = 'rejected'
        if notes:
            self.employer_notes = notes
        self.save()



class PayrollReport(models.Model):
    report_id = models.AutoField(primary_key=True)
    employer = models.ForeignKey(Employer, on_delete=models.CASCADE, related_name="payroll_reports")
    month = models.DateField()
    total_expense = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Payroll Report {self.month} by {self.employer.username}"


class UserProfile(models.Model):
    profile_id = models.AutoField(primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="worker_profile")
    bio = models.TextField(blank=True, null=True)
    skills = models.CharField(max_length=255, help_text="Comma-separated list of skills")
    experience = models.TextField(blank=True, null=True)
    portfolio_link = models.URLField(blank=True, null=True)
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    profile_picture = models.ImageField(upload_to="profile_pics/", null=True, blank=True)

    def average_rating(self):
        ratings = self.user.received_ratings.all()
        if ratings.exists():
            return sum(r.score for r in ratings) / ratings.count()
        return 0

    def __str__(self):
        return f"Profile of {self.user.name}"


class Proposal(models.Model):
    proposal_id = models.AutoField(primary_key=True)
    task = models.ForeignKey(Task, related_name="proposals", on_delete=models.CASCADE)
    freelancer = models.ForeignKey(User, related_name="proposals", on_delete=models.CASCADE)
    cover_letter_file = models.FileField(upload_to='cover_letters/', blank=True, null=True)
    bid_amount = models.DecimalField(max_digits=10, decimal_places=2)
    submitted_at = models.DateTimeField(default=timezone.now)
    
    
    status = models.CharField(
        max_length=20, 
        choices=[
            ('pending', 'Pending'),
            ('accepted', 'Accepted'),
            ('rejected', 'Rejected')
        ], 
        default='pending'
    )
    estimated_days = models.PositiveIntegerField(default=7)  
    cover_letter = models.TextField(blank=True, null=True)  

    def __str__(self):
        return f"{self.freelancer.name} -> {self.task.title}"

class Contract(models.Model):
    contract_id = models.AutoField(primary_key=True)
    task = models.OneToOneField(Task, related_name="contract", on_delete=models.CASCADE)
    freelancer = models.ForeignKey('User', on_delete=models.CASCADE)      
    employer = models.ForeignKey('Employer', on_delete=models.CASCADE) 

    start_date = models.DateField(default=timezone.now)
    end_date = models.DateField(blank=True, null=True)

    employer_accepted = models.BooleanField(default=False)
    freelancer_accepted = models.BooleanField(default=False)

    is_active = models.BooleanField(default=False)
    
    # ADD THESE FIELDS
    is_completed = models.BooleanField(default=False)
    is_paid = models.BooleanField(default=False)
    completed_date = models.DateTimeField(null=True, blank=True)
    payment_date = models.DateTimeField(null=True, blank=True)
    
    # Status choices
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    def __str__(self):
        return f"Contract for {self.task.title}"

    @property
    def is_fully_accepted(self):
        """Check if both employer and freelancer agreed."""
        return self.employer_accepted and self.freelancer_accepted

    def activate_contract(self):
        """Mark contract as active if both sides accepted."""
        if self.is_fully_accepted:
            self.is_active = True
            self.status = 'active'
            self.save()

    def mark_as_completed(self):
        """Mark contract as completed."""
        self.is_completed = True
        self.status = 'completed'
        self.completed_date = timezone.now()
        self.save()

    def mark_as_paid(self):
        """Mark contract as paid."""
        self.is_paid = True
        self.payment_date = timezone.now()
        self.save()
# models.py

# models.py - Update Transaction model
class Transaction(models.Model):
    transaction_id = models.AutoField(primary_key=True)
    
    # Add these fields if missing
    order = models.ForeignKey('Order', on_delete=models.CASCADE, null=True, blank=True)
    paystack_reference = models.CharField(max_length=100, unique=True)
    employer = models.ForeignKey('Employer', on_delete=models.CASCADE, null=True, blank=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'transactions'
    
    def __str__(self):
        return f"Transaction {self.transaction_id} - {self.paystack_reference}"

class PaymentRecord(models.Model):
    tx_ref = models.CharField(max_length=100, unique=True)
    client = models.ForeignKey(User, on_delete=models.CASCADE, related_name="client_payments")
    freelancer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="freelancer_payments")
    total_amount = models.FloatField()
    platform_fee = models.FloatField()
    freelancer_amount = models.FloatField()
    status = models.CharField(max_length=20, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.tx_ref} - {self.status}"
    
    
class Wallet(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="wallet")
    balance = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    updated_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.user.name}'s Wallet - Balance: {self.balance}"  


class Submission(models.Model):
    submission_id = models.AutoField(primary_key=True)
    task = models.ForeignKey(Task, on_delete=models.CASCADE)
    freelancer = models.ForeignKey(User, on_delete=models.CASCADE)
    contract = models.ForeignKey(Contract, on_delete=models.CASCADE)
    
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    submitted_at = models.DateTimeField(auto_now_add=True)
    
   
    repo_url = models.URLField(blank=True, null=True)
    commit_hash = models.CharField(max_length=100, blank=True, null=True)
    staging_url = models.URLField(blank=True, null=True)
    live_demo_url = models.URLField(blank=True, null=True)
    apk_download_url = models.URLField(blank=True, null=True)  
    testflight_link = models.URLField(blank=True, null=True)  
    
    
    admin_username = models.CharField(max_length=100, blank=True, null=True)
    admin_password = models.CharField(max_length=100, blank=True, null=True)
    access_instructions = models.TextField(blank=True, null=True)
    
    
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('revisions_requested', 'Revisions Requested'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    
    # FIXED: File storage path function
    def submission_files_path(instance, filename):
        
        # First try to use task_id directly (most reliable)
        if instance.task_id:
            return f'submissions/task_{instance.task_id}/{filename}'
        
        # If task_id is not set yet, check if task object has id
        elif instance.task and hasattr(instance.task, 'id') and instance.task.id:
            return f'submissions/task_{instance.task.id}/{filename}'
        
        # Fallback: use timestamp or unique ID for new submissions
        else:
            timestamp = timezone.now().strftime('%Y%m%d_%H%M%S_%f')[:-3]
            return f'submissions/temp_{timestamp}/{filename}'
    
    zip_file = models.FileField(upload_to=submission_files_path, blank=True, null=True)
    screenshots = models.FileField(upload_to=submission_files_path, blank=True, null=True)
    video_demo = models.FileField(upload_to=submission_files_path, blank=True, null=True)
    
    # Additional info
    deployment_instructions = models.TextField(blank=True, null=True)
    test_instructions = models.TextField(blank=True, null=True)
    release_notes = models.TextField(blank=True, null=True)
    
    # Acceptance checklist (freelancer self-verification)
    checklist_tests_passing = models.BooleanField(default=False)
    checklist_deployed_staging = models.BooleanField(default=False)
    checklist_documentation = models.BooleanField(default=False)
    checklist_no_critical_bugs = models.BooleanField(default=False)
    
    # Revision tracking
    revision_notes = models.TextField(blank=True, null=True)
    resubmitted_at = models.DateTimeField(blank=True, null=True)
    
    def __str__(self):
        return f"Submission for {self.task.title} by {self.freelancer.username}"
    
    @property
    def is_approved(self):
        return self.status == 'approved'
    
    @property
    def needs_revision(self):
        return self.status == 'revisions_requested'
    
    def approve(self):
        self.status = 'approved'
        self.save()
        
    def request_revision(self, notes):
        self.status = 'revisions_requested'
        self.revision_notes = notes
        self.save()
    
    def mark_under_review(self):
        self.status = 'under_review'
        self.save()
    
    
    def save(self, *args, **kwargs):
        # Ensure task_id is set if we have a task object
        if self.task and not self.task_id:
            self.task_id = self.task.id
        super().save(*args, **kwargs)  

class Rating(models.Model):
    RATING_TYPES = [
        ('employer_to_freelancer', 'Employer to Freelancer'),
        ('freelancer_to_employer', 'Freelancer to Employer'),
    ]
    
    rating_id = models.AutoField(primary_key=True)
    task = models.ForeignKey(Task, on_delete=models.CASCADE)
    contract = models.ForeignKey(Contract, on_delete=models.CASCADE, null=True, blank=True)  # ADD THIS
    submission = models.ForeignKey(Submission, on_delete=models.CASCADE, null=True, blank=True)
    rater = models.ForeignKey(User, related_name='ratings_given', on_delete=models.CASCADE)
    rated_user = models.ForeignKey(User, related_name='ratings_received', on_delete=models.CASCADE)
    rating_type = models.CharField(max_length=25, choices=RATING_TYPES)
    score = models.IntegerField(choices=[(i, i) for i in range(1, 6)])
    review = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['task', 'rater', 'rated_user']
    
    def __str__(self):
        return f"{self.rater.username} → {self.rated_user.username}: {self.score}/5"
    
    def save(self, *args, **kwargs):
        # Auto-set rating_type
        if hasattr(self.rater, 'employer') and hasattr(self.rated_user, 'freelancer'):
            self.rating_type = 'employer_to_freelancer'
        elif hasattr(self.rated_user, 'employer') and hasattr(self.rater, 'freelancer'):
            self.rating_type = 'freelancer_to_employer'
        super().save(*args, **kwargs)
# models.py - Add Notification model
class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('contract_completed', 'Contract Completed'),
        ('rating_received', 'Rating Received'),
        ('payment_received', 'Payment Received'),
        ('task_assigned', 'Task Assigned'),
    ]
    
    notification_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    related_id = models.IntegerField(null=True, blank=True)  # For linking to contract/task
    
    def __str__(self):
        return f"{self.title} - {self.user.username}"
    
    class Meta:
        ordering = ['-created_at']
class Freelancer(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    paystack_subaccount_code = models.CharField(max_length=100, blank=True, null=True)
    bank_account_number = models.CharField(max_length=20, blank=True, null=True)
    bank_name = models.CharField(max_length=100, blank=True, null=True)
    account_name = models.CharField(max_length=100, blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.user.username} - Freelancer"

class Client(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"{self.user.username} - Client"

class Service(models.Model):
    freelancer = models.ForeignKey(Freelancer, on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return self.title

class Order(models.Model):
    ORDER_STATUS = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    order_id = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    
    # ADD null=True temporarily
    employer = models.ForeignKey(Employer, on_delete=models.CASCADE, related_name='orders', null=True)
    
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='orders', null=True)
    
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='KSH')
    freelancer = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    status = models.CharField(max_length=20, choices=ORDER_STATUS, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class PaymentTransaction(models.Model):
    TRANSACTION_STATUS = [
        ('pending', 'Pending'),
        ('success', 'Success'),
        ('failed', 'Failed'),
    ]
    
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    paystack_reference = models.CharField(max_length=100, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    platform_commission = models.DecimalField(max_digits=10, decimal_places=2)  # 10%
    freelancer_share = models.DecimalField(max_digits=10, decimal_places=2)  # 90%
    status = models.CharField(max_length=20, choices=TRANSACTION_STATUS, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"TX-{self.paystack_reference}"