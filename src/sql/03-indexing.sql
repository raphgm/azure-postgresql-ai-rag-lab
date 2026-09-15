-- HNSW: the better default for most workloads (higher recall than
-- IVFFlat, no need to tune list count to table size). Build this AFTER
-- bulk-loading data — building incrementally during a bulk insert is
-- dramatically slower.
CREATE INDEX IF NOT EXISTS documents_embedding_hnsw_idx ON documents
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);
