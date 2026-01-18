import requests
import json
from django.conf import settings

class PaystackService:
    def __init__(self):
        self.secret_key = settings.PAYSTACK_SECRET_KEY
        self.public_key = settings.PAYSTACK_PUBLIC_KEY
        self.base_url = "https://api.paystack.co"

    def _make_request(self, method, endpoint, data=None):
        """Internal helper for handling API requests."""
        headers = {
            'Authorization': f'Bearer {self.secret_key}',
            'Content-Type': 'application/json'
        }
        url = f"{self.base_url}{endpoint}"
        
        try:
            if method == 'POST':
                response = requests.post(url, json=data, headers=headers, timeout=30)
            else:  # GET
                response = requests.get(url, headers=headers, params=data, timeout=30)
            
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Paystack API Error: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response: {e.response.text}")
            return {"status": False, "message": f"API Error: {str(e)}"}

    # ==========================================
    # VERIFICATION & LOOKUP METHODS
    # ==========================================

    def list_banks(self, country="KE", currency="KES"):
        """Fetch official list of banks and codes."""
        return self._make_request('GET', "/bank", {'country': country, 'currency': currency})

    def resolve_account_number(self, account_number, bank_code):
        """Verify bank account ownership details."""
        params = {'account_number': account_number, 'bank_code': bank_code}
        return self._make_request('GET', "/bank/resolve", params)

    def verify_transaction(self, reference):
        """Verify the status of a specific payment reference."""
        print(f"🔍 Verifying transaction: {reference}")
        response = self._make_request('GET', f'/transaction/verify/{reference}')
        
        if response and response.get('status'):
            amount = response.get('data', {}).get('amount', 0)
            print(f"✅ Verified: KSh {amount/100:.2f}")
        return response

    # ==========================================
    # INITIALIZATION METHODS (COLLECTING MONEY)
    # ==========================================

    def initialize_transaction(self, email, amount_cents, reference, callback_url=None, currency="KES"):
        """Regular payment initialization (Escrow flow)."""
        data = {
            'email': email,
            'amount': amount_cents,
            'reference': reference,
            'callback_url': callback_url,
            'currency': currency,
        }
        return self._make_request('POST', '/transaction/initialize', data)

    def initialize_split_transaction(self, email, amount_cents, reference, subaccounts, callback_url=None, currency="KES"):
        """Payment initialization with immediate split to subaccounts."""
        data = {
            'email': email,
            'amount': amount_cents,
            'reference': reference,
            'callback_url': callback_url,
            'subaccount': subaccounts,
            'bearer': 'subaccount',
            'currency': currency,
        }
        return self._make_request('POST', '/transaction/initialize', data)

    # ==========================================
    # TRANSFER & PAYOUT METHODS (SENDING MONEY)
    # ==========================================

    def create_transfer_recipient(self, data):
        """Create a recipient for withdrawals/transfers."""
        return self._make_request('POST', "/transferrecipient", data)

    def transfer_to_subaccount(self, amount_cents, recipient, reason=""):
        """Release funds from platform balance to a specific recipient/subaccount."""
        data = {
            'source': 'balance',
            'amount': amount_cents,
            'recipient': recipient,
            'reason': reason or 'Freelancer payment',
            'currency': 'KES'
        }
        print(f"💸 Releasing KSh {amount_cents/100:.2f} to {recipient}")
        return self._make_request('POST', '/transfer', data)

    def verify_transfer(self, transfer_code):
        """Check the status of a payout/transfer."""
        return self._make_request('GET', f'/transfer/{transfer_code}')