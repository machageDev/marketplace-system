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
    path('apiproposal', views.apisubmit_proposal, name='submit-proposal'),
    path('apiuserprofile',views.apiuserprofile,name='apiuser_profile'),
    path('submissions/create/', views.create_submission, name='submission-create'),
    path('submissions/my-submissions/', views.get_my_submissions, name='my-submissions'),
    path('submissions/employer-submissions/', views.get_employer_submissions, name='employer-submissions'),
    path('submissions/<int:submission_id>/', views.get_submission_detail, name='submission-detail'),
    path('submissions/<int:submission_id>/approve/', views.approve_submission, name='submission-approve'),
    path('submissions/<int:submission_id>/request-revision/', views.request_revision, name='request-revision'),
    
    # Rating URLs
    path('ratings/create/', views.create_rating, name='rating-create'),
    path('users/<int:user_id>/ratings/', views.get_user_ratings, name='user-ratings'),
    path('tasks/<int:task_id>/ratings/', views.get_task_ratings, name='task-ratings'),
    
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
    path('employer/<int:employer_id>/profile/', views.get_employer_profile, name='get_employer_profile'),
    path('employer/profile/create/', views.create_employer_profile, name='create_employer_profile'),
    path('employer/<int:employer_id>/profile/update/', views.update_employer_profile, name='update_employer_profile'),
 
    path('completetask', views.task_completion_list, name='task-completion-list'),
    path('task-completions/<int:pk>/', views.task_completion_detail, name='task-completion-detail'),
    path('api/tasks/employer/rateable/', views.employer_rateable_tasks, name='employer-rateable-tasks'),
    
   
   # path('payment/callback/', views.payment_callback, name='payment_callback'),
   # path('wallet/<int:user_id>/', views.get_wallet_balance, name='get_wallet_balance'),
   # path('wallet/<int:user_id>/withdraw/', views.withdraw_funds, name='withdraw_funds'),
    #path('wallet/<int:user_id>/topup/', views.top_up_wallet, name='top_up_wallet'),
    
   
] 