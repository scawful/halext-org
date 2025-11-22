"""
Add status field to UserPresence table

This migration adds a status field to the user_presences table to support
more granular presence states (online, away, busy, offline).
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from sqlalchemy.orm import Session
from app.database import engine

def upgrade():
    """Add status column to user_presences table."""
    with engine.connect() as conn:
        # For SQLite, check if column exists using PRAGMA
        result = conn.execute(text("PRAGMA table_info(user_presences)"))
        columns = [row[1] for row in result.fetchall()]

        if 'status' not in columns:
            try:
                # Add status column with default value
                conn.execute(text("""
                    ALTER TABLE user_presences
                    ADD COLUMN status VARCHAR DEFAULT 'online'
                """))
                print("Added 'status' column to user_presences table")

                # Update existing records to set status based on is_online
                conn.execute(text("""
                    UPDATE user_presences
                    SET status = CASE
                        WHEN is_online = 1 THEN 'online'
                        ELSE 'offline'
                    END
                """))
                print("Updated existing presence records with status values")

                conn.commit()
            except Exception as e:
                print(f"Error adding column: {e}")
                # Column might already exist
        else:
            print("Column 'status' already exists in user_presences table")


def downgrade():
    """Remove status column from user_presences table."""
    with engine.connect() as conn:
        conn.execute(text("""
            ALTER TABLE user_presences
            DROP COLUMN IF EXISTS status
        """))
        conn.commit()
        print("Removed 'status' column from user_presences table")


if __name__ == "__main__":
    upgrade()