"""
Migration: Add default_model_id to conversations table

This migration adds the ability for conversations to have a default AI model
that will be used for all AI responses in that conversation unless overridden
on a per-message basis.

To run this migration:
    python -m backend.migrations.add_conversation_default_model
"""

import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from sqlalchemy import text
from backend.app.database import SessionLocal, engine


def upgrade():
    """Add default_model_id column to conversations table"""
    print("Running migration: Add default_model_id to conversations")
    
    db = SessionLocal()
    try:
        # Check if column already exists
        result = db.execute(text("""
            SELECT COUNT(*) 
            FROM pragma_table_info('conversations') 
            WHERE name='default_model_id'
        """))
        exists = result.scalar() > 0
        
        if exists:
            print("Column 'default_model_id' already exists, skipping migration")
            return
        
        # Add the column
        db.execute(text("""
            ALTER TABLE conversations 
            ADD COLUMN default_model_id VARCHAR NULL
        """))
        db.commit()
        
        print("Successfully added default_model_id column to conversations table")
        
    except Exception as e:
        print(f"Error running migration: {e}")
        db.rollback()
        raise
    finally:
        db.close()


def downgrade():
    """Remove default_model_id column from conversations table"""
    print("Running downgrade: Remove default_model_id from conversations")
    
    db = SessionLocal()
    try:
        # SQLite doesn't support DROP COLUMN directly, need to recreate table
        # For now, just warn the user
        print("WARNING: SQLite does not support dropping columns.")
        print("To fully revert, you would need to recreate the table without the column.")
        print("This is typically not necessary unless you're debugging.")
        
    except Exception as e:
        print(f"Error running downgrade: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "downgrade":
        downgrade()
    else:
        upgrade()
