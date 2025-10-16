from django.urls import path
from . import views


urlpatterns = [
    #worker/ mobile app
    path('debug-auth-test/', views.debug_auth_test, name='debug-auth-test'),
    path('apilogin',views.apilogin, name = 'apilogin'),
    path('apiregister',views.apiregister,name='apiregister'),
    path('apiforgot_password',views.apiforgot_password, name = 'apiforgotpassword'),
    path('employer_ratings/', views.employer_ratings_list, name='employer_ratings-list'),
    path('employer_ratings', views.employer_rating_detail, name='employer_rating_detail'),
    path('my_employer_ratings/', views.my_employer_ratings, name='my_employer_ratings'),
    path('freelancer_ratings/', views.freelancer_ratings, name='freelancer_ratings'),     
  
    path('task', views.apitask_list, name='tasklist'),
    #path('task/',views.apitask_detail, name='taskdetail'),
    path('apiproposal', views.apisubmit_proposal, name='submit-proposal'),
    path('apiuserprofile',views.apiuserprofile,name='apiuser_profile'),
    

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
    path('freeproposal',views.get_freelancer_proposals,name='freeproposal'),
    path('dashboard', views.employer_dashboard_api, name='employer_dashboard_api'),
    path('employer/tasks/', views.get_employer_tasks, name='get_employer_tasks'),
] 