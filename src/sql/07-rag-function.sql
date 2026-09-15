-- The full RAG loop -- embed, retrieve, augment, generate -- as a
-- single callable SQL function.
CREATE OR REPLACE FUNCTION rag_answer(user_question TEXT)
RETURNS TEXT AS $$
DECLARE
    context_text TEXT;
    question_embedding VECTOR(1536);
    answer TEXT;
BEGIN
    question_embedding := azure_openai.create_embeddings('text-embedding-3-small', user_question);

    -- Retrieval: top 3 most relevant chunks
    SELECT string_agg(content, E'\n---\n')
    INTO context_text
    FROM (
        SELECT content
        FROM documents
        ORDER BY embedding <=> question_embedding
        LIMIT 3
    ) top_matches;

    -- Generation: the LLM answers using only the retrieved context.
    -- The "if the context does not contain the answer, say so"
    -- instruction matters: without it the model will confidently
    -- answer from its own training data when the context is
    -- irrelevant, defeating the point of RAG.
    --
    -- Note the E'' prefix on the format string below -- a plain '...'
    -- literal does NOT interpret \n as a newline in Postgres; only an
    -- E-prefixed ("escape") string does.
    SELECT azure_openai.create_chat_completion(
        'gpt-4o-mini',
        jsonb_build_array(
            jsonb_build_object('role', 'system', 'content',
                'Answer using only the provided context. If the context does not contain the answer, say so.'),
            jsonb_build_object('role', 'user', 'content',
                format(E'Context:\n%s\n\nQuestion: %s', context_text, user_question))
        )
    )->'choices'->0->'message'->>'content'
    INTO answer;

    RETURN answer;
END;
$$ LANGUAGE plpgsql;

-- Try it:
--   SELECT rag_answer('How do I reduce my AKS compute bill?');
