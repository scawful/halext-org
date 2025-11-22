"""
Migration: Add budget progress tracking fields to finance_budgets table

This migration enhances the finance_budgets table with:
- start_date/end_date: Explicit period boundaries for budget tracking
- is_active: Toggle for active/inactive budgets
- goal_amount: Optional savings/spending goal amount
- rollover_enabled: Carry over unused budget to next period
- alert_threshold: Percentage threshold for budget alerts (default 80%)

To run this migration:
    python -m backend.migrations.add_budget_progress_fields
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from sqlalchemy import text
from backend.app.database import SessionLocal


def column_exists(db, table_name: str, column_name: str) -> bool:
    """Check if a column exists in a SQLite table."""
    result = db.execute(text(f"""
        SELECT COUNT(*)
        FROM pragma_table_info('{table_name}')
        WHERE name='{column_name}'
    """))
    return result.scalar() > 0


def upgrade():
    """Add budget progress tracking columns to finance_budgets table"""
    print("Running migration: Add budget progress tracking fields")

    db = SessionLocal()
    try:
        columns_to_add = [
            ("start_date", "DATETIME NULL"),
            ("end_date", "DATETIME NULL"),
            ("is_active", "BOOLEAN DEFAULT 1"),
            ("goal_amount", "FLOAT NULL"),
            ("rollover_enabled", "BOOLEAN DEFAULT 0"),
            ("alert_threshold", "FLOAT DEFAULT 0.8"),
        ]

        added = []
        skipped = []

        for col_name, col_def in columns_to_add:
            if column_exists(db, "finance_budgets", col_name):
                skipped.append(col_name)
                continue

            db.execute(text(f"""
                ALTER TABLE finance_budgets
                ADD COLUMN {col_name} {col_def}
            """))
            added.append(col_name)

        db.commit()

        if added:
            print(f"Successfully added columns: {', '.join(added)}")
        if skipped:
            print(f"Columns already exist (skipped): {', '.join(skipped)}")

        print("Migration completed successfully")

    except Exception as e:
        print(f"Error running migration: {e}")
        db.rollback()
        raise
    finally:
        db.close()


def downgrade():
    """Remove budget progress tracking columns from finance_budgets table"""
    print("Running downgrade: Remove budget progress tracking fields")

    db = SessionLocal()
    try:
        # SQLite doesn't support DROP COLUMN directly in older versions
        # For SQLite 3.35.0+ (2021-03-12), DROP COLUMN is supported
        # But for safety, we'll warn the user

        columns_to_remove = [
            "start_date",
            "end_date",
            "is_active",
            "goal_amount",
            "rollover_enabled",
            "alert_threshold",
        ]

        print("WARNING: SQLite has limited support for dropping columns.")
        print("To fully revert this migration, you may need to:")
        print("1. Create a new table without these columns")
        print("2. Copy data from the old table")
        print("3. Drop the old table and rename the new one")
        print("")
        print(f"Columns that would be removed: {', '.join(columns_to_remove)}")

        # Attempt to drop columns (works in SQLite 3.35.0+)
        for col_name in columns_to_remove:
            try:
                db.execute(text(f"ALTER TABLE finance_budgets DROP COLUMN {col_name}"))
                print(f"Dropped column: {col_name}")
            except Exception as e:
                print(f"Could not drop column {col_name}: {e}")

        db.commit()

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
