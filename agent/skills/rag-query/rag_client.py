#!/usr/bin/env python3
# rag_client.py – Enterprise RAG client with local + web search

import os
import sys
import json
import logging
from pathlib import Path
from typing import Dict, Any, Optional
from urllib.parse import urljoin

import requests
from requests.exceptions import RequestException, Timeout, ConnectionError
from dotenv import load_dotenv

# ---------- Logging ----------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ---------- Environment ----------
def load_env_file() -> Dict[str, str]:
    config = {}
    possible_paths = [
        Path.cwd() / ".pi" / ".env",
        Path.home() / ".pi" / "agent" / ".env",
    ]
    for path in possible_paths:
        if path.exists():
            load_dotenv(path)
            logger.debug(f"Loaded .env from {path}")
            break
    return dict(os.environ)

_env = load_env_file()

# ---------- Constants ----------
RAG_API_IP = _env.get("RAG_API_IP", "192.168.1.2")
RAG_API_PORT = _env.get("RAG_API_PORT", "8080")
RAG_WEB_PORT = _env.get("RAG_WEB_PORT", "8181")          # collection service
RAG_TOP_K = int(_env.get("RAG_TOP_K", "3"))
RAG_TIMEOUT = int(_env.get("RAG_TIMEOUT", "30"))
RAG_MAX_QUERY_LENGTH = int(_env.get("RAG_MAX_QUERY_LENGTH", "4096"))

API_BASE = f"http://{RAG_API_IP}:{RAG_API_PORT}"
WEB_BASE = f"http://{RAG_API_IP}:{RAG_WEB_PORT}"
HEALTH_URL = urljoin(API_BASE, "/health")
QUERY_URL = urljoin(API_BASE, "/query")
WEB_SEARCH_URL = urljoin(WEB_BASE, "/search")

# ---------- RAGClient ----------
class RAGClient:
    def __init__(self, base_url: str = API_BASE, web_base: str = WEB_BASE, timeout: int = RAG_TIMEOUT):
        self.base_url = base_url
        self.web_base = web_base
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "pi-dev-rag-client/1.0",
        })

    def health_check(self) -> bool:
        try:
            resp = self.session.get(HEALTH_URL, timeout=5)
            return resp.status_code == 200 and resp.json().get("status") == "healthy"
        except Exception:
            return False

    def query(self, query: str, top_k: int = RAG_TOP_K) -> Dict[str, Any]:
        if not query or not query.strip():
            raise ValueError("Query cannot be empty")
        sanitized = query.strip()[:RAG_MAX_QUERY_LENGTH]
        effective_k = max(1, min(top_k, 10))
        payload = {"query": sanitized, "top_k": effective_k}

        try:
            resp = self.session.post(QUERY_URL, json=payload, timeout=self.timeout)
            resp.raise_for_status()
            data = resp.json()
            return {
                "response": data.get("response", "No response"),
                "sources": data.get("sources", []),
            }
        except Timeout:
            logger.error("RAG query timed out")
            raise
        except ConnectionError:
            logger.error("Cannot reach RAG server")
            raise
        except RequestException as e:
            logger.error("RAG API error: %s", str(e))
            raise

    def web_search(self, query: str, top_k: int = RAG_TOP_K, include_extraction: bool = True) -> Dict[str, Any]:
        """Esegue una ricerca web tramite il Collection Service."""
        if not query or not query.strip():
            raise ValueError("Web search query cannot be empty")
        sanitized = query.strip()[:RAG_MAX_QUERY_LENGTH]
        effective_k = max(1, min(top_k, 10))
        payload = {
            "query": sanitized,
            "top_k": effective_k,
            "include_extraction": include_extraction,
        }

        try:
            resp = self.session.post(WEB_SEARCH_URL, json=payload, timeout=self.timeout * 2)
            resp.raise_for_status()
            return resp.json()
        except Timeout:
            logger.error("Web search timed out")
            raise
        except ConnectionError:
            logger.error("Cannot reach Collection Service at %s", self.web_base)
            raise
        except RequestException as e:
            logger.error("Web search error: %s", str(e))
            raise

    def hybrid_search(self, query: str, top_k: int = RAG_TOP_K) -> Dict[str, Any]:
        """Combina risultati RAG locale e web."""
        local_result = None
        web_result = None

        try:
            local_result = self.query(query, top_k)
        except Exception as e:
            logger.warning("Local RAG failed: %s", str(e))
            local_result = {"response": "⚠️ RAG unavailable", "sources": []}

        try:
            web_result = self.web_search(query, top_k, include_extraction=True)
        except Exception as e:
            logger.warning("Web search failed: %s", str(e))
            web_result = {"sources": [], "ingested": 0, "cached": False}

        return {
            "local": local_result,
            "web": web_result,
            "combined": {
                "response": (
                    local_result.get("response", "") +
                    "\n\n--- Web sources ---\n" +
                    "\n".join(
                        f"- {s.get('title', 'Untitled')} ({s.get('url', '')})"
                        for s in web_result.get("sources", [])[:3]
                    )
                ),
                "sources": local_result.get("sources", []) + web_result.get("sources", []),
            }
        }

# ---------- Main ----------
if __name__ == "__main__":
    args = sys.argv
    if len(args) < 2:
        print("Usage:")
        print("  python rag_client.py <query> [top_k]          # local RAG")
        print("  python rag_client.py web <query> [top_k]      # web search")
        print("  python rag_client.py hybrid <query> [top_k]   # hybrid search")
        sys.exit(1)

    client = RAGClient()
    command = args[1]

    if command == "web":
        query = args[2] if len(args) > 2 else ""
        top_k = int(args[3]) if len(args) > 3 else RAG_TOP_K
        try:
            result = client.web_search(query, top_k)
        except Exception as e:
            result = {"error": str(e)}
    elif command == "hybrid":
        query = args[2] if len(args) > 2 else ""
        top_k = int(args[3]) if len(args) > 3 else RAG_TOP_K
        try:
            result = client.hybrid_search(query, top_k)
        except Exception as e:
            result = {"error": str(e)}
    else:
        query = args[1]
        top_k = int(args[2]) if len(args) > 2 else RAG_TOP_K
        try:
            result = client.query(query, top_k)
        except Exception as e:
            result = {"error": str(e)}

    print(json.dumps(result, indent=2))