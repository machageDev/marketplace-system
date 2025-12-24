import os
import django
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'helawork.settings')
django.setup()

import psycopg2
from django.conf import settings

def fix_contract_foreign_key():
    """
    Directly fixes the foreign key constraint in the database.
    1. Drops the problematic foreign key constraint
    2. Recreates it pointing to the CORRECT table (webapp_user)
    """
    db_settings = settings.DATABASES['default']
    
    conn = psycopg2.connect(
        dbname=db_settings['NAME'],
        user=db_settings['USER'],
        password=db_settings['PASSWORD'],
        host=db_settings['HOST'],
        port=db_settings['PORT']
    )
    
    cursor = conn.cursor()
    
    try:
        print("Step 1: Dropping problematic foreign key constraint...")
        cursor.execute("""
            ALTER TABLE webapp_contract 
            DROP CONSTRAINT IF EXISTS webapp_contract_freelancer_id_e6672d8b_fk_auth_user_id;
        """)
        
        print("Step 2: Creating correct foreign key to webapp_user table...")
        cursor.execute("""
            ALTER TABLE webapp_contract 
            ADD CONSTRAINT webapp_contract_freelancer_id_fk_webapp_user
            FOREIGN KEY (freelancer_id) 
            REFERENCES webapp_user(user_id);
        """)
        
        print("Step 3: Checking for orphaned contracts...")
        cursor.execute("""
            SELECT COUNT(*) FROM webapp_contract 
            WHERE freelancer_id NOT IN (SELECT user_id FROM webapp_user);
        """)
        orphaned_count = cursor.fetchone()[0]
        
        if orphaned_count > 0:
            print(f"Found {orphaned_count} orphaned contracts. Deleting...")
            cursor.execute("""
                DELETE FROM webapp_contract 
                WHERE freelancer_id NOT IN (SELECT user_id FROM webapp_user);
            """)
            print(f"Deleted {orphaned_count} orphaned contracts.")
        else:
            print("No orphaned contracts found.")
        
        conn.commit()
        print("✅ Foreign key fixed successfully!")
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Error: {e}")
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    fix_contract_foreign_key()