from django.urls import path
from . import views


urlpatterns = [
    #worker/ mobile app
    path('debug-auth-test/', views.debug_auth_test, name='debug-auth-test'),
    path('apilogin',views.apilogin, name = 'apilogin'),
    path('apiregister',views.apiregister,name='apiregister'),
    path('apiforgot_password',views.apiforgot_password, name = 'apiforgotpassword'),    
    path('task', views.apitask_list, name='tasklist'),
    #path('task/',views.apitask_detail, name='taskdetail'),
    path('apiproposal', views.apisubmit_proposal, name='submit_proposal'),
    path('apiuserprofile',views.apiuserprofile,name='apiuser_profile'),
    path('submissions/create/', views.create_submission, name='submission_create'),
    #path('submissions/my-submissions/', views.get_my_submissions, name='my_submissions'),
    path('submissions/employer-submissions/', views.get_employer_submissions, name='employer_submissions'),
    #path('submissions/<int:submission_id>/', views.get_submission_detail, name='submission_detail'),
    path('submissions/<int:submission_id>/approve/', views.approve_submission, name='submission_approve'),
    path('submissions/<int:submission_id>/request-revision/', views.request_revision, name='request_revision'),
     path('api/freelancer/contracts/', views.freelancer_contracts, name='freelancer_contracts'),
    path('api/contracts/<int:contract_id>/accept/', views.accept_contract, name='accept_contract'),
    path('api/contracts/<int:contract_id>/reject/', views.reject_contract, name='reject_contract'),
    # Rating URLs
    path('ratings/create/', views.create_rating, name='rating-create'),
    path('users/<int:user_id>/ratings/', views.get_user_ratings, name='user_ratings'),
    path('tasks/<int:task_id>/ratings/', views.get_task_ratings, name='task_ratings'),
    path('freelancer/recommended-jobs/', views.recommended_jobs, name='recommended_jobs'),
    # Dashboard
    path('submissions/stats/', views.submission_stats, name='submission-stats'),
    

    # Employer CRUD
    path('login',views.employer_login,name='login'),  
    path('register', views.employer_register, name='employer_register'),  
    path('employers/<int:pk>/', views.get_employer, name='get_employer'),
    path('employers/<int:pk>/', views.update_employer, name='update_employer'),
    path('employers/<int:pk>/', views.delete_employer, name='delete_employer'),
    path('employers/<int:employer_id>/profile', views.employer_profile, name='employer_profile'),
    path('tasks/create/', views.create_task, name='create-task'),
    path('tasks/<int:task_id>/delete/', views.delete_task, name='delete-task'),
    path('tasks/bulk-delete/', views.bulk_delete_tasks, name='bulk-delete-tasks'),
    path('client/proposals/',views.get_freelancer_proposals,name='freeproposal'),
    path('dashboard', views.employer_dashboard_api, name='employer_dashboard_api'),
    path('employer/tasks/', views.get_employer_tasks, name='get_employer_tasks'),    
    #path('employer/<int:employer_id>/profile/', views.get_employer_profile, name='get_employer_profile'),
    #path('employer/profile/create/', views.create_employer_profile, name='create_employer_profile'),
    #path('employer/<int:employer_id>/profile/update/', views.update_employer_profile, name='update_employer_profile'),
    path('profile/', views.get_employer_profile, name='get-employer-profile'),
    path('profile/create/', views.create_employer_profile, name='create-employer-profile'),
    path('profile/update/', views.update_employer_profile, name='update-employer-profile'),
    path('profile/upload-id/', views.upload_id_document, name='upload-id-document'),
    path('profile/verify-email/', views.verify_email, name='verify-email'),
    path('profile/verify-phone/', views.verify_phone, name='verify-phone'),
    path('completetask', views.task_completion_list, name='task-completion-list'),
    path('task-completions/<int:pk>/', views.task_completion_detail, name='task-completion-detail'),
    path('api/tasks/employer/rateable/', views.employer_rateable_tasks, name='employer-rateable-tasks'),
    path('api/employers/<int:employer_id>/ratings/', views.employer_ratings, name='employer-ratings'),
    path('api/payment/order/<str:order_id>/', views.payment_order_details, name='api_payment_order_details'),
    path('api/payment/initialize/', views.initialize_payment_api, name='api_initialize_payment'),
    path('api/payment/verify/<str:reference>/', views.verify_payment_api, name='api_verify_payment'),
    path('api/payment/webhook/', views.payment_webhook_api, name='api_payment_webhook'),
    path('api/transactions/history/', views.transaction_history, name='api_transaction_history'),
    path('api/submissions/create/', views.create_submission, name='create-submission'), 
   # path('api/submissions/<int:submission_id>/', views.get_submission_detail, name='submission-detail'),
    
    
   
] 