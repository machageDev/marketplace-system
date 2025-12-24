# scripts/fix_contracts.py
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project_name.settings')
django.setup()

from webapp.models import Contract

def fix_contract_data():
    """Deletes contracts with freelancer_id=2, which is causing the foreign key error."""
    try:
        # Find and delete the problematic contracts
        bad_contracts = Contract.objects.filter(freelancer_id=2)
        count, _ = bad_contracts.delete()
        print(f"Successfully deleted {count} problematic contract(s) with freelancer_id=2.")
        return True
    except Exception as e:
        print(f"Error fixing contract data: {e}")
        return False

if __name__ == '__main__':
    fix_contract_data()