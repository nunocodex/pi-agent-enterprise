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
RAG_DOCS_PATH = _env.get("RAG_DOCS_PATH", "./docs")
RAG_DOCS_MAX_FILES = int(_env.get("RAG_DOCS_MAX_FILES", "50"))

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

    def ingest_url(self, url: str) -> Dict[str, Any]:
        """Ingestisce un singolo URL nel server RAG."""
        if not url or not url.strip():
            raise ValueError("URL cannot be empty")
        sanitized = url.strip()
        payload = {"url": sanitized}
        try:
            resp = self.session.post(
                urljoin(self.base_url, "/ingest"),
                json=payload,
                timeout=self.timeout * 2,  # ingestion can take longer
            )
            resp.raise_for_status()
            return resp.json()
        except Timeout:
            logger.error("URL ingestion timed out: %s", sanitized)
            raise
        except ConnectionError:
            logger.error("Cannot reach RAG server for ingestion")
            raise
        except RequestException as e:
            logger.error("Ingestion error for %s: %s", sanitized, str(e))
            raise

    def upload_file(self, filepath: str) -> Dict[str, Any]:
        """Carica un file locale nel RAG server via multipart upload."""
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError(f"File not found: {filepath}")
        if not path.is_file():
            raise ValueError(f"Not a file: {filepath}")
        try:
            with open(path, 'rb') as f:
                resp = self.session.post(
                    urljoin(self.base_url, "/upload"),
                    files={"file": (path.name, f)},
                    timeout=self.timeout * 2,
                    headers={"Content-Type": None},  # override session JSON header for multipart
                )
            resp.raise_for_status()
            return resp.json()
        except Timeout:
            logger.error("File upload timed out: %s", filepath)
            raise
        except Exception as e:
            logger.error("Upload error for %s: %s", filepath, str(e))
            raise

    def ingest_directory(self, dirpath: str, max_files: int = 50) -> Dict[str, Any]:
        """Carica tutti i file da una directory locale nel RAG."""
        import os
        path = Path(dirpath)
        if not path.exists():
            raise FileNotFoundError(f"Directory not found: {dirpath}")
        if not path.is_dir():
            raise ValueError(f"Not a directory: {dirpath}")

        # Supported text/doc extensions
        extensions = {".md", ".txt", ".rst", ".html", ".htm", ".xml",
                      ".json", ".yaml", ".yml", ".py", ".js", ".ts",
                      ".jsx", ".tsx", ".css", ".scss", ".toml", ".cfg",
                      ".ini", ".sh", ".bash", ".zsh", ".env"}
        results = {"ingested": 0, "failed": 0, "skipped": 0, "files": []}

        for root, dirs, files in os.walk(dirpath):
            # Skip hidden dirs and node_modules
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'node_modules' and d != '__pycache__']
            for filename in files:
                if len(results["files"]) >= max_files:
                    break
                filepath = os.path.join(root, filename)
                ext = os.path.splitext(filename)[1].lower()
                if ext not in extensions and filename.find('.') != -1:
                    results["skipped"] += 1
                    continue
                try:
                    result = self.upload_file(filepath)
                    results["files"].append({"file": filepath, "status": result.get("status", "unknown")})
                    results["ingested"] += 1
                except Exception as e:
                    results["failed"] += 1
                    results["files"].append({"file": filepath, "status": "failed", "error": str(e)})
            if len(results["files"]) >= max_files:
                break

        return results

    def crawl_and_ingest(self, base_url: str, max_pages: int = 50) -> Dict[str, Any]:
        """Crawla una documentazione: estrae link interni e li ingerisce."""
        import re
        from urllib.parse import urljoin as _urljoin, urlparse

        parsed = urlparse(base_url)
        base_origin = f"{parsed.scheme}://{parsed.netloc}"
        base_path = parsed.path.rstrip('/') if parsed.path else ''

        visited = set()
        to_visit = [base_url]
        results = {"ingested": 0, "failed": 0, "skipped": 0, "urls": []}

        while to_visit and len(visited) < max_pages:
            url = to_visit.pop(0)
            if url in visited:
                continue
            visited.add(url)

            try:
                # Fetch the page to extract links
                resp = requests.get(url, timeout=self.timeout, headers={
                    "User-Agent": "pi-dev-rag-crawler/1.0",
                })
                if resp.status_code != 200:
                    results["skipped"] += 1
                    continue

                # Extract internal links (same domain, same base path)
                links = re.findall(r'href=["\']([^"\'\s]+)["\']', resp.text, re.IGNORECASE)
                for link in links:
                    absolute = _urljoin(url, link)
                    link_parsed = urlparse(absolute)
                    # Only same domain, same base path, HTML/docs pages
                    if (link_parsed.netloc == parsed.netloc and
                        absolute.startswith(base_origin + base_path) and
                        absolute not in visited and
                        not absolute.endswith(('.png', '.jpg', '.svg', '.css', '.js', '.json', '.xml', '.ico', '.woff2', '.woff'))):
                        # Clean fragment/anchor
                        clean = absolute.split('#')[0]
                        if clean not in visited:
                            to_visit.append(clean)

                # Ingest the current page
                ingest_result = self.ingest_url(url)
                results["urls"].append({"url": url, "status": ingest_result.get("status", "unknown")})
                results["ingested"] += 1

            except Exception as e:
                logger.warning("Failed to process %s: %s", url, str(e))
                results["failed"] += 1
                results["urls"].append({"url": url, "status": "failed", "error": str(e)})

        return results

    def refresh_index(self) -> Dict[str, Any]:
        """Forza il refresh/reindex del Collection Service dopo ingestion."""
        try:
            resp = self.session.post(
                urljoin(self.web_base, "/documents/refresh"),
                timeout=self.timeout * 2,
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.error("Refresh failed: %s", str(e))
            raise

    def document_status(self) -> Dict[str, Any]:
        """Recupera lo stato dei documenti indicizzati."""
        try:
            resp = self.session.get(
                urljoin(self.web_base, "/documents/status"),
                timeout=self.timeout,
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as e:
            logger.error("Status check failed: %s", str(e))
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
        print("  python rag_client.py ingest <url>             # ingest single URL")
        print("  python rag_client.py crawl <url> [max_pages]  # crawl + ingest URL pages")
        print("  python rag_client.py dir [path] [max_files]   # ingest local directory")
        print("  python rag_client.py refresh                  # refresh/reindex after ingestion")
        print("  python rag_client.py status                   # check document indexing status")
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
    elif command == "ingest":
        url = args[2] if len(args) > 2 else ""
        try:
            result = client.ingest_url(url)
        except Exception as e:
            result = {"error": str(e)}
    elif command == "crawl":
        url = args[2] if len(args) > 2 else ""
        max_pages = int(args[3]) if len(args) > 3 else 50
        try:
            result = client.crawl_and_ingest(url, max_pages)
        except Exception as e:
            result = {"error": str(e)}
    elif command == "dir":
        # If arg is a number, it's max_files, not path
        if len(args) > 2 and args[2].isdigit():
            dirpath = RAG_DOCS_PATH
            max_files = int(args[2])
        else:
            dirpath = args[2] if len(args) > 2 else RAG_DOCS_PATH
            max_files = int(args[3]) if len(args) > 3 else RAG_DOCS_MAX_FILES
        try:
            result = client.ingest_directory(dirpath, max_files)
        except Exception as e:
            result = {"error": str(e)}
    elif command == "refresh":
        try:
            result = client.refresh_index()
        except Exception as e:
            result = {"error": str(e)}
    elif command == "status":
        try:
            result = client.document_status()
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