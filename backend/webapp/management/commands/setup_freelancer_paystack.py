# backend/webapp/management/commands/setup_freelancer_paystack.py
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from webapp.models import Freelancer
import requests
from django.conf import settings

class Command(BaseCommand):
    help = 'Setup Paystack subaccounts for freelancers'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--freelancer-id',
            type=int,
            help='Specific freelancer ID to setup'
        )
        parser.add_argument(
            '--email',
            type=str,
            help='Freelancer email to setup'
        )
    
    def handle(self, *args, **options):
        # Find freelancer(s) to setup
        freelancers = Freelancer.objects.filter(is_paystack_setup=False)
        
        if options['freelancer_id']:
            freelancers = freelancers.filter(id=options['freelancer_id'])
        elif options['email']:
            user = User.objects.get(email=options['email'])
            freelancers = freelancers.filter(user=user)
        
        self.stdout.write(f"Found {freelancers.count()} freelancers to setup")
        
        for freelancer in freelancers:
            self.setup_freelancer(freelancer)
    
    def setup_freelancer(self, freelancer):
        self.stdout.write(f"\nSetting up Paystack for: {freelancer.name}")
        
        # Check if bank details exist
        if not freelancer.bank_code or not freelancer.account_number:
            self.stdout.write(self.style.WARNING(
                f"  ❌ Skipping: {freelancer.name} has no bank details"
            ))
            return
        
        # Create Paystack subaccount
        url = "https://api.paystack.co/subaccount"
        headers = {
            "Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY_TEST}",
            "Content-Type": "application/json"
        }
        
        data = {
            "business_name": freelancer.business_name or f"{freelancer.name} Freelancing",
            "settlement_bank": freelancer.bank_code,
            "account_number": freelancer.account_number,
            "percentage_charge": 10.0,
            "description": f"Freelancer account for {freelancer.name}",
            "primary_contact_email": freelancer.email,
            "primary_contact_name": freelancer.name,
            "metadata": {"freelancer_id": freelancer.id}
        }
        
        try:
            response = requests.post(url, json=data, headers=headers)
            
            if response.status_code == 201:
                result = response.json()
                freelancer.paystack_subaccount_code = result['data']['subaccount_code']
                freelancer.is_paystack_setup = True
                freelancer.save()
                
                self.stdout.write(self.style.SUCCESS(
                    f"  ✅ Success! Subaccount: {freelancer.paystack_subaccount_code}"
                ))
            else:
                self.stdout.write(self.style.ERROR(
                    f"  ❌ Failed: {response.status_code} - {response.text}"
                ))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"  ❌ Error: {e}"))