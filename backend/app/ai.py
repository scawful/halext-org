import os
from typing import Sequence, Optional, List, Dict, Any, AsyncGenerator
import json

try:
    import httpx
except ImportError:  # pragma: no cover
    httpx = None


class AiGateway:
    """
    Enhanced AI adapter supporting OpenWebUI, Ollama, with streaming and embeddings.
    """

    def __init__(self):
        self.provider = os.getenv("AI_PROVIDER", "mock").lower()
        self.model = os.getenv("AI_MODEL", "llama3.1")
        self.openwebui_url = os.getenv("OPENWEBUI_URL")
        self.ollama_url = os.getenv("OLLAMA_URL", "http://localhost:11434")

    async def generate_reply(self, prompt: str, history: Optional[Sequence[dict]] = None):
        """Generate a single response (non-streaming)"""
        if httpx is None:
            return self._mock_response(prompt, history or [])
        if self.provider == "openwebui" and self.openwebui_url:
            return await self._call_openwebui(prompt, history or [])
        if self.provider == "ollama":
            return await self._call_ollama(prompt, history or [])
        return self._mock_response(prompt, history or [])

    async def generate_stream(
        self,
        prompt: str,
        history: Optional[Sequence[dict]] = None,
        model: Optional[str] = None
    ) -> AsyncGenerator[str, None]:
        """Generate a streaming response"""
        model = model or self.model

        if httpx is None or self.provider == "mock":
            # Mock streaming - yield the mock response word by word
            response = self._mock_response(prompt, history or [])
            for word in response.split():
                yield word + " "
            return

        if self.provider == "ollama":
            async for chunk in self._stream_ollama(prompt, history or [], model):
                yield chunk
        elif self.provider == "openwebui" and self.openwebui_url:
            async for chunk in self._stream_openwebui(prompt, history or [], model):
                yield chunk
        else:
            # Fallback to mock
            response = self._mock_response(prompt, history or [])
            for word in response.split():
                yield word + " "

    async def get_models(self) -> List[Dict[str, Any]]:
        """List available AI models"""
        if httpx is None or self.provider == "mock":
            return [
                {"name": "llama3.1", "size": "8B", "provider": "mock"},
                {"name": "mistral", "size": "7B", "provider": "mock"},
            ]

        if self.provider == "ollama":
            return await self._list_ollama_models()
        elif self.provider == "openwebui" and self.openwebui_url:
            return await self._list_openwebui_models()

        return []

    async def generate_embeddings(self, text: str, model: Optional[str] = None) -> List[float]:
        """Generate embeddings for text"""
        model = model or self.model

        if httpx is None or self.provider == "mock":
            # Mock embeddings - return a simple hash-based vector
            import hashlib
            hash_val = int(hashlib.md5(text.encode()).hexdigest(), 16)
            return [(hash_val >> i) % 100 / 100.0 for i in range(384)]

        if self.provider == "ollama":
            return await self._get_ollama_embeddings(text, model)

        # Fallback to mock
        import hashlib
        hash_val = int(hashlib.md5(text.encode()).hexdigest(), 16)
        return [(hash_val >> i) % 100 / 100.0 for i in range(384)]

    async def _call_openwebui(self, prompt: str, history: Sequence[dict]):
        """Call OpenWebUI API (non-streaming)"""
        url = f"{self.openwebui_url.rstrip('/')}/api/v1/chat/completions"
        payload = {
            "model": self.model,
            "messages": [*history, {"role": "user", "content": prompt}],
            "stream": False,
        }
        if httpx is None:
            return self._mock_response(prompt, history)
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                return data["choices"][0]["message"]["content"]
        except Exception as e:
            print(f"OpenWebUI error: {e}")
            return self._mock_response(prompt, history)

    async def _stream_openwebui(
        self,
        prompt: str,
        history: Sequence[dict],
        model: str
    ) -> AsyncGenerator[str, None]:
        """Stream from OpenWebUI"""
        url = f"{self.openwebui_url.rstrip('/')}/api/v1/chat/completions"
        payload = {
            "model": model,
            "messages": [*history, {"role": "user", "content": prompt}],
            "stream": True,
        }

        try:
            async with httpx.AsyncClient(timeout=60) as client:
                async with client.stream("POST", url, json=payload) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if line.startswith("data: "):
                            data_str = line[6:]
                            if data_str.strip() == "[DONE]":
                                break
                            try:
                                data = json.loads(data_str)
                                content = data["choices"][0]["delta"].get("content", "")
                                if content:
                                    yield content
                            except (json.JSONDecodeError, KeyError):
                                continue
        except Exception as e:
            print(f"OpenWebUI streaming error: {e}")
            yield self._mock_response(prompt, history)

    async def _list_openwebui_models(self) -> List[Dict[str, Any]]:
        """List models from OpenWebUI"""
        url = f"{self.openwebui_url.rstrip('/')}/api/v1/models"
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                return data.get("data", [])
        except Exception as e:
            print(f"Error listing OpenWebUI models: {e}")
            return []

    async def _call_ollama(self, prompt: str, history: Sequence[dict]):
        """Call Ollama API (non-streaming)"""
        url = f"{self.ollama_url.rstrip('/')}/api/chat"
        payload = {
            "model": self.model,
            "messages": [*history, {"role": "user", "content": prompt}],
            "stream": False,
        }
        if httpx is None:
            return self._mock_response(prompt, history)
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                message = data.get("message") or {}
                return message.get("content") or self._mock_response(prompt, history)
        except Exception as e:
            print(f"Ollama error: {e}")
            return self._mock_response(prompt, history)

    async def _stream_ollama(
        self,
        prompt: str,
        history: Sequence[dict],
        model: str
    ) -> AsyncGenerator[str, None]:
        """Stream from Ollama"""
        url = f"{self.ollama_url.rstrip('/')}/api/chat"
        payload = {
            "model": model,
            "messages": [*history, {"role": "user", "content": prompt}],
            "stream": True,
        }

        try:
            async with httpx.AsyncClient(timeout=60) as client:
                async with client.stream("POST", url, json=payload) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if line.strip():
                            try:
                                data = json.loads(line)
                                message = data.get("message", {})
                                content = message.get("content", "")
                                if content:
                                    yield content
                                if data.get("done", False):
                                    break
                            except json.JSONDecodeError:
                                continue
        except Exception as e:
            print(f"Ollama streaming error: {e}")
            yield self._mock_response(prompt, history)

    async def _list_ollama_models(self) -> List[Dict[str, Any]]:
        """List models from Ollama"""
        url = f"{self.ollama_url.rstrip('/')}/api/tags"
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                models = data.get("models", [])
                return [
                    {
                        "name": model.get("name", "unknown"),
                        "size": model.get("size", 0),
                        "modified_at": model.get("modified_at"),
                        "provider": "ollama"
                    }
                    for model in models
                ]
        except Exception as e:
            print(f"Error listing Ollama models: {e}")
            return []

    async def _get_ollama_embeddings(self, text: str, model: str) -> List[float]:
        """Get embeddings from Ollama"""
        url = f"{self.ollama_url.rstrip('/')}/api/embeddings"
        payload = {
            "model": model,
            "prompt": text,
        }

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                return data.get("embedding", [])
        except Exception as e:
            print(f"Ollama embeddings error: {e}")
            # Fallback to mock
            import hashlib
            hash_val = int(hashlib.md5(text.encode()).hexdigest(), 16)
            return [(hash_val >> i) % 100 / 100.0 for i in range(384)]

    async def generate_image(self, prompt: str, model: Optional[str] = None) -> Optional[bytes]:
        """Generate an image from a prompt."""
        model = model or self.model
        if httpx is None:
            return None  # Or return a placeholder image bytes

        if self.provider == "ollama":
            return await self._call_ollama_image(prompt, model)
        
        # Placeholder for other providers
        return None

    async def _call_ollama_image(self, prompt: str, model: str) -> Optional[bytes]:
        """Call Ollama for image generation."""
        url = f"{self.ollama_url.rstrip('/')}/api/generate"
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
        }
        if httpx is None:
            return None

        try:
            async with httpx.AsyncClient(timeout=120) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                if data.get("images"):
                    import base64
                    return base64.b64decode(data["images"][0])
                return None
        except Exception as e:
            print(f"Ollama image generation error: {e}")
            return None

    def _mock_response(self, prompt: str, history: Sequence[dict]):
        """Generate mock response"""
        return "I am a mock AI assistant. Connect me to a real backend to get started!"

    def openwebui_status(self):
        """Get OpenWebUI integration status"""
        enabled = bool(self.openwebui_url)
        return {
            "enabled": enabled,
            "url": self.openwebui_url if enabled else None,
        }

    def get_provider_info(self):
        """Get current AI provider information"""
        return {
            "provider": self.provider,
            "model": self.model,
            "ollama_url": self.ollama_url if self.provider == "ollama" else None,
            "openwebui_url": self.openwebui_url if self.provider == "openwebui" else None,
        }
