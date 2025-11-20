#!/usr/bin/env python3
"""Pretty-print the coordination board with keyword highlights."""
import os
import random
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parent.parent
BOARD = ROOT / "docs" / "internal" / "agents" / "coordination-board.md"
CHAT_TOPICS = ROOT / "docs" / "internal" / "agents" / "yaze-keep-chatting-topics.md"

COLORS = {
    "reset": "\033[0m",
    "green": "\033[32m",
    "yellow": "\033[33m",
    "red": "\033[31m",
    "cyan": "\033[36m",
}

KEYWORDS = {
    "BLOCKER": COLORS["red"],
    "REQUEST": COLORS["yellow"],
    "keep chatting": COLORS["cyan"],
}

if not BOARD.exists():
    sys.exit(f"Board file not found: {BOARD}")

content = BOARD.read_text().splitlines()
print(f"[stream] {BOARD} \n")
contains_keep_chatting = False

for line in content:
    lower = line.lower()
    colored_line = line
    for keyword, color in KEYWORDS.items():
        if keyword.lower() in lower:
            colored_line = colored_line.replace(keyword, f"{color}{keyword}{COLORS['reset']}")
            colored_line = colored_line.replace(keyword.upper(), f"{color}{keyword.upper()}{COLORS['reset']}")
            if keyword == "keep chatting":
                contains_keep_chatting = True
    print(colored_line)

if contains_keep_chatting and CHAT_TOPICS.exists():
    topics = [line.strip("- ") for line in CHAT_TOPICS.read_text().splitlines() if line.startswith("-") or line.strip().startswith("1.")]
    topics = [t for t in topics if t]
    if topics:
        suggestion = random.choice(topics)
        print("\n[stream] keep chatting detected → suggestion:")
        print(f"    {COLORS['green']}{suggestion}{COLORS['reset']}")
else:
    print("\n[stream] no keep chatting entries detected.")
