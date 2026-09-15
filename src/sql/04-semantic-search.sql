-- Find the 5 most semantically similar documents to a query.
-- <=> is pgvector's cosine-distance operator: smaller distance means
-- more similar, so 1 - distance gives a more intuitive 0-1 score.
WITH query_embedding AS (
    SELECT azure_openai.create_embeddings('text-embedding-3-small', 'how do I reduce my AKS bill') AS emb
)
SELECT
    d.id,
    d.title,
    1 - (d.embedding <=> q.emb) AS similarity
FROM documents d, query_embedding q
ORDER BY d.embedding <=> q.emb
LIMIT 5;
