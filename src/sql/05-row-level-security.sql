-- Combine semantic search with a permissions filter enforced by the
-- database itself — no way for an application bug to leak a similarity
-- match the requesting user isn't allowed to see.
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS document_access ON documents;
CREATE POLICY document_access ON documents
    FOR SELECT
    USING (owner_id = current_setting('app.current_user_id', true)::int OR is_public = true);

-- Set this per-connection (e.g. right after your app authenticates the
-- user) so the policy above has something to compare against:
--   SELECT set_config('app.current_user_id', '42', false);
