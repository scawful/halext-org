"""
AI Usage Logging Helper
Tracks AI API usage for analytics, cost tracking, and model performance monitoring.
"""
from datetime import datetime
from typing import Optional
from sqlalchemy.orm import Session
from . import models


def log_ai_usage(
    db: Session,
    user_id: Optional[int],
    model_identifier: str,
    endpoint: str,
    prompt_tokens: int = 0,
    response_tokens: int = 0,
    conversation_id: Optional[int] = None,
    latency_ms: Optional[int] = None,
) -> models.AIUsageLog:
    """
    Log AI usage to the database for tracking and analytics.
    
    Args:
        db: Database session
        user_id: ID of the user making the request
        model_identifier: Model identifier (e.g., "client:1:llama3.1", "openai:gpt-4o-mini")
        endpoint: API endpoint that was called (e.g., "/ai/chat", "/ai/tasks/suggest")
        prompt_tokens: Number of tokens in the prompt (estimated)
        response_tokens: Number of tokens in the response (estimated)
        conversation_id: Optional conversation ID if this is part of a conversation
        latency_ms: Response time in milliseconds
    
    Returns:
        The created AIUsageLog entry
    """
    total_tokens = prompt_tokens + response_tokens
    
    log_entry = models.AIUsageLog(
        user_id=user_id,
        conversation_id=conversation_id,
        model_identifier=model_identifier,
        endpoint=endpoint,
        prompt_tokens=prompt_tokens,
        response_tokens=response_tokens,
        total_tokens=total_tokens,
        latency_ms=latency_ms,
    )
    
    db.add(log_entry)
    db.commit()
    db.refresh(log_entry)
    
    return log_entry


def estimate_token_count(text: str) -> int:
    """
    Rough estimate of token count for a given text.
    Uses a simple heuristic: ~4 characters per token on average.
    
    Args:
        text: The text to estimate tokens for
    
    Returns:
        Estimated token count
    """
    if not text:
        return 0
    # Simple heuristic: average of 4 characters per token
    return len(text) // 4
