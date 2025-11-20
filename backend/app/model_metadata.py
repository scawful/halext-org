"""
Model Metadata Helpers
Contains information about context windows, costs, and capabilities for various AI models
"""
from typing import Optional, Dict, Any


def enrich_openai_model(model_id: str, model_data: Dict[str, Any]) -> Dict[str, Any]:
    """Enrich OpenAI model with metadata"""
    model_data["description"] = get_openai_model_description(model_id)
    model_data["context_window"] = get_openai_context_window(model_id)
    model_data["max_output_tokens"] = get_openai_max_output(model_id)
    model_data["input_cost_per_1m"] = get_openai_input_cost(model_id)
    model_data["output_cost_per_1m"] = get_openai_output_cost(model_id)
    model_data["supports_vision"] = openai_supports_vision(model_id)
    model_data["supports_function_calling"] = openai_supports_functions(model_id)
    return model_data


def enrich_gemini_model(model_id: str, model_data: Dict[str, Any]) -> Dict[str, Any]:
    """Enrich Gemini model with metadata"""
    model_data["description"] = model_data.get("description") or get_gemini_model_description(model_id)
    model_data["context_window"] = get_gemini_context_window(model_id)
    model_data["max_output_tokens"] = get_gemini_max_output(model_id)
    model_data["input_cost_per_1m"] = get_gemini_input_cost(model_id)
    model_data["output_cost_per_1m"] = get_gemini_output_cost(model_id)
    model_data["supports_vision"] = gemini_supports_vision(model_id)
    model_data["supports_function_calling"] = True  # All Gemini models support function calling
    return model_data


# OpenAI Model Metadata
def get_openai_model_description(model_id: str) -> str:
    """Get description for OpenAI model"""
    descriptions = {
        "gpt-4o": "Most advanced multimodal model, best for complex tasks",
        "gpt-4o-mini": "Affordable and intelligent small model for fast, lightweight tasks",
        "gpt-4-turbo": "Latest GPT-4 Turbo model with vision capabilities",
        "gpt-4-turbo-preview": "GPT-4 Turbo preview with latest updates",
        "gpt-4": "GPT-4 base model, high intelligence",
        "gpt-3.5-turbo": "Fast, inexpensive model for simple tasks",
        "gpt-3.5-turbo-16k": "Extended context version of GPT-3.5 Turbo",
    }
    return descriptions.get(model_id, "OpenAI language model")


def get_openai_context_window(model_id: str) -> int:
    """Get context window size for OpenAI model"""
    windows = {
        "gpt-4o": 128000,
        "gpt-4o-mini": 128000,
        "gpt-4-turbo": 128000,
        "gpt-4-turbo-preview": 128000,
        "gpt-4": 8192,
        "gpt-3.5-turbo": 16385,
        "gpt-3.5-turbo-16k": 16385,
    }
    return windows.get(model_id, 8192)


def get_openai_max_output(model_id: str) -> int:
    """Get max output tokens for OpenAI model"""
    outputs = {
        "gpt-4o": 16384,
        "gpt-4o-mini": 16384,
        "gpt-4-turbo": 4096,
        "gpt-4-turbo-preview": 4096,
        "gpt-4": 8192,
        "gpt-3.5-turbo": 4096,
    }
    return outputs.get(model_id, 4096)


def get_openai_input_cost(model_id: str) -> Optional[float]:
    """Get cost per 1M input tokens in USD for OpenAI model"""
    costs = {
        "gpt-4o": 5.00,
        "gpt-4o-mini": 0.15,
        "gpt-4-turbo": 10.00,
        "gpt-4-turbo-preview": 10.00,
        "gpt-4": 30.00,
        "gpt-3.5-turbo": 0.50,
    }
    return costs.get(model_id)


def get_openai_output_cost(model_id: str) -> Optional[float]:
    """Get cost per 1M output tokens in USD for OpenAI model"""
    costs = {
        "gpt-4o": 15.00,
        "gpt-4o-mini": 0.60,
        "gpt-4-turbo": 30.00,
        "gpt-4-turbo-preview": 30.00,
        "gpt-4": 60.00,
        "gpt-3.5-turbo": 1.50,
    }
    return costs.get(model_id)


def openai_supports_vision(model_id: str) -> bool:
    """Check if OpenAI model supports vision"""
    vision_models = {"gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-4-vision-preview"}
    return model_id in vision_models


def openai_supports_functions(model_id: str) -> bool:
    """Check if OpenAI model supports function calling"""
    # All modern GPT models support function calling
    return "gpt-4" in model_id or "gpt-3.5" in model_id


# Gemini Model Metadata
def get_gemini_model_description(model_id: str) -> str:
    """Get description for Gemini model"""
    descriptions = {
        "gemini-1.5-pro": "Most capable Gemini model, best for complex reasoning",
        "gemini-1.5-pro-latest": "Latest Gemini 1.5 Pro with newest updates",
        "gemini-1.5-flash": "Fast and versatile performance across a variety of tasks",
        "gemini-1.5-flash-latest": "Latest Gemini 1.5 Flash with newest updates",
        "gemini-1.0-pro": "Previous generation Gemini model",
        "gemini-2.0-flash-exp": "Experimental next generation flash model",
        "gemini-exp-1206": "Experimental Gemini model released Dec 2024",
    }
    return descriptions.get(model_id, "Google Gemini model")


def get_gemini_context_window(model_id: str) -> int:
    """Get context window size for Gemini model"""
    windows = {
        "gemini-1.5-pro": 2000000,  # 2M tokens
        "gemini-1.5-pro-latest": 2000000,
        "gemini-1.5-flash": 1000000,  # 1M tokens
        "gemini-1.5-flash-latest": 1000000,
        "gemini-1.0-pro": 32760,
        "gemini-2.0-flash-exp": 1000000,
        "gemini-exp-1206": 2000000,
    }
    # Default to 1M for unknown Gemini models
    for key in windows:
        if key in model_id:
            return windows[key]
    return 1000000


def get_gemini_max_output(model_id: str) -> int:
    """Get max output tokens for Gemini model"""
    outputs = {
        "gemini-1.5-pro": 8192,
        "gemini-1.5-pro-latest": 8192,
        "gemini-1.5-flash": 8192,
        "gemini-1.5-flash-latest": 8192,
        "gemini-1.0-pro": 2048,
        "gemini-2.0-flash-exp": 8192,
        "gemini-exp-1206": 8192,
    }
    return outputs.get(model_id, 8192)


def get_gemini_input_cost(model_id: str) -> Optional[float]:
    """Get cost per 1M input tokens in USD for Gemini model"""
    costs = {
        "gemini-1.5-pro": 1.25,  # <= 128K context
        "gemini-1.5-pro-latest": 1.25,
        "gemini-1.5-flash": 0.075,  # <= 128K context
        "gemini-1.5-flash-latest": 0.075,
        "gemini-1.0-pro": 0.50,
    }
    # Experimental models are free during preview
    if "exp" in model_id or "gemini-2.0" in model_id:
        return 0.0
    return costs.get(model_id)


def get_gemini_output_cost(model_id: str) -> Optional[float]:
    """Get cost per 1M output tokens in USD for Gemini model"""
    costs = {
        "gemini-1.5-pro": 5.00,
        "gemini-1.5-pro-latest": 5.00,
        "gemini-1.5-flash": 0.30,
        "gemini-1.5-flash-latest": 0.30,
        "gemini-1.0-pro": 1.50,
    }
    if "exp" in model_id or "gemini-2.0" in model_id:
        return 0.0
    return costs.get(model_id)


def gemini_supports_vision(model_id: str) -> bool:
    """Check if Gemini model supports vision"""
    # All Gemini 1.5+ models support vision
    return "gemini-1.5" in model_id or "gemini-2.0" in model_id or "gemini-exp" in model_id


# Model Recommendations
def get_recommended_test_models() -> Dict[str, str]:
    """Get recommended lightweight models for testing"""
    return {
        "openai": "gpt-3.5-turbo",
        "gemini": "gemini-1.5-flash",
    }


def get_recommended_production_models() -> Dict[str, str]:
    """Get recommended production-grade models"""
    return {
        "openai": "gpt-4o-mini",
        "gemini": "gemini-1.5-pro",
    }


def get_model_tier(model_id: str) -> str:
    """Get the tier/category of a model (lightweight, standard, premium)"""
    if "gpt-3.5" in model_id or "flash" in model_id:
        return "lightweight"
    elif "gpt-4o-mini" in model_id or "gemini-1.5-pro" in model_id:
        return "standard"
    elif "gpt-4o" in model_id or "gpt-4-turbo" in model_id:
        return "premium"
    elif "gpt-4" in model_id:
        return "premium"
    else:
        return "unknown"
