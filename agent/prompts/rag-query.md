---
description: "Direct RAG query — retrieve documentation from RAG server"
model: deepseek/deepseek-v4-flash
thinking: low
skill: rag-query
---
# RAG Query

## Query
{{query}}

## Context Retrieval
{{tool "rag_query" query=query}}

## Response
(Generate response based solely on the context retrieved.)
