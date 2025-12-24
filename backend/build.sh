#!/usr/bin/env bash
set -o errexit

# 1. Install dependencies
pip install -r requirements.txt

# 2. Install psycopg2 for direct database access
pip install psycopg2-binary

# 3. FIX THE FOREIGN KEY DIRECTLY
echo "=== FIXING FOREIGN KEY CONSTRAINT ==="
python fix_foreign_key.py

# 4. Now run migrations normally
echo "=== RUNNING MIGRATIONS ==="
python manage.py migrate

# 5. Collect static files
echo "=== COLLECTING STATIC FILES ==="
python manage.py collectstatic --no-input

echo "✅ Build completed successfully!"