from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import User, Freelancer, Employer, EmployerProfile

@receiver(post_save, sender=User)
def create_user_profiles(sender, instance, created, **kwargs):
    """
    Automatically create Freelancer and Employer profiles when a new User is created
    """
    if created:
        print(f"🎯 Creating profiles for new user: {instance.name} (ID: {instance.user_id})")
        
        # Create Freelancer profile (empty)
        try:
            Freelancer.objects.get_or_create(
                user=instance,
                defaults={
                    'business_name': f"{instance.name} Freelancing",
                    'is_verified': False,
                    'is_paystack_setup': False,
                    'total_earnings': 0.00,
                    'pending_payout': 0.00
                }
            )
            print(f"✅ Created Freelancer profile for {instance.name}")
        except Exception as e:
            print(f"⚠️ Could not create Freelancer profile: {e}")
        
        # Create Employer profile (empty)
        try:
            employer, emp_created = Employer.objects.get_or_create(
                username=instance.name,
                contact_email=instance.email,
                defaults={
                    'password': '',  # Will be set separately
                    'phone_number': instance.phoneNo or ''
                }
            )
            
            # Also create EmployerProfile
            EmployerProfile.objects.get_or_create(
                employer=employer,
                defaults={
                    'full_name': instance.name,
                    'contact_email': instance.email,
                    'city': 'Not provided',
                    'address': 'Not provided',
                    'verification_status': 'unverified'
                }
            )
            print(f"✅ Created Employer profile for {instance.name}")
        except Exception as e:
            print(f"⚠️ Could not create Employer profile: {e}")

@receiver(post_save, sender=User)
def update_user_profiles(sender, instance, **kwargs):
    """
    Update related profiles when User is updated
    """
    try:
        # Update freelancer name if it exists
        if hasattr(instance, 'freelancer_profile'):
            instance.freelancer_profile.save()
    except:
        pass