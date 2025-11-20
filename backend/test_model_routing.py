#!/usr/bin/env python3
"""
Test script to verify model routing backward compatibility.
Tests that all AI endpoints still work without the model parameter (backward compatibility).
"""
import sys
import os

# Add parent directory to path to import app modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.schemas import (
    AiTaskSuggestionsRequest,
    AiEventAnalysisRequest, 
    AiNoteSummaryRequest,
    AiChatRequest
)
from datetime import datetime, timedelta


def test_backward_compatibility():
    """Test that all request schemas work without model parameter (backward compatibility)"""
    
    print("Testing backward compatibility...")
    
    # Test 1: AI Task Request without model
    print("\n1. Testing AiTaskSuggestionsRequest without model parameter...")
    task_request = AiTaskSuggestionsRequest(
        title="Complete project documentation",
        description="Write comprehensive docs for the new feature"
    )
    assert task_request.model is None, "Model should default to None"
    print("   ✓ AiTaskSuggestionsRequest works without model parameter")
    
    # Test 2: AI Task Request with model
    print("\n2. Testing AiTaskSuggestionsRequest with model parameter...")
    task_request_with_model = AiTaskSuggestionsRequest(
        title="Complete project documentation",
        description="Write comprehensive docs for the new feature",
        model="openai:gpt-4o-mini"
    )
    assert task_request_with_model.model == "openai:gpt-4o-mini", "Model should be set"
    print("   ✓ AiTaskSuggestionsRequest works with model parameter")
    
    # Test 3: AI Event Request without model
    print("\n3. Testing AiEventAnalysisRequest without model parameter...")
    event_request = AiEventAnalysisRequest(
        title="Team Meeting",
        description="Quarterly planning session",
        start_time=datetime.now(),
        end_time=datetime.now() + timedelta(hours=2)
    )
    assert event_request.model is None, "Model should default to None"
    print("   ✓ AiEventAnalysisRequest works without model parameter")
    
    # Test 4: AI Event Request with model
    print("\n4. Testing AiEventAnalysisRequest with model parameter...")
    event_request_with_model = AiEventAnalysisRequest(
        title="Team Meeting",
        description="Quarterly planning session",
        start_time=datetime.now(),
        end_time=datetime.now() + timedelta(hours=2),
        model="client:1:llama3.1"
    )
    assert event_request_with_model.model == "client:1:llama3.1", "Model should be set"
    print("   ✓ AiEventAnalysisRequest works with model parameter")
    
    # Test 5: AI Note Request without model
    print("\n5. Testing AiNoteSummaryRequest without model parameter...")
    note_request = AiNoteSummaryRequest(
        content="This is a long note that needs summarization..."
    )
    assert note_request.model is None, "Model should default to None"
    assert note_request.max_length == 200, "max_length should default to 200"
    print("   ✓ AiNoteSummaryRequest works without model parameter")
    
    # Test 6: AI Note Request with model
    print("\n6. Testing AiNoteSummaryRequest with model parameter...")
    note_request_with_model = AiNoteSummaryRequest(
        content="This is a long note that needs summarization...",
        max_length=150,
        model="gemini:gemini-1.5-flash"
    )
    assert note_request_with_model.model == "gemini:gemini-1.5-flash", "Model should be set"
    assert note_request_with_model.max_length == 150, "max_length should be 150"
    print("   ✓ AiNoteSummaryRequest works with model parameter")
    
    # Test 7: AI Chat Request without model
    print("\n7. Testing AiChatRequest without model parameter...")
    chat_request = AiChatRequest(
        prompt="Hello, how are you?"
    )
    assert chat_request.model is None, "Model should default to None"
    assert chat_request.history == [], "History should default to empty list"
    print("   ✓ AiChatRequest works without model parameter")
    
    # Test 8: AI Chat Request with model
    print("\n8. Testing AiChatRequest with model parameter...")
    chat_request_with_model = AiChatRequest(
        prompt="Hello, how are you?",
        history=[{"role": "user", "content": "Previous message"}],
        model="ollama:mistral"
    )
    assert chat_request_with_model.model == "ollama:mistral", "Model should be set"
    assert len(chat_request_with_model.history) == 1, "History should have 1 entry"
    print("   ✓ AiChatRequest works with model parameter")
    
    print("\n" + "="*60)
    print("✓ All backward compatibility tests passed!")
    print("="*60)
    return True


if __name__ == "__main__":
    try:
        success = test_backward_compatibility()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
