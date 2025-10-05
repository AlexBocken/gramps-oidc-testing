-- Initialize Gramps Web database
-- This script is executed when the PostgreSQL container starts for the first time

-- Create additional database for user management if needed
-- (keeping the main gramps_web database as default)

-- Set up UTF8 encoding and locale for proper character support
-- This is handled by POSTGRES_INITDB_ARGS in docker-compose.yml

-- The main gramps_web database is created automatically by POSTGRES_DB

-- Create Authentik database
CREATE DATABASE authentik;