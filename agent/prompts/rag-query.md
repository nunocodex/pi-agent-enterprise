---
description: "Hybrid RAG query — search local RAG + web collection service for maximum coverage"
argument-hint: "<query>"
thinking: low
skill: rag-query
---

# Hybrid RAG Query

## Query
{{query}}

## Context Retrieval — Primary (local RAG)
```
~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py "{{query}}"
```

## Context Retrieval — Secondary (web search)
```
~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py web "{{query}}"
```

## Response
- Combine results from both local RAG (port 8080) and web collection (port 8181)
- If local returns 0 sources, prioritize web results
- Cite all sources with URLs
- If both return empty, state "No results found in RAG or web collection"
