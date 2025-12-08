-- AutoPR Engine PostgreSQL Initialization Script
-- This script runs on first database initialization

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schema for AutoPR
CREATE SCHEMA IF NOT EXISTS autopr;

-- Set default search path
ALTER DATABASE autopr SET search_path TO autopr, public;

-- Grant permissions to autopr user
GRANT ALL PRIVILEGES ON SCHEMA autopr TO autopr;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA autopr TO autopr;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA autopr TO autopr;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA autopr
GRANT ALL PRIVILEGES ON TABLES TO autopr;

ALTER DEFAULT PRIVILEGES IN SCHEMA autopr
GRANT ALL PRIVILEGES ON SEQUENCES TO autopr;

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'AutoPR Engine database initialized successfully';
END $$;
