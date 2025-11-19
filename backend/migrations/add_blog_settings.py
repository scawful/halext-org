#!/usr/bin/env python3
"""Migration script for blog file path column and site settings table"""
import os
import sys
from sqlalchemy import inspect, text

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import engine
from app.models import Base


def add_blog_file_path_column():
    inspector = inspect(engine)
    columns = [col["name"] for col in inspector.get_columns("blog_posts")]
    if "file_path" in columns:
        return
    dialect = engine.dialect.name
    if dialect == "sqlite":
        statement = "ALTER TABLE blog_posts ADD COLUMN file_path VARCHAR"
    else:
        statement = "ALTER TABLE blog_posts ADD COLUMN IF NOT EXISTS file_path VARCHAR"
    with engine.connect() as conn:
        conn.execute(text(statement))
        conn.commit()
    print("Added file_path column to blog_posts table")


def run_migration():
    print("Running blog settings migration...")
    add_blog_file_path_column()
    Base.metadata.create_all(bind=engine)
    print("Blog settings migration complete")


if __name__ == "__main__":
    try:
        run_migration()
    except Exception as exc:
        print(f"Migration failed: {exc}")
        sys.exit(1)
