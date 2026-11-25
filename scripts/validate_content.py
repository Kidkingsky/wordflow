#!/usr/bin/env python3
"""Validate the native WordFlow bilingual content bundled into Runner and WidgetKit."""
import json
from pathlib import Path

base = json.loads(Path("assets/content/content.json").read_text(encoding="utf-8"))
course = json.loads(Path("assets/content/course_content.json").read_text(encoding="utf-8"))
assert len({x["id"] for x in base}) == len(base), "Duplicate base ID"
assert len({x["id"] for x in course["items"]}) == len(course["items"]), "Duplicate course ID"
merged = {x["id"]: x for x in base}
for item in course["items"]:
    if item["id"] in merged:
        old = merged[item["id"]]
        assert old["english"] == item["english"] and old["kind"] == item["kind"], "Changed existing identity"
    merged[item["id"]] = item
items = list(merged.values())
words = [x for x in items if x["kind"] == "word"]
phrases = [x for x in items if x["kind"] == "phrase"]
assert len(words) >= 1500, f"Expected at least 1500 words; found {len(words)}"
assert len(phrases) >= 24, f"Expected at least 24 phrases; found {len(phrases)}"
assert len({x["id"] for x in items}) == len(items), "Duplicate content id"
assert len({x["english"].casefold() for x in words}) == len(words), "Duplicate English word"
assert all(x["chinese"].strip() and x["english"].strip() for x in items), "Missing translation or English"
assert all(x["level"] in {"A2", "B1"} for x in items), "Unsupported CEFR level"
assert all(x["category"] in {"travel", "daily", "fitness", "work"} for x in items), "Bad category"
assert all(set(x) >= {"id", "kind", "category", "level", "english", "chinese", "note", "example", "exampleChinese"} for x in items), "Invalid schema"
lessons = course["lessons"]
assert len({x["id"] for x in lessons}) == len(lessons), "Duplicate lesson IDs"
for lesson in lessons:
    assert lesson["level"] in {"A2", "B1"} and lesson["category"] in {"daily", "travel", "fitness", "work"}
    assert lesson["title"].strip() and lesson["objective"].strip()
    assert len(lesson["wordIds"]) == 4 and len(lesson["phraseIds"]) >= 2
    assert len(set(lesson["wordIds"] + lesson["phraseIds"])) == len(lesson["wordIds"] + lesson["phraseIds"])
    for kind in ("word", "phrase"):
        for item_id in lesson[kind + "Ids"]:
            item = merged[item_id]
            assert item["kind"] == kind, f"Wrong lesson item type: {item_id}"
            assert item["example"].strip() and item["exampleChinese"].strip(), f"No example: {item_id}"
assert all(any(l["level"] == level and l["category"] == category for l in lessons)
           for level in ("A2", "B1") for category in ("daily", "travel", "fitness", "work"))
patterns = course["patterns"]
lesson_phrases = {item_id for lesson in lessons for item_id in lesson["phraseIds"]}
assert lesson_phrases <= patterns.keys(), "Every course phrase needs sentence structure"
def normalized(text):
    return text.casefold().replace("’", "'")
for phrase_id, pattern in patterns.items():
    item = merged[phrase_id]
    assert item["kind"] == "phrase", f"Pattern is not attached to a phrase: {phrase_id}"
    assert all(pattern[k].strip() for k in ("formula", "usage", "tip")), phrase_id
    assert len(pattern["focus"]) >= 2, phrase_id
    for word in pattern["focus"]:
        assert word["chinese"].strip() and word["english"].strip()
        assert normalized(word["english"]) in normalized(item["english"] + " " + item["example"]), (phrase_id, word)
    assert {"daily", "work", "fitness"} <= {example["category"] for example in pattern["examples"]}, phrase_id
    assert len({example["category"] for example in pattern["examples"]}) == len(pattern["examples"]), phrase_id
    for example in pattern["examples"]:
        assert example["english"].strip() and example["chinese"].strip(), phrase_id
print(f"Validated {len(words)} words and {len(phrases)} phrases ({len(items)} items), {len(lessons)} lessons.")
print(f"Validated {len(patterns)} sentence patterns, {sum(len(p['examples']) for p in patterns.values())} transfer examples.")

# Word families (同家族單字): every family must link to at least one bundled word,
# and every entry needs English, Chinese and a formation hint.
families = json.loads(Path("assets/content/word_families.json").read_text(encoding="utf-8"))
library = {x["english"].casefold() for x in words}
assert len({f["id"] for f in families}) == len(families), "Duplicate family id"
for f in families:
    assert f["root"].strip() and f["meaning"].strip(), f"Family {f['id']} missing root/meaning"
    assert f["members"], f"Family {f['id']} has no members"
    for m in f["members"]:
        assert m["english"].strip() and m["chinese"].strip() and m["hint"].strip(), f"Bad member in {f['id']}: {m}"
    spellings = [f["root"]] + [m["english"] for m in f["members"]]
    assert any(s.casefold() in library for s in spellings), f"Family {f['id']} matches no bundled word"
print(f"Validated {len(families)} word families.")
