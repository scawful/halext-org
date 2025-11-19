#!/usr/bin/env python3
"""Import Pico markdown files into the Halext Org blog tables"""
import argparse
import os
from pathlib import Path
from datetime import datetime
from typing import Dict

import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "backend"))

from app.database import SessionLocal
from app import models

BLOG_ROOT = Path(os.getenv("HALX_BLOG_CONTENT_ROOT", "/www/halext.org/public/blog/content"))


def parse_markdown(path: Path) -> Dict[str, str]:
    text = path.read_text(encoding="utf-8")
    front: Dict[str, str] = {}
    body = text
    if text.startswith("---"):
        parts = text.split("---", 2)
        if len(parts) >= 3:
            body = parts[2].lstrip("\n")
            for line in parts[1].strip().splitlines():
                if ":" in line:
                    key, value = line.split(":", 1)
                    front[key.strip().lower()] = value.strip()
    return {
        "front": front,
        "body": body,
    }


def import_file(path: Path, session: SessionLocal, dry_run: bool = False) -> None:
    rel_path = path.relative_to(BLOG_ROOT).as_posix()
    parsed = parse_markdown(path)
    front = parsed["front"]
    slug = front.get("slug") or path.stem
    title = front.get("title") or slug
    if not slug:
        print(f"Skipping {path}: missing slug")
        return
    tags = []
    if "tags" in front:
        tags = [tag.strip() for tag in front["tags"].split(",") if tag.strip()]
    status = front.get("status", "draft")
    published_text = front.get("published")
    published_at = None
    if published_text:
        try:
            published_at = datetime.fromisoformat(published_text)
        except Exception:
            published_at = None
    summary = front.get("summary")

    if dry_run:
        print(f"[DRY RUN] Would import {slug} -> {rel_path}")
        return

    post = session.query(models.BlogPost).filter(models.BlogPost.slug == slug).first()
    if post:
        print(f"Updating {slug}")
    else:
        post = models.BlogPost(slug=slug, title=title, body_markdown="", tags=[], status=status)
        session.add(post)
    post.title = title
    post.summary = summary
    post.body_markdown = parsed["body"].strip()
    post.tags = tags
    post.hero_image_url = post.hero_image_url
    post.status = status
    post.published_at = published_at
    post.file_path = rel_path
    session.commit()


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Pico blog posts into the API database")
    parser.add_argument("--dry-run", action="store_true", help="Only report actions without writing to DB")
    args = parser.parse_args()

    if not BLOG_ROOT.exists():
        print(f"Blog content directory not found: {BLOG_ROOT}")
        return

    session = SessionLocal()
    try:
        for path in BLOG_ROOT.rglob("*.md"):
            import_file(path, session, dry_run=args.dry_run)
    finally:
        session.close()


if __name__ == "__main__":
    main()
