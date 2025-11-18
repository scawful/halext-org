"""
Enhanced AI Providers with Cloud Support
Supports OpenAI, Google Gemini, Ollama, and OpenWebUI
"""
import os
from typing import Optional, List, Dict, Any, AsyncGenerator
from abc import ABC, abstractmethod
import json

try:
    import httpx
except ImportError:
    httpx = None


class AIProvider(ABC):
    """Abstract base class for AI providers"""

    @abstractmethod
    async def generate(self, prompt: str, history: List[dict], **kwargs) -> str:
        """Generate a single response"""
        pass

    @abstractmethod
    async def generate_stream(self, prompt: str, history: List[dict], **kwargs) -> AsyncGenerator[str, None]:
        """Generate streaming response"""
        pass

    @abstractmethod
    async def list_models(self) -> List[Dict[str, Any]]:
        """List available models"""
        pass


class OpenAIProvider(AIProvider):
    """OpenAI / ChatGPT provider"""

    def __init__(self, api_key: str, model: str = "gpt-4o-mini", base_url: Optional[str] = None):
        self.api_key = api_key
        self.model = model
        self.base_url = base_url or "https://api.openai.com/v1"

    async def generate(self, prompt: str, history: List[dict], **kwargs) -> str:
        if httpx is None:
            raise ImportError("httpx required for OpenAI provider")

        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        model = kwargs.get("model", self.model)
        messages = [*history, {"role": "user", "content": prompt}]

        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "temperature": kwargs.get("temperature", 0.7),
            "max_tokens": kwargs.get("max_tokens", 2000),
        }

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"]

    async def generate_stream(self, prompt: str, history: List[dict], **kwargs) -> AsyncGenerator[str, None]:
        if httpx is None:
            raise ImportError("httpx required for OpenAI provider")

        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        model = kwargs.get("model", self.model)
        messages = [*history, {"role": "user", "content": prompt}]

        payload = {
            "model": model,
            "messages": messages,
            "stream": True,
            "temperature": kwargs.get("temperature", 0.7),
            "max_tokens": kwargs.get("max_tokens", 2000),
        }

        async with httpx.AsyncClient(timeout=120) as client:
            async with client.stream("POST", url, json=payload, headers=headers) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        data_str = line[6:]
                        if data_str.strip() == "[DONE]":
                            break
                        try:
                            data = json.loads(data_str)
                            delta = data["choices"][0]["delta"]
                            content = delta.get("content", "")
                            if content:
                                yield content
                        except (json.JSONDecodeError, KeyError):
                            continue

    async def list_models(self) -> List[Dict[str, Any]]:
        if httpx is None:
            return []

        url = f"{self.base_url}/models"
        headers = {"Authorization": f"Bearer {self.api_key}"}

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(url, headers=headers)
                response.raise_for_status()
                data = response.json()
                return [
                    {
                        "name": model["id"],
                        "provider": "openai",
                        "owned_by": model.get("owned_by"),
                        "created": model.get("created")
                    }
                    for model in data.get("data", [])
                    if "gpt" in model["id"]  # Filter to GPT models
                ]
        except Exception as e:
            print(f"Error listing OpenAI models: {e}")
            return []


class GoogleGeminiProvider(AIProvider):
    """Google Gemini provider"""

    def __init__(self, api_key: str, model: str = "gemini-1.5-flash"):
        self.api_key = api_key
        self.model = model
        self.base_url = "https://generativelanguage.googleapis.com/v1beta"

    async def generate(self, prompt: str, history: List[dict], **kwargs) -> str:
        if httpx is None:
            raise ImportError("httpx required for Gemini provider")

        model = kwargs.get("model", self.model)
        url = f"{self.base_url}/models/{model}:generateContent?key={self.api_key}"

        # Convert history to Gemini format
        contents = []
        for msg in history:
            role = "user" if msg["role"] == "user" else "model"
            contents.append({
                "role": role,
                "parts": [{"text": msg["content"]}]
            })

        # Add current prompt
        contents.append({
            "role": "user",
            "parts": [{"text": prompt}]
        })

        payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": kwargs.get("temperature", 0.7),
                "maxOutputTokens": kwargs.get("max_tokens", 2048),
            }
        }

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            return data["candidates"][0]["content"]["parts"][0]["text"]

    async def generate_stream(self, prompt: str, history: List[dict], **kwargs) -> AsyncGenerator[str, None]:
        if httpx is None:
            raise ImportError("httpx required for Gemini provider")

        model = kwargs.get("model", self.model)
        url = f"{self.base_url}/models/{model}:streamGenerateContent?key={self.api_key}&alt=sse"

        # Convert history to Gemini format
        contents = []
        for msg in history:
            role = "user" if msg["role"] == "user" else "model"
            contents.append({
                "role": role,
                "parts": [{"text": msg["content"]}]
            })

        contents.append({
            "role": "user",
            "parts": [{"text": prompt}]
        })

        payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": kwargs.get("temperature", 0.7),
                "maxOutputTokens": kwargs.get("max_tokens", 2048),
            }
        }

        async with httpx.AsyncClient(timeout=120) as client:
            async with client.stream("POST", url, json=payload) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        data_str = line[6:]
                        try:
                            data = json.loads(data_str)
                            if "candidates" in data:
                                text = data["candidates"][0]["content"]["parts"][0].get("text", "")
                                if text:
                                    yield text
                        except (json.JSONDecodeError, KeyError):
                            continue

    async def list_models(self) -> List[Dict[str, Any]]:
        if httpx is None:
            return []

        url = f"{self.base_url}/models?key={self.api_key}"

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                return [
                    {
                        "name": model["name"].split("/")[-1],
                        "provider": "gemini",
                        "display_name": model.get("displayName"),
                        "description": model.get("description")
                    }
                    for model in data.get("models", [])
                    if "generateContent" in model.get("supportedGenerationMethods", [])
                ]
        except Exception as e:
            print(f"Error listing Gemini models: {e}")
            return []


class OllamaProvider(AIProvider):
    """Ollama provider (local or remote)"""

    def __init__(self, base_url: str = "http://localhost:11434", model: str = "llama3.1"):
        self.base_url = base_url
        self.model = model

    async def generate(self, prompt: str, history: List[dict], **kwargs) -> str:
        if httpx is None:
            raise ImportError("httpx required for Ollama provider")

        url = f"{self.base_url}/api/chat"
        model = kwargs.get("model", self.model)
        messages = [*history, {"role": "user", "content": prompt}]

        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": kwargs.get("temperature", 0.7),
                "num_predict": kwargs.get("max_tokens", 2000),
            }
        }

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            return data["message"]["content"]

    async def generate_stream(self, prompt: str, history: List[dict], **kwargs) -> AsyncGenerator[str, None]:
        if httpx is None:
            raise ImportError("httpx required for Ollama provider")

        url = f"{self.base_url}/api/chat"
        model = kwargs.get("model", self.model)
        messages = [*history, {"role": "user", "content": prompt}]

        payload = {
            "model": model,
            "messages": messages,
            "stream": True,
            "options": {
                "temperature": kwargs.get("temperature", 0.7),
                "num_predict": kwargs.get("max_tokens", 2000),
            }
        }

        async with httpx.AsyncClient(timeout=120) as client:
            async with client.stream("POST", url, json=payload) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.strip():
                        try:
                            data = json.loads(line)
                            content = data.get("message", {}).get("content", "")
                            if content:
                                yield content
                            if data.get("done", False):
                                break
                        except json.JSONDecodeError:
                            continue

    async def list_models(self) -> List[Dict[str, Any]]:
        if httpx is None:
            return []

        url = f"{self.base_url}/api/tags"

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                return [
                    {
                        "name": model["name"],
                        "provider": "ollama",
                        "size": model.get("size"),
                        "modified_at": model.get("modified_at"),
                        "family": model.get("details", {}).get("family")
                    }
                    for model in data.get("models", [])
                ]
        except Exception as e:
            print(f"Error listing Ollama models: {e}")
            return []


class OpenWebUIProvider(AIProvider):
    """OpenWebUI provider"""

    def __init__(self, base_url: str, model: str = "llama3.1"):
        self.base_url = base_url
        self.model = model

    async def generate(self, prompt: str, history: List[dict], **kwargs) -> str:
        if httpx is None:
            raise ImportError("httpx required for OpenWebUI provider")

        url = f"{self.base_url.rstrip('/')}/api/v1/chat/completions"
        model = kwargs.get("model", self.model)
        messages = [*history, {"role": "user", "content": prompt}]

        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
        }

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"]

    async def generate_stream(self, prompt: str, history: List[dict], **kwargs) -> AsyncGenerator[str, None]:
        if httpx is None:
            raise ImportError("httpx required for OpenWebUI provider")

        url = f"{self.base_url.rstrip('/')}/api/v1/chat/completions"
        model = kwargs.get("model", self.model)
        messages = [*history, {"role": "user", "content": prompt}]

        payload = {
            "model": model,
            "messages": messages,
            "stream": True,
        }

        async with httpx.AsyncClient(timeout=120) as client:
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

    async def list_models(self) -> List[Dict[str, Any]]:
        if httpx is None:
            return []

        url = f"{self.base_url.rstrip('/')}/api/v1/models"

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                return [
                    {
                        "name": model.get("id"),
                        "provider": "openwebui",
                        **model
                    }
                    for model in data.get("data", [])
                ]
        except Exception as e:
            print(f"Error listing OpenWebUI models: {e}")
            return []
