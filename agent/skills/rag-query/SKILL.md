---
name: rag-query
description: "Query the RAG server using the rag_client.py utility"
---

# RAG Query Skill

## Objective
Retrieve relevant documentation from the RAG server to answer the user's query.

## Instructions
1.  **Receive Query**: You will be provided with a user query.
2.  **Execute Client**: Run the RAG client utility using the `Bash` tool.
    *   Command: `~/.pi/venv/bin/python ~/.pi/agent/skills/rag-query/rag_client.py "<query>"`
3.  **Process Output**: The script returns a JSON object with `response` and `sources`.
4.  **Respond**: Use the `response` as the answer, citing `sources` if available.

## Setup
- Dependencies are managed globally in `~/.pi/requirements.txt`.
- Run `~/.pi/setup.sh` once to install them.

## Notes
- If the script fails, respond with the error message.
- Do not invent information outside the RAG response.
