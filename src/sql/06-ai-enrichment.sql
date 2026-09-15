-- Enrich data at write time rather than query time — trades a small
-- write-time cost for zero read-time latency, the right call for data
-- that's written once and read often.

-- Sentiment analysis on a support ticket, stored alongside the row.
UPDATE support_tickets
SET sentiment = azure_cognitive.analyze_sentiment(body, 'en')
WHERE sentiment IS NULL;

-- Key phrase extraction, useful for tagging/search without a separate
-- NLP pipeline.
SELECT azure_cognitive.extract_key_phrases(content, 'en')
FROM documents
WHERE id = 1;
