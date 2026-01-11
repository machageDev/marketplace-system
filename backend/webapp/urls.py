from django.urls import path
from . import views
from .skill_views import get_all_skills, manage_user_skills, manage_portfolio
from .freelancer_profile_view_view import view_freelancer_profile
from .freelancer_views import get_freelancer_work_passport, get_freelancer_verified_skills, get_freelancer_portfolio

urlpatterns = [
    # ============ AUTH & USER ============
    
    path('apilogin', views.apilogin, name='apilogin'),
    path('apiregister', views.apiregister, name='apiregister'),
    path('apiforgot_password', views.apiforgot_password, name='apiforgotpassword'),    
    path('apiuserprofile', views.apiuserprofile, name='apiuser_profile'),
    
    # ============ TASKS ============
    path('task', views.apitask_list, name='tasklist'),
    path('tasks/create/', views.create_task, name='create-task'),    
    path('employer/tasks/', views.get_employer_tasks, name='get_employer_tasks'),
    path('api/tasks/assigned/', views.get_assigned_tasks, name='freelancer-assigned-tasks'),
    path('api/tasks/employer/rateable/', views.employer_rateable_tasks, name='employer-rateable-tasks'),
    
    # ============ PROPOSALS ============
    path('apiproposal', views.apisubmit_proposal, name='submit_proposal'),
    path('client/proposals/', views.get_freelancer_proposals, name='freeproposal'),
    path('proposals/accept/', views.accept_proposal, name='accept_proposal'),
    
    # ============ CONTRACTS ============
    path('api/freelancer/contracts/', views.freelancer_contracts, name='freelancer_contracts'),
    path('api/contracts/<int:contract_id>/accept/', views.accept_contract, name='accept_contract'),
    path('api/contracts/<int:contract_id>/reject/', views.reject_contract, name='reject_contract'),
    path('api/employer/contracts/', views.employer_contracts, name='employer_contracts'),
    path('contracts/employer/pending-completions/', views.employer_pending_completions, name='employer_pending_completions'),
    path('api/contracts/<int:contract_id>/mark-completed/', views.employer_mark_contract_completed, name='mark-contract-completed'),
    path('contracts/employer/pending-completions/', views.employer_pending_completions, name='employer_pending_completions'),
    path('contracts/<int:contract_id>/mark-completed/', views.mark_contract_completed, name='mark_contract_completed'),
    
    # ============ SUBMISSIONS ============
    path('submissions/create/', views.create_submission, name='submission_create'),
    path('api/submissions/create/', views.create_submission, name='create-submission'),     
     path('api/tasks/freelancer/completed/', views.freelancer_completed_tasks, name='freelancer_completed_tasks'),
    path('api/submissions-to-rate/', views.get_submissions_for_rating, name='submissions_to_rate'),
    path('api/submissions/employer/', views.employer_submissions, name='employer-submissions'),
    path('api/submissions/<int:submission_id>/approve/', views.approve_submission, name='approve-submission'),
    path('api/submissions/<int:submission_id>/request-revision/', views.request_revision, name='request-revision'),
    path('api/submissions/<int:submission_id>/', views.submission_detail, name='submission-detail'),
    
    # ============ PAYMENTS ============
    # CHOOSE ONE: Either use existing payment endpoints OR new ones
    # OPTION A: Use your existing payment endpoints (recommended - remove the new ones below)
    path('api/payment/create-order/', views.create_order, name='create_order'),
    path('api/payment/order/<str:order_id>/', views.payment_order_details, name='api_payment_order_details'),
    path('api/payment/initialize/', views.initialize_payment, name='api_initialize_payment'),
    path('api/payment/verify/<str:reference>/', views.verify_payment_api, name='api_verify_payment'),
    path('api/payment/webhook/', views.payment_webhook_api, name='api_payment_webhook'),
    #path('api/transactions/history/', views.transaction_history, name='api_transaction_history'),
    path('api/orders/pending-payment/', views.pending_payment_orders, name='pending_payment_orders'),
    path('api/payment/transactions/', views.employer_transactions, name='employer_transactions'),
    path('api/orders/<uuid:order_id>/verify-payment/', views.verify_order_payment, name='verify-order-payment'),
    path('contracts/<int:contract_id>/order/', views.get_order_for_contract, name='contract-order'),
    path('api/banks/', views.register_bank,name='register-bank'),
    # OPTION B: Use new payment endpoints (if you implemented them) - REMOVE ABOVE IF USING THESE
    # path('api/payment/order/<str:order_id>/', views.order_detail, name='order_detail'),
    # path('api/orders/pending-payment/', views.pending_payment_orders, name='pending_payment_orders'),
    # path('api/payment/initialize/', views.initialize_payment, name='initialize_payment'),
    # path('api/payment/verify/<str:reference>/', views.verify_payment, name='verify_payment'),
    # path('api/payment/callback/', views.payment_callback, name='payment_callback'),
    # path('api/payment/transactions/', views.employer_transactions, name='employer_transactions'),
   
    
    # ============ RATINGS ============
    path('contracts/rateable/', views.get_rateable_contracts, name='rateable-contracts'),
    path('ratings/', views.create_employer_rating, name='rating-create'),
    path('users/ratings/', views.get_user_ratings, name='user_ratings'),
    path('tasks/ratings/', views.get_task_ratings, name='task_ratings'),
    path('api/employers/<int:employer_id>/ratings/', views.employer_ratings, name='employer-ratings'),
    
    # ============ EMPLOYER PROFILE ============
    path('profile/', views.get_employer_profile, name='get-employer-profile'),
    path('employers/profile/create/', views.create_employer_profile, name='create-employer-profile'),
    path('profile/update/', views.update_employer_profile, name='update-employer-profile'),
    path('profile/upload-id/', views.update_id_number, name='upload-id-document'),
    path('profile/verify-email/', views.verify_email, name='verify-email'),
    path('profile/verify-phone/', views.verify_phone, name='verify-phone'),
    
    # ============ EMPLOYER AUTH ============
    path('login', views.employer_login, name='login'),  
    path('register', views.employer_register, name='employer_register'),
    path('employers/<int:pk>/', views.get_employer, name='get_employer'),   
    path('employers/<int:employer_id>/profile', views.employer_profile, name='employer_profile'),
    
    # ============ DASHBOARD & MISC ============
    path('dashboard', views.employer_dashboard_api, name='employer_dashboard_api'),
    path('submissions/stats/', views.submission_stats, name='submission-stats'),
    path('freelancer/recommended-jobs/', views.recommended_jobs, name='recommended_jobs'),
    path('completetask', views.task_completion_list, name='task-completion-list'),
    path('task-completions/<int:pk>/', views.task_completion_detail, name='task-completion-detail'),
    
    # Wallet endpoints
    path('api/wallet/', views.get_wallet_data, name='wallet-data'),
    path('api/wallet/balance/', views.get_wallet_balance, name='wallet-balance'),
    path('api/wallet/withdraw/', views.withdraw_funds, name='withdraw-funds'),
    path('api/wallet/topup/', views.top_up_wallet, name='top-up-wallet'),
    path('api/wallet/register-bank/', views.register_bank, name='register-bank'),
    
    # Skill and Portfolio endpoints
    path('api/skills/all/', get_all_skills, name='all_skills'),
    path('api/skills/my/', manage_user_skills, name='my_skills'),
    path('api/portfolio/', manage_portfolio, name='portfolio_list'),
    path('api/portfolio/<int:portfolio_id>/', manage_portfolio, name='portfolio_detail'),
    
    # ============ FREELANCER PROFILE ============
    path('api/freelancers/<int:user_id>/', view_freelancer_profile, name='freelancer-profile'),
    
    # ============ FREELANCER READ-ONLY ENDPOINTS ============
    path('api/freelancer/work-passport/', get_freelancer_work_passport, name='freelancer-work-passport'),
    path('api/freelancer/work-passport/<int:user_id>/', get_freelancer_work_passport, name='freelancer-work-passport-by-id'),
    path('api/freelancer/verified-skills/', get_freelancer_verified_skills, name='freelancer-verified-skills'),
    path('api/freelancer/verified-skills/<int:user_id>/', get_freelancer_verified_skills, name='freelancer-verified-skills-by-id'),
    path('api/freelancer/portfolio/', get_freelancer_portfolio, name='freelancer-portfolio'),
    path('api/freelancer/portfolio/<int:user_id>/', get_freelancer_portfolio, name='freelancer-portfolio-by-id'),
]