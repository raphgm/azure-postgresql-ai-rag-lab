-- Run once per database. Requires the extensions to be allowlisted first
-- via the Azure Portal: Server Parameters -> azure.extensions -> add
-- "VECTOR,AZURE_AI" -- otherwise CREATE EXTENSION fails with a
-- permission error even for an admin user.
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS azure_ai;
