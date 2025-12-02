import requests
import json
from django.conf import settings

class PaystackService:
    def __init__(self):
        self.secret_key = settings.PAYSTACK_SECRET_KEY
        self.public_key = settings.PAYSTACK_PUBLIC_KEY
        self.base_url = "https://api.paystack.co"
    
    def _make_request(self, method, endpoint, data=None):
        headers = {
            'Authorization': f'Bearer {self.secret_key}',
            'Content-Type': 'application/json'
        }
        
        url = f"{self.base_url}{endpoint}"
        
        try:
            if method == 'POST':
                response = requests.post(url, json=data, headers=headers)
            elif method == 'GET':
                response = requests.get(url, headers=headers)
            
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Paystack API Error: {e}")
            return None
    
    def initialize_transaction(self, email, amount, reference, callback_url=None):
        data = {
            'email': email,
            'amount': int(amount * 100),  # Convert to kobo
            'reference': reference,
            'callback_url': callback_url,
        }
        
        return self._make_request('POST', '/transaction/initialize', data)
    
    def verify_transaction(self, reference):
        return self._make_request('GET', f'/transaction/verify/{reference}')
    
    def initialize_split_payment(self, email, amount, reference, subaccounts, callback_url=None):
        data = {
            'email': email,
            'amount': int(amount * 100),
            'reference': reference,
            'callback_url': callback_url,
            'subaccount': subaccounts,
            'bearer': 'account',
        }
        
        return self._make_request('POST', '/transaction/initialize', data)