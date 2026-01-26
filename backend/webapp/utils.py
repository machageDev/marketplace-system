import requests
from django.conf import settings

def get_bank_name(bank_code):
    """Your local bank mapping (Internal use)"""
    banks = {
        '01': 'KCB Bank Kenya',
        '02': 'Standard Chartered Kenya',
        '03': 'Absa Bank Kenya',
        '07': 'NCBA Bank Kenya',
        '09': 'Equity Bank Kenya',
        '11': 'Co-operative Bank of Kenya Ltd',
        '34': 'Ecobank Kenya',
        '57': 'I&M Bank Kenya',
        '63': 'Diamond Trust Bank',
        '68': 'Equity Bank Kenya Ltd',
        '70': 'Family Bank Ltd',
    }
    return banks.get(str(bank_code).strip(), 'Unknown Bank')

def get_paystack_bank_list():
    """Fetches official Paystack codes for Kenya from their API"""
    url = "https://api.paystack.co/bank?country=kenya"
    headers = {"Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}"}
    try:
        response = requests.get(url, headers=headers, timeout=5)
        if response.status_code == 200:
            return response.json().get('data', [])
    except Exception:
        return []
    return []

def get_paystack_code_dynamically(bank_name_search):
    """Matches your bank name to Paystack's required code"""
    # 1. Quick Map for performance
    quick_map = {
        'Equity Bank Kenya Ltd': '007',
        'Equity Bank Kenya': '007',
        'KCB Bank Kenya': '008',
        'Co-operative Bank of Kenya Ltd': '009',
        'Absa Bank Kenya': '001',
        'Standard Chartered Kenya': '010',
    }
    
    if bank_name_search in quick_map:
        return quick_map[bank_name_search]

    # 2. API Fallback for other banks
    all_banks = get_paystack_bank_list()
    for bank in all_banks:
        paystack_name = bank['name'].lower()
        search_name = bank_name_search.lower()
        if search_name in paystack_name or paystack_name in search_name:
            return bank['code']
    return None

def create_paystack_records(freelancer, account_number, paystack_bank_code):
    """
    Creates both a Transfer Recipient and a Subaccount.
    Returns (recipient_code, subaccount_code, error_message)
    """
    headers = {
        "Authorization": f"Bearer {settings.PAYSTACK_SECRET_KEY}",
        "Content-Type": "application/json"
    }

    # Step A: Create Transfer Recipient (for Payouts)
    recipient_data = {
        "type": "nuban",
        "name": f"{freelancer.user.first_name} {freelancer.user.last_name}",
        "account_number": account_number,
        "bank_code": paystack_bank_code,
        "currency": "KES"
    }
    
    res_rec = requests.post("https://api.paystack.co/transferrecipient", json=recipient_data, headers=headers)
    if res_rec.status_code != 201:
        return None, None, res_rec.json().get('message', 'Recipient creation failed')
    
    recipient_code = res_rec.json()['data']['recipient_code']

    # Step B: Create Subaccount (for Split Payments)
    sub_data = {
        "business_name": f"{freelancer.user.first_name} {freelancer.user.last_name}",
        "settlement_bank": paystack_bank_code,
        "account_number": account_number,
        "percentage_charge": 10.0  # Your platform fee
    }
    
    res_sub = requests.post("https://api.paystack.co/subaccount", json=sub_data, headers=headers)
    subaccount_code = res_sub.json()['data']['subaccount_code'] if res_sub.status_code in [200, 201] else None

    return recipient_code, subaccount_code, None