#!/usr/bin/env python3
"""
Migration script to add API keys and AI provider config tables
Run this after updating models.py
"""
import sys
import os

# Add parent directory to path so we can import from app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import engine
from app.models import Base

def run_migration():
    """Create new tables for API keys and AI provider configs"""
    print("Creating API key and AI provider config tables...")

    try:
        # This will create only the new tables if they don't exist
        Base.metadata.create_all(bind=engine)
        print("✅ Migration completed successfully!")
        print("New tables created:")
        print("  - api_keys")
        print("  - ai_provider_configs")
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    run_migration()
