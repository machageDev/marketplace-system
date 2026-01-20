from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import *

if admin.site.is_registered(User):
    admin.site.unregister(User)
@admin.register(User)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ('user_id', 'name', 'email', 'phoneNo', 'wallet_balance')
    list_filter = ('email', 'name')
    search_fields = ('name', 'email', 'phoneNo')
    ordering = ('user_id',)

    fieldsets = (
        (None, {'fields': ('name', 'email', 'password')}),
        ('Contact Info', {'fields': ('phoneNo',)}),
        ('Financial', {'fields': ('wallet_balance',)}),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('name', 'email', 'phoneNo', 'password1', 'password2'),
        }),
    )

@admin.register(UserToken)
class UserTokenAdmin(admin.ModelAdmin):
    list_display = ('user', 'key', 'created')
    list_filter = ('created',)
    search_fields = ('user__name', 'key')
    ordering = ('-created',)

# Employer Admin
@admin.register(Employer)
class EmployerAdmin(admin.ModelAdmin):
    list_display = ('employer_id', 'username', 'contact_email', 'phone_number')
    list_filter = ('contact_email', 'phone_number')
    search_fields = ('username', 'contact_email', 'phone_number')
    ordering = ('employer_id',)

@admin.register(EmployerToken)
class EmployerTokenAdmin(admin.ModelAdmin):
    list_display = ('employer', 'key', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('employer__username', 'key')
    ordering = ('-created_at',)

@admin.register(EmployerProfile)
class EmployerProfileAdmin(admin.ModelAdmin):
    list_display = ('employer', 'full_name', 'city', 'verification_status', 'is_fully_verified')
    list_filter = ('verification_status', 'email_verified', 'phone_verified', 'id_verified', 'city')
    search_fields = ('full_name', 'contact_email', 'phone_number', 'id_number')
    readonly_fields = ('created_at', 'updated_at')
    fieldsets = (
        ('Basic Info', {
            'fields': ('employer', 'full_name', 'profile_picture', 'bio')
        }),
        ('Contact Info', {
            'fields': ('contact_email', 'phone_number', 'alternate_phone', 'city', 'address')
        }),
        ('Verification', {
            'fields': (
                'email_verified', 'email_verified_at',
                'phone_verified', 'phone_verified_at',
                'id_verified', 'id_number', 'id_verified_by', 'id_verified_at',
                'verification_status'
            )
        }),
        ('Professional Info', {
            'fields': ('profession', 'skills', 'linkedin_url', 'twitter_url')
        }),
        ('Statistics', {
            'fields': ('total_projects_posted', 'total_spent', 'avg_freelancer_rating')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

# Task Admin
@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = (
        'task_id', 'title', 'employer', 'category', 'service_type', 
        'budget', 'status', 'is_approved', 'is_active', 'created_at'
    )
    list_filter = (
        'category', 'service_type', 'status', 'is_approved', 'is_active', 
        'is_urgent', 'payment_type', 'payment_status', 'created_at'
    )
    search_fields = ('title', 'description', 'employer__username', 'location_address')
    readonly_fields = ('created_at', 'onsite_verified_at', 'verification_generated_at')
    list_editable = ('status', 'is_approved', 'is_active')
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('title', 'description', 'category', 'employer')
        }),
        ('Task Type & Payment', {
            'fields': ('service_type', 'payment_type', 'budget')
        }),
        ('Payment Details', {
            'fields': ('is_paid', 'payment_status', 'amount_held_in_escrow', 'paystack_reference')
        }),
        ('Location (for On-Site)', {
            'fields': ('location_address', 'latitude', 'longitude'),
            'classes': ('collapse',)
        }),
        ('Timeline', {
            'fields': ('deadline', 'is_urgent')
        }),
        ('Skills & Files', {
            'fields': ('required_skills', 'attachments'),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('is_approved', 'is_active', 'status', 'assigned_user')
        }),
        ('On-Site Verification', {
            'fields': ('verification_code', 'verification_attempts', 'verification_generated_at', 'onsite_verified_at'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['approve_tasks', 'mark_as_active', 'mark_as_completed']

    def approve_tasks(self, request, queryset):
        queryset.update(is_approved=True)
    approve_tasks.short_description = "Approve selected tasks"

    def mark_as_active(self, request, queryset):
        queryset.update(is_active=True)
    mark_as_active.short_description = "Mark selected tasks as active"

    def mark_as_completed(self, request, queryset):
        queryset.update(status='completed')
    mark_as_completed.short_description = "Mark selected tasks as completed"

@admin.register(TaskCompletion)
class TaskCompletionAdmin(admin.ModelAdmin):
    list_display = ('completion_id', 'user', 'task', 'amount', 'status', 'paid', 'completed_at')
    list_filter = ('status', 'paid', 'completed_at')
    search_fields = ('user__name', 'task__title')
    readonly_fields = ('completed_at', 'payment_date')
    list_editable = ('status', 'paid')
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('user', 'task', 'submission')
        }),
        ('Payment', {
            'fields': ('amount', 'paid', 'payment_date', 'payment_reference')
        }),
        ('Status', {
            'fields': ('status',)
        }),
        ('Notes', {
            'fields': ('employer_notes', 'freelancer_notes'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('completed_at',),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['approve_completions', 'mark_as_paid']

    def approve_completions(self, request, queryset):
        for completion in queryset:
            completion.approve_completion()
    approve_completions.short_description = "Approve selected completions"

    def mark_as_paid(self, request, queryset):
        for completion in queryset:
            completion.mark_as_paid()
    mark_as_paid.short_description = "Mark selected completions as paid"

# Proposal Admin
@admin.register(Proposal)
class ProposalAdmin(admin.ModelAdmin):
    list_display = ('proposal_id', 'freelancer', 'task', 'status', 'submitted_at', 'estimated_days')
    list_filter = ('status', 'submitted_at')
    search_fields = ('freelancer__name', 'task__title', 'cover_letter')
    list_editable = ('status',)
    readonly_fields = ('submitted_at',)
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('freelancer', 'task', 'status')
        }),
        ('Proposal Details', {
            'fields': ('cover_letter', 'cover_letter_file', 'estimated_days')
        }),
        ('Timestamps', {
            'fields': ('submitted_at',),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['accept_proposals', 'reject_proposals']

    def accept_proposals(self, request, queryset):
        queryset.update(status='accepted')
    accept_proposals.short_description = "Accept selected proposals"

    def reject_proposals(self, request, queryset):
        queryset.update(status='rejected')
    reject_proposals.short_description = "Reject selected proposals"

# Contract Admin
@admin.register(Contract)
class ContractAdmin(admin.ModelAdmin):
    list_display = (
        'contract_id', 'task', 'freelancer', 'employer', 
        'is_active', 'status', 'is_fully_accepted', 'start_date'
    )
    list_filter = ('status', 'is_active', 'is_paid', 'is_completed', 'start_date')
    search_fields = ('task__title', 'freelancer__user__name', 'employer__username')
    readonly_fields = ('completed_date', 'payment_date')
    list_editable = ('status', 'is_active')
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('task', 'freelancer', 'employer')
        }),
        ('Contract Terms', {
            'fields': ('start_date', 'end_date')
        }),
        ('Acceptance Status', {
            'fields': ('employer_accepted', 'freelancer_accepted', 'is_fully_accepted')
        }),
        ('Contract Status', {
            'fields': ('is_active', 'status', 'is_completed', 'is_paid')
        }),
        ('Verification', {
            'fields': ('completion_code',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('completed_date', 'payment_date'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['activate_contracts', 'mark_as_completed', 'mark_as_paid']

    def activate_contracts(self, request, queryset):
        for contract in queryset:
            contract.activate_contract()
    activate_contracts.short_description = "Activate selected contracts"

    def mark_as_completed(self, request, queryset):
        for contract in queryset:
            contract.mark_as_completed()
    mark_as_completed.short_description = "Mark selected contracts as completed"

    def mark_as_paid(self, request, queryset):
        for contract in queryset:
            contract.mark_as_paid()
    mark_as_paid.short_description = "Mark selected contracts as paid"

# Transaction Admin
@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        'transaction_id', 'transaction_type', 'amount', 
        'freelancer_share', 'platform_fee', 'status', 'created_at'
    )
    list_filter = ('transaction_type', 'status', 'created_at')
    search_fields = ('paystack_reference', 'client__name', 'freelancer__user__name')
    readonly_fields = ('created_at', 'updated_at', 'completed_at')
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('transaction_type', 'status')
        }),
        ('Payment References', {
            'fields': ('paystack_reference', 'paystack_transfer_code')
        }),
        ('Relationships', {
            'fields': ('order', 'contract', 'task', 'client', 'freelancer'),
            'classes': ('collapse',)
        }),
        ('Amounts', {
            'fields': ('amount', 'freelancer_share', 'platform_fee', 'paystack_fee')
        }),
        ('Metadata', {
            'fields': ('metadata', 'notes'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'completed_at'),
            'classes': ('collapse',)
        }),
    )

# Withdrawal Request Admin
@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(admin.ModelAdmin):
    list_display = (
        'request_id', 'freelancer', 'amount', 'status', 
        'bank_name', 'account_number', 'requested_at'
    )
    list_filter = ('status', 'bank_name', 'requested_at')
    search_fields = ('freelancer__user__name', 'account_number', 'paystack_recipient_code')
    readonly_fields = ('requested_at', 'approved_at', 'processed_at', 'completed_at')
    list_editable = ('status',)
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('freelancer', 'amount', 'status')
        }),
        ('Bank Details', {
            'fields': ('bank_name', 'account_number', 'account_name')
        }),
        ('Paystack References', {
            'fields': ('paystack_recipient_code', 'paystack_transfer_code', 'transaction'),
            'classes': ('collapse',)
        }),
        ('Status Tracking', {
            'fields': ('admin_notes', 'failure_reason')
        }),
        ('Timestamps', {
            'fields': ('requested_at', 'approved_at', 'processed_at', 'completed_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['approve_withdrawals', 'mark_as_processing', 'mark_as_completed']

    def approve_withdrawals(self, request, queryset):
        queryset.update(status='approved')
    approve_withdrawals.short_description = "Approve selected withdrawals"

    def mark_as_processing(self, request, queryset):
        queryset.update(status='processing')
    mark_as_processing.short_description = "Mark selected withdrawals as processing"

    def mark_as_completed(self, request, queryset):
        queryset.update(status='completed')
    mark_as_completed.short_description = "Mark selected withdrawals as completed"

# Wallet and Payment Admin
@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ('user', 'balance', 'updated_at')
    list_filter = ('updated_at',)
    search_fields = ('user__name', 'user__email')
    readonly_fields = ('updated_at',)

@admin.register(PaymentRecord)
class PaymentRecordAdmin(admin.ModelAdmin):
    list_display = ('tx_ref', 'client', 'freelancer', 'total_amount', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('tx_ref', 'client__name', 'freelancer__name')
    readonly_fields = ('created_at',)

# Submission Admin
@admin.register(Submission)
class SubmissionAdmin(admin.ModelAdmin):
    list_display = (
        'submission_id', 'task', 'freelancer', 'title', 
        'status', 'submitted_at', 'checklist_tests_passing'
    )
    list_filter = ('status', 'submitted_at')
    search_fields = ('task__title', 'freelancer__name', 'title', 'description')
    readonly_fields = ('submitted_at', 'resubmitted_at')
    list_editable = ('status',)
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('task', 'freelancer', 'contract', 'title', 'description', 'status')
        }),
        ('Technical Details', {
            'fields': (
                'repo_url', 'commit_hash', 'staging_url', 'live_demo_url',
                'apk_download_url', 'testflight_link'
            ),
            'classes': ('collapse',)
        }),
        ('Access Credentials', {
            'fields': ('admin_username', 'admin_password', 'access_instructions'),
            'classes': ('collapse',)
        }),
        ('Files', {
            'fields': ('zip_file', 'screenshots', 'video_demo'),
            'classes': ('collapse',)
        }),
        ('Additional Info', {
            'fields': ('deployment_instructions', 'test_instructions', 'release_notes'),
            'classes': ('collapse',)
        }),
        ('Checklist', {
            'fields': (
                'checklist_tests_passing', 'checklist_deployed_staging',
                'checklist_documentation', 'checklist_no_critical_bugs'
            )
        }),
        ('Revision Tracking', {
            'fields': ('revision_notes', 'resubmitted_at'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('submitted_at',),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['approve_submissions', 'request_revision']

    def approve_submissions(self, request, queryset):
        for submission in queryset:
            submission.approve()
    approve_submissions.short_description = "Approve selected submissions"

    def request_revision(self, request, queryset):
        for submission in queryset:
            submission.request_revision("Please revise as requested by admin.")
    request_revision.short_description = "Request revision for selected submissions"

# Rating Admin
@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = (
        'rating_id', 'task', 'rater', 'rated_user', 
        'rating_type', 'score', 'created_at'
    )
    list_filter = ('rating_type', 'score', 'created_at')
    search_fields = ('task__title', 'rater__name', 'rated_user__name')
    readonly_fields = ('created_at',)
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('task', 'contract', 'submission', 'rater_employer')
        }),
        ('Rating Details', {
            'fields': ('rater', 'rated_user', 'rating_type', 'score', 'review')
        }),
        ('Work Passport Data', {
            'fields': (
                'would_recommend', 'would_rehire', 
                'performance_tags', 'calculated_composite', 'category_scores'
            ),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

# Notification Admin
@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('notification_id', 'user', 'title', 'notification_type', 'is_read', 'created_at')
    list_filter = ('notification_type', 'is_read', 'created_at')
    search_fields = ('user__name', 'title', 'message')
    readonly_fields = ('created_at',)
    list_editable = ('is_read',)
    
    actions = ['mark_as_read', 'mark_as_unread']

    def mark_as_read(self, request, queryset):
        queryset.update(is_read=True)
    mark_as_read.short_description = "Mark selected notifications as read"

    def mark_as_unread(self, request, queryset):
        queryset.update(is_read=False)
    mark_as_unread.short_description = "Mark selected notifications as unread"

# Freelancer Admin
@admin.register(Freelancer)
class FreelancerAdmin(admin.ModelAdmin):
    list_display = (
        'user', 'name', 'email', 'is_verified', 
        'has_paystack_account', 'can_receive_payments', 'total_earnings'
    )
    list_filter = ('is_verified', 'is_paystack_setup', 'bank_name')
    search_fields = ('user__name', 'user__email', 'business_name', 'account_number')
    readonly_fields = ('paystack_setup_date', 'last_payout_date')
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('user', 'is_verified')
        }),
        ('Paystack Account', {
            'fields': (
                'is_paystack_setup', 'paystack_subaccount_code', 'paystack_setup_date',
                'business_name', 'bank_name', 'bank_code', 'account_number', 'account_name'
            )
        }),
        ('Payment Statistics', {
            'fields': ('total_earnings', 'pending_payout', 'last_payout_date')
        }),
    )
    
    actions = ['verify_freelancers', 'mark_paystack_setup_complete']

    def verify_freelancers(self, request, queryset):
        queryset.update(is_verified=True)
    verify_freelancers.short_description = "Verify selected freelancers"

# Order and Payment Transaction Admin
@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('order_id', 'amount', 'currency', 'employer', 'status', 'created_at')
    list_filter = ('status', 'currency', 'created_at')
    search_fields = ('order_id', 'employer__username', 'task__title')
    readonly_fields = ('created_at', 'updated_at')
    list_editable = ('status',)

@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ('order', 'paystack_reference', 'amount', 'platform_commission', 'freelancer_share', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('paystack_reference', 'order__order_id')
    readonly_fields = ('created_at',)

# User Profile Admin
@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'skills', 'hourly_rate')
    search_fields = ('user__name', 'skills')
    list_filter = ('hourly_rate',)

# Skill System Admin
@admin.register(Skill)
class SkillAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'description')
    search_fields = ('name', 'category')
    list_filter = ('category',)

@admin.register(UserSkill)
class UserSkillAdmin(admin.ModelAdmin):
    list_display = ('user', 'skill', 'verification_status', 'date_verified')
    list_filter = ('verification_status', 'date_verified')
    search_fields = ('user__name', 'skill__name')
    list_editable = ('verification_status',)
    
    actions = ['mark_as_verified', 'mark_as_test_passed']

    def mark_as_verified(self, request, queryset):
        queryset.update(verification_status='verified', date_verified=timezone.now().date())
    mark_as_verified.short_description = "Mark selected skills as verified"

    def mark_as_test_passed(self, request, queryset):
        queryset.update(verification_status='test_passed', date_verified=timezone.now().date())
    mark_as_test_passed.short_description = "Mark selected skills as test passed"

# Portfolio Admin
@admin.register(PortfolioItem)
class PortfolioItemAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'completion_date', 'created_at')
    list_filter = ('completion_date', 'created_at')
    search_fields = ('user__name', 'title', 'description')
    filter_horizontal = ('skills_used',)
    
    fieldsets = (
        ('Basic Info', {
            'fields': ('user', 'title', 'description', 'completion_date')
        }),
        ('Media & Links', {
            'fields': ('image', 'video_url', 'project_url', 'client_quote'),
            'classes': ('collapse',)
        }),
        ('Skills', {
            'fields': ('skills_used',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

@admin.register(WorkHistory)
class WorkHistoryAdmin(admin.ModelAdmin):
    list_display = ('user', 'task', 'earnings', 'client_rating', 'completion_date')
    list_filter = ('completion_date', 'client_rating')
    search_fields = ('user__name', 'task__title')

# Payroll Report Admin
@admin.register(PayrollReport)
class PayrollReportAdmin(admin.ModelAdmin):
    list_display = ('report_id', 'employer', 'month', 'total_expense', 'created_at')
    list_filter = ('month', 'created_at')
    search_fields = ('employer__username',)

# Client and Service Admin
@admin.register(Client)
class ClientAdmin(admin.ModelAdmin):
    list_display = ('user',)
    search_fields = ('user__name', 'user__email')

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('freelancer', 'title', 'price', 'is_active')
    list_filter = ('is_active', 'price')
    search_fields = ('title', 'description', 'freelancer__user__name')