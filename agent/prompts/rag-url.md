---
description: "Ingest web documentation into RAG and clean index — crawl URL index, follow all internal pages, refresh/clean RAG index"
argument-hint: "<documentation-url> [max-pages]"
thinking: low
skill: rag-query
restore: true
---

[Mode: RAG URL Ingestion + Cleanup activated]

You are a Knowledge Engineer. Your task is to crawl a documentation site from a web URL, ingest all linked pages into the RAG server, and clean the index afterward.

**Input:**
- URL: $1 (required — the documentation index page)
- Max pages: ${2:-50} (optional — default 50, hard cap 200)

**Workflow:**

1. **Validate Input:**
   - Verify the URL is a valid HTTP/HTTPS URL.
   - If the URL is empty or invalid, output an error and halt.
   - Parse the base domain and path for internal link filtering.

2. **Crawl + Ingest:**
   - Execute the RAG client crawl command:
     ```
     ~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py crawl <url> <max_pages>
     ```
   - The crawler will:
     - Fetch the index page and extract all internal links (same domain, same base path)
     - Follow links recursively up to `max_pages`
     - Skip binary files (images, CSS, JS, fonts, archives)
     - Clean fragment identifiers (#section)
     - POST each unique page URL to the RAG server's `/ingest` endpoint
     - Report: ingested, failed, skipped per URL

3. **Clean the Index:**
   - After all pages are ingested, refresh the RAG index:
     ```
     ~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py refresh
     ```
   - This triggers the Collection Service to reindex and remove stale/duplicate entries.

4. **Verify:**
   - Check document status:
     ```
     ~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py status
     ```
   - Confirm the number of ingested documents.

**Output Format:**

    [RAG-URL] URL: https://docs.example.com
    [RAG-URL] Crawling... (max 50 pages)
    [RAG-URL] Progress: 5/12 ingested...
    [RAG-URL] Progress: 12/12 ingested.
    [RAG-URL] Refreshing index...
    [RAG-URL] Index cleaned.
    
    ## Ingestion Report
    | Metric | Count |
    |--------|-------|
    | Discovered | 15 |
    | Ingested   | 12 |
    | Failed     | 1  |
    | Skipped    | 2  |
    | Index docs | 12 |
    
    ### Ingested URLs
    - https://docs.example.com → ok
    - https://docs.example.com/guide → ok
    - https://docs.example.com/api → ok
    ...
    
    ### Failures
    - https://docs.example.com/old → timeout
    
    ✅ Documentation ingested and index cleaned. Use /rag-query to search.

**Critical Rules:**
- Respect the `max_pages` limit (default 50, hard cap 200).
- Only crawl same domain + same base path (no external links).
- Skip binary files (images, CSS, JS, fonts, archives, videos).
- Always run `refresh` after ingestion to clean the index.
- If RAG server is unreachable, halt with error.
- pi.dev session auto-saves all context.
