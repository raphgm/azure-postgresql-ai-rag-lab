#!/usr/bin/env python3
"""
A minimal tool-calling agent: the model decides whether a question needs
a document search, a sentiment summary, or neither, rather than always
following the same fixed retrieval path.

Usage:
    python agent.py "How do I reduce my AKS compute bill?"

Requires environment variables:
    AZURE_OPENAI_ENDPOINT   e.g. https://<your-resource>.openai.azure.com
    PG_CONN_STRING          e.g. "dbname=ragdb host=<server>.postgres.database.azure.com user=<user> sslmode=require"
"""

import json
import os
import sys

import psycopg2
from openai import AzureOpenAI

client = AzureOpenAI(
    azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
    api_version="2024-08-01-preview",
)
conn = psycopg2.connect(os.environ["PG_CONN_STRING"])

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "search_documents",
            "description": "Semantic search over the internal knowledge base",
            "parameters": {
                "type": "object",
                "properties": {"query": {"type": "string"}},
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_ticket_sentiment_summary",
            "description": "Aggregate sentiment across recent support tickets",
            "parameters": {"type": "object", "properties": {}},
        },
    },
]


def search_documents(query: str) -> str:
    with conn.cursor() as cur:
        cur.execute("SELECT rag_answer(%s)", (query,))
        return cur.fetchone()[0]


def get_ticket_sentiment_summary() -> str:
    with conn.cursor() as cur:
        cur.execute("SELECT sentiment, count(*) FROM support_tickets GROUP BY sentiment")
        return json.dumps(cur.fetchall())


FUNCTIONS = {
    "search_documents": search_documents,
    "get_ticket_sentiment_summary": get_ticket_sentiment_summary,
}


def run_agent(user_message: str) -> str:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": user_message}],
        tools=TOOLS,
    )
    msg = response.choices[0].message
    if not msg.tool_calls:
        return msg.content

    tool_call = msg.tool_calls[0]
    fn = FUNCTIONS[tool_call.function.name]
    args = json.loads(tool_call.function.arguments)
    result = fn(**args)

    follow_up = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "user", "content": user_message},
            msg,
            {"role": "tool", "tool_call_id": tool_call.id, "content": result},
        ],
    )
    return follow_up.choices[0].message.content


if __name__ == "__main__":
    question = " ".join(sys.argv[1:]) or "How do I reduce my AKS compute bill?"
    print(run_agent(question))
