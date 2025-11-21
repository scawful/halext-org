"""
Environment validation helpers for the backend runtime.
Keeps checks lightweight so startup remains fast while surfacing misconfigurations.
"""
import os
from typing import Dict, List


def validate_runtime_env(dev_mode: bool = False) -> Dict[str, object]:
    """
    Return a summary of env health: missing keys, warnings, and enabled providers.
    Does not raise; callers can log or expose this in health endpoints.
    """
    issues: List[str] = []
    warnings: List[str] = []

    db_url = os.getenv("DATABASE_URL", "sqlite:///./halext_dev.db")
    if not db_url:
        issues.append("DATABASE_URL is missing; using in-memory SQLite will break persistence.")
    elif db_url.startswith("sqlite") and db_url.endswith(":memory:"):
        warnings.append("DATABASE_URL points to in-memory SQLite; data will not persist.")

    access_code = os.getenv("ACCESS_CODE", "").strip()
    if not dev_mode and not access_code:
        warnings.append("ACCESS_CODE not set; set ACCESS_CODE or DEV_MODE=true to avoid open access.")

    ai_offline = os.getenv("AI_OFFLINE", "false").lower() == "true"

    configured_providers: List[str] = []
    missing_provider_keys: List[str] = []
    ai_provider = os.getenv("AI_PROVIDER", "").lower()

    if os.getenv("OPENAI_API_KEY"):
        configured_providers.append("openai")
    elif ai_provider.startswith("openai"):
        missing_provider_keys.append("OPENAI_API_KEY")

    if os.getenv("GEMINI_API_KEY"):
        configured_providers.append("gemini")
    elif ai_provider.startswith("gemini"):
        missing_provider_keys.append("GEMINI_API_KEY")

    if os.getenv("OPENWEBUI_URL"):
        configured_providers.append("openwebui")

    if os.getenv("OLLAMA_URL"):
        configured_providers.append("ollama")

    return {
        "issues": issues,
        "warnings": warnings,
        "configured_providers": sorted(configured_providers),
        "missing_provider_keys": sorted(set(missing_provider_keys)),
        "offline": ai_offline,
        "dev_mode": dev_mode,
    }
