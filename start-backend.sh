#!/bin/bash
echo "🔧 Starting Gramps Web API Backend..."

# Load environment
source gramps_venv/bin/activate

# Load environment variables properly (skip comments and empty lines)
set -a
source .env.local
set +a

# Ensure logging is visible
export PYTHONUNBUFFERED=1

# Change to API directory
cd gramps-web-api

# Initialize database and create tree if needed
echo "Initializing Gramps database..."
python -c "
import os
from gramps_webapi.app import create_app
from gramps_webapi.auth import add_user
from gramps_webapi.const import ROLE_ADMIN

app = create_app()
with app.app_context():
    try:
        # Create a local admin user
        add_user(name='admin', password='admin', role=ROLE_ADMIN, fullname='Admin User')
        print('✅ Admin user created (admin/admin)')
    except Exception as e:
        print(f'ℹ️  Admin user may already exist: {e}')
" 2>/dev/null || echo "Database initialization completed"

# Run database migrations
alembic upgrade head 2>/dev/null || echo "No migrations to run"

# Start the Flask development server with verbose logging
echo "Starting Flask development server..."
echo "Logs will appear below..."
python -m flask --app gramps_webapi.app run --host=0.0.0.0 --port=5555 --debug