#!/usr/bin/env python3
"""Validate the native WordFlow bilingual content bundled into Runner and WidgetKit."""
import json
from pathlib import Path

items = json.loads(Path("assets/content/content.json").read_text(encoding="utf-8"))
words = [x for x in items if x["kind"] == "word"]
phrases = [x for x in items if x["kind"] == "phrase"]
assert len(words) == 1500, f"Expected 1500 words; found {len(words)}"
assert len(phrases) == 24, f"Expected 24 phrases; found {len(phrases)}"
assert len({x["id"] for x in items}) == len(items), "Duplicate content id"
assert len({x["english"].casefold() for x in words}) == len(words), "Duplicate English word"
assert all(x["chinese"].strip() and x["english"].strip() for x in items), "Missing translation or English"
assert all(x["level"] in {"A2", "B1"} for x in items), "Unsupported CEFR level"
assert all(x["category"] in {"travel", "daily", "fitness", "work"} for x in items), "Bad category"
assert all(set(x) >= {"id", "kind", "category", "level", "english", "chinese", "note", "example", "exampleChinese"} for x in items), "Invalid schema"
print(f"Validated {len(words)} words and {len(phrases)} phrases ({len(items)} items).")
