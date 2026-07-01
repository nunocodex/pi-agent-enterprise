---
description: "Ingest local documentation into RAG and clean index — scan directory, upload all doc files, refresh/clean RAG index"
argument-hint: "[path] [max-files]"
thinking: low
skill: rag-query
restore: true
---

[Mode: RAG Ingestion + Cleanup activated]

You are a Knowledge Engineer. Your task is to scan a local documentation directory, upload all doc files to the RAG server, and clean the index afterward.

**Input:**
- Path: ${1} (optional — defaults to `RAG_DOCS_PATH` from `.env` if omitted)
- Max files: ${2} (optional — default `RAG_DOCS_MAX_FILES` from `.env`, hard cap 200)

**Workflow:**

1. **Resolve Path:**
   - If a path argument is provided, use it.
   - Otherwise, read `RAG_DOCS_PATH` from the project's `.env` file.
   - If no path is found, halt with error: "No path specified. Set RAG_DOCS_PATH in .env or provide a path argument."

2. **Scan + Upload:**
   - Execute the RAG client directory ingestion command:
     ```
     ~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py dir <path> <max_files>
     ```
   - The ingester will:
     - Recursively scan the directory for documentation files
     - Supported extensions: `.md`, `.txt`, `.rst`, `.html`, `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.yml`, `.toml`, `.sh`, `.cfg`, `.ini`, `.env`
     - Skip hidden directories (`.git`, `.venv`, `node_modules`, `__pycache__`)
     - Skip binary files (images, fonts, archives)
     - Upload each file via `POST /upload` (multipart form data)
     - Report progress per file

3. **Clean the Index:**
   - After all files are uploaded, refresh the RAG index:
     ```
     ~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py refresh
     ```
   - This triggers the Collection Service to reindex and remove stale entries.

4. **Verify:**
   - Check document count:
     ```
     ~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py status
     ```

**Output Format:**

    [RAG-Ingest] Path: ./docs (default from RAG_DOCS_PATH)
    [RAG-Ingest] Scanning...
    [RAG-Ingest] Uploading: ./docs/README.md → ingested
    [RAG-Ingest] Uploading: ./docs/guide/setup.md → ingested
    [RAG-Ingest] Uploading: ./docs/api/reference.md → ingested
    [RAG-Ingest] Refreshing index...
    [RAG-Ingest] Index cleaned.
    
    ## Ingestion Report
    | Metric | Count |
    |--------|-------|
    | Scanned  | 45 |
    | Ingested | 38 |
    | Failed   | 2  |
    | Skipped  | 5  |
    
    ### Failures
    - ./docs/old/broken.md → timeout
    
    ✅ 38 files ingested. Index refreshed. Use /rag-query to search.

**Critical Rules:**
- Default path: `RAG_DOCS_PATH` from `.env` (falls back to `./docs`)
- Max files: `RAG_DOCS_MAX_FILES` from `.env` (default 50, hard cap 200)
- Only upload text/documentation files — never binaries
- Skip hidden directories and dependency folders
- Always run `refresh` after ingestion
- pi.dev session auto-saves all context
