-- CodeFlow Engine PostgreSQL Initialization Script
-- This script runs on first database initialization

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schema for CodeFlow
CREATE SCHEMA IF NOT EXISTS CodeFlow;

-- Set default search path
ALTER DATABASE CodeFlow SET search_path TO CodeFlow, public;

-- Grant permissions to CodeFlow user
GRANT ALL PRIVILEGES ON SCHEMA CodeFlow TO CodeFlow;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA CodeFlow TO CodeFlow;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA CodeFlow TO CodeFlow;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA CodeFlow
GRANT ALL PRIVILEGES ON TABLES TO CodeFlow;

ALTER DEFAULT PRIVILEGES IN SCHEMA CodeFlow
GRANT ALL PRIVILEGES ON SEQUENCES TO CodeFlow;

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'CodeFlow Engine database initialized successfully';
END $$;
