import os
from typing import Sequence, Optional

try:
    import httpx
except ImportError:  # pragma: no cover
    httpx = None


class AiGateway:
    """
    Lightweight adapter that can speak to OpenWebUI, Ollama, or mock responses.
    """

    def __init__(self):
        self.provider = os.getenv("AI_PROVIDER", "mock").lower()
        self.model = os.getenv("AI_MODEL", "llama3.1")
        self.openwebui_url = os.getenv("OPENWEBUI_URL")
        self.ollama_url = os.getenv("OLLAMA_URL", "http://localhost:11434")

    async def generate_reply(self, prompt: str, history: Optional[Sequence[dict]] = None):
        if httpx is None:
            return self._mock_response(prompt, history or [])
        if self.provider == "openwebui" and self.openwebui_url:
            return await self._call_openwebui(prompt, history or [])
        if self.provider == "ollama":
            return await self._call_ollama(prompt, history or [])
        return self._mock_response(prompt, history or [])

    async def _call_openwebui(self, prompt: str, history: Sequence[dict]):
        url = f"{self.openwebui_url.rstrip('/')}/api/v1/chat/completions"
        payload = {
            "model": self.model,
            "messages": [*history, {"role": "user", "content": prompt}],
            "stream": False,
        }
        if httpx is None:
            return self._mock_response(prompt, history)
        try:
            async with httpx.AsyncClient(timeout=20) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                return data["choices"][0]["message"]["content"]
        except Exception:
            return self._mock_response(prompt, history)

    async def _call_ollama(self, prompt: str, history: Sequence[dict]):
        url = f"{self.ollama_url.rstrip('/')}/api/chat"
        payload = {
            "model": self.model,
            "messages": [*history, {"role": "user", "content": prompt}],
        }
        if httpx is None:
            return self._mock_response(prompt, history)
        try:
            async with httpx.AsyncClient(timeout=20) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                message = data.get("message") or {}
                return message.get("content") or self._mock_response(prompt, history)
        except Exception:
            return self._mock_response(prompt, history)

    def _mock_response(self, prompt: str, history: Sequence[dict]):
        context = history[-1]["content"] if history else ""
        return (
            "I have captured your request. "
            "Here's a quick summary so it is easy to follow up later:\n\n"
            f"Latest prompt: {prompt.strip()}\n"
            f"Last context: {context}"
        )

    def openwebui_status(self):
        enabled = bool(self.openwebui_url)
        return {
            "enabled": enabled,
            "url": self.openwebui_url if enabled else None,
        }
