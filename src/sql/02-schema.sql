CREATE TABLE IF NOT EXISTS documents (
    id          SERIAL PRIMARY KEY,
    title       TEXT NOT NULL,
    content     TEXT NOT NULL,
    embedding   VECTOR(1536),   -- matches text-embedding-3-small's output dimension
    owner_id    INT,
    is_public   BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS support_tickets (
    id          SERIAL PRIMARY KEY,
    body        TEXT NOT NULL,
    sentiment   TEXT,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- Sample data. Embeddings are populated separately (they need a live
-- Azure OpenAI call) — see the INSERT example in the article, Section 02.
INSERT INTO documents (title, content, owner_id, is_public) VALUES
    ('FinOps for Kubernetes', 'Practical strategies to slash compute spend on AKS using spot node pools, KEDA auto-scalers, and Azure Data Lake Gen2 tiering.', NULL, true),
    ('Zero Trust Network Architecture', 'A deep dive into perimeter-less networking, micro-segmentation, and central hub-and-spoke security enforcement.', NULL, true)
ON CONFLICT DO NOTHING;
