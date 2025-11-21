
import asyncio
import hashlib
import os
from datetime import datetime, timedelta
from typing import Any, AsyncGenerator, Dict, List, NamedTuple, Optional, Sequence, Tuple

try:  # pragma: no cover - optional dependency
    import httpx
except ImportError:  # pragma: no cover
    httpx = None

from sqlalchemy import or_
from sqlalchemy.orm import Session

from .ai_client_manager import ai_client_manager
from . import crud
from .ai_providers import (
    AIProvider,
    GoogleGeminiProvider,
    OllamaProvider,
    OpenAIProvider,
    OpenWebUIProvider,
)
from .database import SessionLocal
from .models import AIClientNode

RECENT_NODE_MINUTES = 30


class _ProviderContext(NamedTuple):
    key: str
    model: str
    identifier: str
    provider: Optional[AIProvider]
    node: Optional[AIClientNode]
    base_url: Optional[str]


class RouteInfo(NamedTuple):
    key: str
    model: str
    identifier: str
    node_id: Optional[int]
    node_name: Optional[str]


class MockProvider(AIProvider):
    '''Fallback provider used when no real integration is configured.'''

    async def generate(self, prompt: str, history: List[dict], **_: Any) -> str:
        return "I am a mock AI assistant. Connect me to a real backend to get started!"

    async def generate_stream(
        self, prompt: str, history: List[dict], **_: Any
    ) -> AsyncGenerator[str, None]:
        response = await self.generate(prompt, history)
        for word in response.split():
            yield word + " "

    async def list_models(self) -> List[Dict[str, Any]]:
        return [
            {"name": "llama3.1", "provider": "mock"},
            {"name": "mistral", "provider": "mock"},
        ]


class AiGateway:
    '''Central router that fans out to OpenAI, Gemini, Ollama clients, or OpenWebUI.'''

    def __init__(self) -> None:
        default_identifier = os.getenv("AI_DEFAULT_MODEL", "gemini:gemini-2.5-flash")
        self.provider = os.getenv("AI_PROVIDER", "gemini").lower()
        self.model = os.getenv("AI_MODEL", "gemini-2.5-flash")
        self.openwebui_url = os.getenv("OPENWEBUI_URL")
        self.openwebui_public_url = os.getenv("OPENWEBUI_PUBLIC_URL", self.openwebui_url)
        self.ollama_url = os.getenv("OLLAMA_URL", "http://localhost:11434")
        self.default_model_identifier = default_identifier

        self.providers: Dict[str, AIProvider] = {}
        self._init_providers()

        if self.default_model_identifier:
            parsed_provider, parsed_model, _ = self._parse_identifier(self.default_model_identifier)
            self.provider = parsed_provider
            self.model = parsed_model
        else:
            self.default_model_identifier = f"{self.provider}:{self.model}"

    def _init_providers(self) -> None:
        self.providers["mock"] = MockProvider()

        if self.ollama_url:
            self.providers["ollama-local"] = OllamaProvider(self.ollama_url, self.model)

        if self.openwebui_url:
            self.providers["openwebui"] = OpenWebUIProvider(self.openwebui_url, self.model)

        openai_key = os.getenv("OPENAI_API_KEY")
        if openai_key:
            openai_model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
            self.providers["openai"] = OpenAIProvider(openai_key, openai_model)

        gemini_key = os.getenv("GEMINI_API_KEY")
        if gemini_key:
            gemini_model = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
            self.providers["gemini"] = GoogleGeminiProvider(gemini_key, gemini_model)

    def _load_provider_from_db(
        self,
        provider_key: str,
        db: Optional[Session],
        user_id: Optional[int] = None,
    ) -> None:
        """Ensure cloud providers are backed by stored credentials."""
        if provider_key not in ("openai", "gemini"):
            return

        session, created = self._get_db_session(db)
        try:
            secret = crud.get_provider_secret(session, provider_key, owner_id=user_id)
        finally:
            if created:
                session.close()

        if not secret or not secret.get("api_key"):
            return

        model_name = secret.get("model")
        if provider_key == "openai":
            model_name = model_name or os.getenv("OPENAI_MODEL", "gpt-4o-mini")
            self.providers["openai"] = OpenAIProvider(secret["api_key"], model_name)
        elif provider_key == "gemini":
            model_name = model_name or os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
            self.providers["gemini"] = GoogleGeminiProvider(secret["api_key"], model_name)

        # Prefer cloud providers (OpenAI, Gemini) as the default when available
        # Only override if current provider is mock, local (ollama/openwebui), or unavailable
        if (
            self.provider in ("mock", "openwebui", "ollama-local", "ollama", "client")
            or self.provider not in self.providers
        ):
            self.provider = provider_key
            self.model = model_name
            self.default_model_identifier = f"{provider_key}:{model_name}"

    def _ensure_cloud_providers(
        self,
        db: Optional[Session],
        user_id: Optional[int] = None,
    ) -> None:
        self._load_provider_from_db("openai", db, user_id=user_id)
        self._load_provider_from_db("gemini", db, user_id=user_id)

    def _get_db_session(self, db: Optional[Session]) -> Tuple[Session, bool]:
        if db is not None:
            return db, False
        session = SessionLocal()
        return session, True

    def _parse_identifier(self, identifier: Optional[str]) -> Tuple[str, str, Optional[int]]:
        if not identifier:
            return self.provider, self.model, None

        if identifier.startswith("client:"):
            parts = identifier.split(":", 2)
            if len(parts) < 3:
                return "client", self.model, None
            try:
                node_id = int(parts[1])
            except ValueError:
                node_id = None
            model_name = parts[2] if len(parts) > 2 else self.model
            return "client", model_name, node_id

        if ":" in identifier:
            provider_key, model_name = identifier.split(":", 1)
            provider_key = provider_key or self.provider
            model_name = model_name or self.model
            return provider_key, model_name, None

        return self.provider, identifier, None

    def _build_identifier(
        self, provider_key: str, model_name: str, node: Optional[AIClientNode]
    ) -> str:
        if provider_key == "client" and node:
            return f"client:{node.id}:{model_name}"
        normalized = "ollama" if provider_key == "ollama-local" else provider_key
        return f"{normalized}:{model_name}"

    async def _resolve_provider_context(
        self,
        model_identifier: Optional[str],
        db: Optional[Session],
        user_id: Optional[int],
    ) -> _ProviderContext:
        self._ensure_cloud_providers(db, user_id=user_id)
        provider_key, model_name, node_id = self._parse_identifier(model_identifier)
        provider: Optional[AIProvider] = None
        node: Optional[AIClientNode] = None
        base_url: Optional[str] = None

        if provider_key == "client":
            node = self._get_client_node(node_id, db, user_id)
            if node:
                provider = OllamaProvider(node.base_url, model_name)
                base_url = node.base_url
            else:
                provider_key = "mock"

        elif provider_key == "openai":
            provider = self.providers.get("openai")

        elif provider_key == "gemini":
            provider = self.providers.get("gemini")

        elif provider_key in ("ollama", "ollama-local"):
            provider = self.providers.get("ollama-local")
            base_url = self.ollama_url

        elif provider_key == "openwebui":
            provider = self.providers.get("openwebui")
            base_url = self.openwebui_url

        else:
            provider = self.providers.get(provider_key)

        if provider is None:
            # Fallback to cloud providers (OpenAI, Gemini) over mock if available
            if self.providers.get("openai"):
                provider_key = "openai"
                provider = self.providers.get("openai")
                model_name = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
            elif self.providers.get("gemini"):
                provider_key = "gemini"
                provider = self.providers.get("gemini")
                model_name = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
            else:
                provider_key = "mock"
                provider = self.providers.get("mock")
                model_name = "mock"

        identifier = self._build_identifier(provider_key, model_name, node)
        return _ProviderContext(
            key=provider_key,
            model=model_name,
            identifier=identifier,
            provider=provider,
            node=node,
            base_url=base_url,
        )

    def _get_client_node(
        self,
        node_id: Optional[int],
        db: Optional[Session],
        user_id: Optional[int],
    ) -> Optional[AIClientNode]:
        if not node_id:
            return None

        session, created = self._get_db_session(db)
        try:
            query = (
                session.query(AIClientNode)
                .filter(AIClientNode.id == node_id, AIClientNode.is_active == True)
            )
            if user_id:
                query = query.filter(
                    or_(AIClientNode.owner_id == user_id, AIClientNode.is_public == True)
                )
            else:
                query = query.filter(AIClientNode.is_public == True)
            return query.first()
        finally:
            if created:
                session.close()

    def _route_from_context(self, context: _ProviderContext) -> RouteInfo:
        node_id = context.node.id if context.node else None
        node_name = context.node.name if context.node else None
        return RouteInfo(
            key=context.key,
            model=context.model,
            identifier=context.identifier,
            node_id=node_id,
            node_name=node_name,
        )

    async def generate_reply(
        self,
        prompt: str,
        history: Optional[Sequence[dict]] = None,
        model_identifier: Optional[str] = None,
        user_id: Optional[int] = None,
        db: Optional[Session] = None,
        include_context: bool = False,
    ) -> Any:
        self._ensure_cloud_providers(db, user_id=user_id)
        ctx = await self._resolve_provider_context(model_identifier, db, user_id)
        provider = ctx.provider
        payload = list(history or [])

        try:
            if provider is None:
                raise ValueError("No provider configured")
            response = await provider.generate(prompt, payload, model=ctx.model)
        except Exception as exc:  # pragma: no cover - diagnostic only
            print(f"AI provider '{ctx.key}' failed: {exc}")
            response = self._mock_response(prompt, payload)
            ctx = _ProviderContext(
                key="mock",
                model="mock",
                identifier="mock:llama3.1",
                provider=self.providers["mock"],
                node=None,
                base_url=None,
            )

        if include_context:
            return response, self._route_from_context(ctx)
        return response

    async def generate_stream(
        self,
        prompt: str,
        history: Optional[Sequence[dict]] = None,
        model_identifier: Optional[str] = None,
        user_id: Optional[int] = None,
        db: Optional[Session] = None,
    ) -> Tuple[AsyncGenerator[str, None], RouteInfo]:
        self._ensure_cloud_providers(db, user_id=user_id)
        ctx = await self._resolve_provider_context(model_identifier, db, user_id)
        provider = ctx.provider
        payload = list(history or [])

        async def iterator() -> AsyncGenerator[str, None]:
            if provider is None:
                for word in self._mock_response(prompt, payload).split():
                    yield word + " "
                return

            try:
                async for chunk in provider.generate_stream(prompt, payload, model=ctx.model):
                    yield chunk
            except Exception as exc:  # pragma: no cover - diagnostic only
                print(f"AI streaming provider '{ctx.key}' failed: {exc}")
                for word in self._mock_response(prompt, payload).split():
                    yield word + " "

        return iterator(), self._route_from_context(ctx)

    async def generate_embeddings(
        self,
        text: str,
        model_identifier: Optional[str] = None,
        user_id: Optional[int] = None,
        db: Optional[Session] = None,
    ) -> List[float]:
        self._ensure_cloud_providers(db, user_id=user_id)
        ctx = await self._resolve_provider_context(model_identifier, db, user_id)

        if ctx.key in {"client", "ollama", "ollama-local"}:
            base_url = ctx.base_url or (ctx.node.base_url if ctx.node else self.ollama_url)
            return await self._get_ollama_embeddings(text, ctx.model, base_url)

        return self._mock_embeddings(text)

    async def generate_image(
        self,
        prompt: str,
        model_identifier: Optional[str] = None,
        user_id: Optional[int] = None,
        db: Optional[Session] = None,
    ) -> Optional[bytes]:
        ctx = await self._resolve_provider_context(model_identifier, db, user_id)
        if ctx.key not in {"client", "ollama", "ollama-local"}:
            return None

        base_url = ctx.base_url or (ctx.node.base_url if ctx.node else self.ollama_url)
        return await self._call_ollama_image(prompt, ctx.model, base_url)

    async def get_models(
        self,
        db: Optional[Session] = None,
        user_id: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        self._ensure_cloud_providers(db, user_id=user_id)
        models: List[Dict[str, Any]] = []

        models.extend(await self._list_provider_models("openai"))
        models.extend(await self._list_provider_models("gemini"))
        models.extend(await self._list_provider_models("openwebui"))
        models.extend(await self._list_provider_models("ollama-local"))
        models.extend(await self._gather_client_models(db, user_id))

        if not models:
            models = [
                self._format_model_entry("mock", "llama3.1"),
                self._format_model_entry("mock", "mistral"),
            ]

        return models

    async def _list_provider_models(self, provider_key: str) -> List[Dict[str, Any]]:
        provider = self.providers.get(provider_key)
        if not provider:
            return []

        try:
            entries = await provider.list_models()
        except Exception as exc:  # pragma: no cover - network failure logging
            # Log error but don't crash - provider might be temporarily unavailable
            print(f"⚠️ Error listing models for provider '{provider_key}': {exc}")
            import traceback
            traceback.print_exc()
            entries = []

        formatted: List[Dict[str, Any]] = []
        normalized = "ollama" if provider_key == "ollama-local" else provider_key
        for entry in entries:
            name = entry.get("name") or entry.get("id")
            if not name:
                continue

            # Enrich cloud models with metadata
            model_entry = self._format_model_entry(
                normalized,
                name,
                source=normalized,
                size=entry.get("size"),
                metadata=entry,
                endpoint=self._endpoint_for_provider(normalized),
            )

            # Add enriched metadata for cloud providers
            if normalized == "openai":
                from .model_metadata import enrich_openai_model
                model_entry = enrich_openai_model(name, model_entry)
            elif normalized == "gemini":
                from .model_metadata import enrich_gemini_model
                model_entry = enrich_gemini_model(name, model_entry)

            formatted.append(model_entry)

        curated_openai = [
            "gpt-5.1",
            "gpt-5.1-codex",
            "gpt-4o",
            "gpt-4o-mini",
            "gpt-4-turbo",
            "gpt-4-turbo-preview",
        ]
        curated_gemini = [
            "gemini-2.5-pro",
            "gemini-2.5-flash",
            "gemini-1.5-pro-latest",
            "gemini-1.5-flash-latest",
        ]
        curated = curated_openai if normalized == "openai" else curated_gemini if normalized == "gemini" else []
        for name in curated:
            if any(m.get("name") == name for m in formatted):
                continue
            model_entry = self._format_model_entry(
                normalized,
                name,
                source=normalized,
                endpoint=self._endpoint_for_provider(normalized),
            )
            if normalized == "openai":
                from .model_metadata import enrich_openai_model
                model_entry = enrich_openai_model(name, model_entry)
            elif normalized == "gemini":
                from .model_metadata import enrich_gemini_model
                model_entry = enrich_gemini_model(name, model_entry)
            formatted.append(model_entry)
        return formatted

    def _endpoint_for_provider(self, provider_key: str) -> Optional[str]:
        if provider_key == "openai":
            return "https://api.openai.com"
        if provider_key == "gemini":
            return "https://generativelanguage.googleapis.com"
        if provider_key == "openwebui":
            return self.openwebui_url
        if provider_key == "ollama":
            return self.ollama_url
        return None

    async def _gather_client_models(
        self,
        db: Optional[Session],
        user_id: Optional[int],
    ) -> List[Dict[str, Any]]:
        session, created = self._get_db_session(db)
        try:
            query = session.query(AIClientNode).filter(AIClientNode.is_active == True)
            if user_id:
                query = query.filter(
                    or_(AIClientNode.owner_id == user_id, AIClientNode.is_public == True)
                )
            else:
                query = query.filter(AIClientNode.is_public == True)
            nodes = query.all()
        finally:
            if created:
                session.close()

        if not nodes:
            return []

        recent_cutoff = datetime.utcnow() - timedelta(minutes=RECENT_NODE_MINUTES)
        active_nodes = [
            n
            for n in nodes
            if n.status == "online" or (
                n.last_seen_at and n.last_seen_at >= recent_cutoff
            )
        ]

        if not active_nodes:
            return []

        tasks = [ai_client_manager.get_models_from_node(node) for node in active_nodes]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        entries: List[Dict[str, Any]] = []
        for node, models in zip(active_nodes, results):
            if isinstance(models, Exception):
                print(f"Error getting models from node '{node.name}': {models}")
                continue
            for model_name in models:
                caps = node.capabilities or {}
                latency = caps.get("last_response_time_ms") if isinstance(caps, dict) else None
                entries.append(
                    self._format_model_entry(
                        "client",
                        model_name,
                        source="client",
                        node=node,
                        endpoint=node.base_url,
                        metadata=caps if isinstance(caps, dict) else {},
                        latency_ms=latency,
                    )
                )
        return entries

    def _format_model_entry(
        self,
        provider_key: str,
        model_name: str,
        *,
        source: Optional[str] = None,
        size: Optional[Any] = None,
        metadata: Optional[Dict[str, Any]] = None,
        node: Optional[AIClientNode] = None,
        endpoint: Optional[str] = None,
        latency_ms: Optional[int] = None,
    ) -> Dict[str, Any]:
        metadata = metadata or {}
        identifier = self._build_identifier(provider_key, model_name, node)
        provider_label = "ollama" if provider_key in {"client", "ollama", "ollama-local"} else provider_key

        return {
            "id": identifier,
            "name": model_name,
            "provider": provider_label,
            "source": source or provider_label,
            "size": size,
            "node_id": node.id if node else None,
            "node_name": node.name if node else None,
            "endpoint": endpoint,
            "latency_ms": latency_ms,
            "metadata": metadata,
            "modified_at": metadata.get("modified_at") or metadata.get("created"),
        }

    async def _get_ollama_embeddings(
        self, text: str, model: str, base_url: Optional[str]
    ) -> List[float]:
        target = (base_url or "").rstrip("/")
        if not target or httpx is None:
            return self._mock_embeddings(text)

        url = f"{target}/api/embeddings"
        payload = {"model": model, "prompt": text}

        try:
            async with httpx.AsyncClient(timeout=30) as client:  # pragma: no cover - network
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                return data.get("embedding", [])
        except Exception as exc:  # pragma: no cover - diagnostic only
            print(f"Ollama embeddings error: {exc}")
            return self._mock_embeddings(text)

    async def _call_ollama_image(
        self, prompt: str, model: str, base_url: Optional[str]
    ) -> Optional[bytes]:
        target = (base_url or "").rstrip("/")
        if not target or httpx is None:
            return None

        url = f"{target}/api/generate"
        payload = {"model": model, "prompt": prompt, "stream": False}

        try:
            async with httpx.AsyncClient(timeout=120) as client:  # pragma: no cover - network
                response = await client.post(url, json=payload)
                response.raise_for_status()
                data = response.json()
                if data.get("images"):
                    import base64

                    return base64.b64decode(data["images"][0])
                return None
        except Exception as exc:  # pragma: no cover - diagnostic only
            print(f"Ollama image generation error: {exc}")
            return None

    def _mock_response(self, prompt: str, history: Sequence[dict]) -> str:
        return "I am a mock AI assistant. Connect me to a real backend to get started!"

    def _mock_embeddings(self, text: str) -> List[float]:
        hash_val = int(hashlib.md5(text.encode()).hexdigest(), 16)
        return [(hash_val >> i) % 100 / 100.0 for i in range(384)]

    def openwebui_status(self) -> Dict[str, Any]:
        enabled = bool(self.openwebui_url)
        public_url = self.openwebui_public_url if enabled else None
        return {"enabled": enabled, "url": public_url if public_url else None}

    def get_provider_info(self) -> Dict[str, Any]:
        self._ensure_cloud_providers(None)
        available = sorted(k for k in self.providers.keys() if k != "mock")
        return {
            "provider": self.provider,
            "model": self.model,
            "default_model_id": self.default_model_identifier,
            "available_providers": available,
            "ollama_url": self.ollama_url if "ollama-local" in self.providers else None,
            "openwebui_url": self.openwebui_url,
            "openwebui_public_url": self.openwebui_public_url,
        }
