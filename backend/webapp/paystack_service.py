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
                response = requests.post(url, json=data, headers=headers, timeout=30)
            elif method == 'GET':
                # For GET requests, 'data' should be sent as params[citation:3]
                response = requests.get(url, headers=headers, params=data, timeout=30)
            
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Paystack API Error: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            return {"status": False, "message": f"API Error: {str(e)}"}
    
    # NEW METHOD: Fetch the official Paystack bank list[citation:1]
    def list_banks(self, country="KE", currency="KES"):
        """Fetch the list of banks and their codes from Paystack."""
        endpoint = "/bank"
        params = {'country': country, 'currency': currency}
        return self._make_request('GET', endpoint, params)
    
    def resolve_account_number(self, account_number, bank_code):
        """Verify bank account details[citation:3]"""
        endpoint = "/bank/resolve"
        params = {  # Send account_number and bank_code as query parameters[citation:3]
            'account_number': account_number,
            'bank_code': bank_code
        }
        return self._make_request('GET', endpoint, params)
    
    def create_transfer_recipient(self, data):
        """Create transfer recipient for withdrawals"""
        endpoint = "/transferrecipient"
        return self._make_request('POST', endpoint, data)
    
    # ... keep all your other existing methods (initialize_transaction, etc.) below ...
    def initiate_transfer(self, amount, recipient_code, reason=""):
        """Initiate transfer to freelancer's bank"""
        data = {
            'source': 'balance',
            'amount': amount,
            'recipient': recipient_code,
            'reason': reason,
            'currency': 'KES'
        }
        return self._make_request('POST', '/transfer', data)
    
    def verify_transfer(self, transfer_code):
        """Check transfer status"""
        return self._make_request('GET', f'/transfer/{transfer_code}')
    
    def initialize_transaction(self, email, amount_cents, reference, callback_url=None, currency="KES"):
        """
        Regular (non-split) transaction initialization
        amount_cents: in CENTS (1 KSH = 100 cents)
        """
        data = {
            'email': email,
            'amount': amount_cents,
            'reference': reference,
            'callback_url': callback_url,
            'currency': currency,
        }
        
        print(f"💰 Paystack Regular Payment Request:")
        print(f"  Email: {email}")
        print(f"  Amount: {amount_cents} cents (KSh {amount_cents/100:.2f})")
        print(f"  Reference: {reference}")
        print(f"  Currency: {currency}")
        
        response = self._make_request('POST', '/transaction/initialize', data)
        print(f"💰 Paystack Response: {response}")
        return response
    
    def initialize_split_transaction(self, email, amount_cents, reference, subaccounts, callback_url=None, currency="KES"):
        """
        Initialize split payment transaction
        amount_cents: in CENTS (1 KSH = 100 cents)
        subaccounts: list of dicts with 'subaccount' and 'share' keys
        Example: [
            {'subaccount': 'ACCT_xxxx', 'share': 9000, 'bearer': 'subaccount'},  # 90.00 KSH
            {'subaccount': 'ACCT_yyyy', 'share': 1000, 'bearer': 'subaccount'}   # 10.00 KSH
        ]
        Note: 'share' is also in CENTS
        """
        data = {
            'email': email,
            'amount': amount_cents,
            'reference': reference,
            'callback_url': callback_url,
            'subaccount': subaccounts,
            'bearer': 'subaccount',
            'currency': currency,
        }
        
        print(f"💰 Paystack Split Payment Request:")
        print(f"  Email: {email}")
        print(f"  Amount: {amount_cents} cents (KSh {amount_cents/100:.2f})")
        print(f"  Reference: {reference}")
        print(f"  Currency: {currency}")
        print(f"  Subaccounts (in cents):")
        for sub in subaccounts:
            share_cents = sub['share']
            print(f"    - {sub['subaccount']}: {share_cents} cents (KSh {share_cents/100:.2f})")
        
        response = self._make_request('POST', '/transaction/initialize', data)
        print(f"💰 Paystack Response: {response}")
        return response
    
    def verify_transaction(self, reference):
        """
        Verify transaction status
        """
        print(f"🔍 Verifying transaction: {reference}")
        response = self._make_request('GET', f'/transaction/verify/{reference}')
        
        if response and response.get('status'):
            data = response.get('data', {})
            amount_cents = data.get('amount', 0)
            print(f"🔍 Transaction verified: {amount_cents} cents (KSh {amount_cents/100:.2f})")
        
        return response
    
    def transfer_to_subaccount(self, amount_cents, recipient, reason=""):
        """
        Transfer funds to subaccount
        amount_cents: in CENTS
        recipient: subaccount code
        """
        data = {
            'source': 'balance',
            'amount': amount_cents,
            'recipient': recipient,
            'reason': reason or 'Freelancer payment'
        }
        
        print(f"💸 Transferring {amount_cents} cents (KSh {amount_cents/100:.2f}) to {recipient}")
        response = self._make_request('POST', '/transfer', data)
        print(f"💸 Transfer Response: {response}")
        return response