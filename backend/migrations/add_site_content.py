#!/usr/bin/env python3
"""Migration script to add admin flag and site content tables"""
import sys
import os
from sqlalchemy import inspect, text

# Ensure app modules are importable
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import engine
from app.models import Base


def add_is_admin_column():
    inspector = inspect(engine)
    columns = [col["name"] for col in inspector.get_columns("users")]
    if "is_admin" in columns:
        return

    dialect = engine.dialect.name
    if dialect == "sqlite":
        statement = "ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT 0"
    else:
        statement = "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE"
    with engine.connect() as conn:
        conn.execute(text(statement))
        conn.commit()
    print("Added is_admin column to users table")


def run_migration():
    print("Running site content migration...")
    add_is_admin_column()
    Base.metadata.create_all(bind=engine)
    with engine.connect() as conn:
        conn.execute(text("UPDATE users SET is_admin = 1 WHERE username IN ('scawful', 'admin')"))
        conn.commit()
    print("Site content tables ready")


if __name__ == "__main__":
    try:
        run_migration()
    except Exception as exc:
        print(f"Migration failed: {exc}")
        sys.exit(1)
