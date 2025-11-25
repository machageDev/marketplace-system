from django.db import models
from django.contrib.auth.hashers import make_password, check_password
from django.utils import timezone
import uuid
from django.db import models

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
# models.py
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
class EmployerProfile(models.Model):
    employer = models.OneToOneField(  
        Employer, 
        on_delete=models.CASCADE, 
        related_name='profile',
        null=True,
        blank=True
    )
    company_name = models.CharField(max_length=255, blank=True, null=True)
    contact_email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='employer_profiles/', blank=True, null=True)

    def __str__(self):
        return self.company_name if self.company_name else self.contact_email
    
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


# Contract (when freelancer is hired)
class Contract(models.Model):
    contract_id = models.AutoField(primary_key=True)
    task = models.OneToOneField(Task, related_name="contract", on_delete=models.CASCADE)
    freelancer = models.ForeignKey(User, on_delete=models.CASCADE)
    employer = models.ForeignKey(Employer, on_delete=models.CASCADE)

    start_date = models.DateField(default=timezone.now)
    end_date = models.DateField(blank=True, null=True)

    employer_accepted = models.BooleanField(default=False)
    freelancer_accepted = models.BooleanField(default=False)

    is_active = models.BooleanField(default=False)

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
            self.save()


class Transaction(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    email = models.EmailField()
    reference = models.CharField(max_length=100, unique=True)
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.reference} - {self.amount}"


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
    
    # Files storage
    def submission_files_path(instance, filename):
        return f'submissions/task_{instance.task.id}/{filename}'
    
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


class Rating(models.Model):
    RATING_TYPES = [
        ('employer_to_freelancer', 'Employer to Freelancer'),
        ('freelancer_to_employer', 'Freelancer to Employer'),
    ]
    
    rating_id = models.AutoField(primary_key=True)
    task = models.ForeignKey(Task, on_delete=models.CASCADE)
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
        
        if hasattr(self.rater, 'employer') and hasattr(self.rated_user, 'freelancer'):
            self.rating_type = 'employer_to_freelancer'
        elif hasattr(self.rated_user, 'employer') and hasattr(self.rater, 'freelancer'):
            self.rating_type = 'freelancer_to_employer'
        super().save(*args, **kwargs)        