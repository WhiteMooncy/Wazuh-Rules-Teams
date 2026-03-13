#!/usr/bin/env python3
"""Validate Wazuh custom rule files in the canonical rules directory."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict, Dict, List, Tuple


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RULES_DIR = PROJECT_ROOT / "rules"
DEPRECATED_FILE = "local_rules_override.xml"


def find_rule_files(rules_dir: Path) -> List[Path]:
    return sorted(path for path in rules_dir.glob("*.xml") if path.is_file())


def parse_rules(rule_file: Path) -> List[Tuple[str, str]]:
    raw_content = rule_file.read_text(encoding="utf-8")
    root = ET.fromstring(f"<root>{raw_content}</root>")
    parsed_rules: List[Tuple[str, str]] = []

    for rule in root.iter("rule"):
        rule_id = rule.attrib.get("id")
        description = (rule.findtext("description") or "").strip()
        if rule_id:
            parsed_rules.append((rule_id, description))

    return parsed_rules


def collect_rules(rule_files: List[Path]) -> Tuple[DefaultDict[str, List[Tuple[str, str]]], Dict[str, int]]:
    rule_map: DefaultDict[str, List[Tuple[str, str]]] = defaultdict(list)
    per_file_count: Dict[str, int] = {}

    for rule_file in rule_files:
        parsed_rules = parse_rules(rule_file)
        per_file_count[rule_file.name] = len(parsed_rules)
        for rule_id, description in parsed_rules:
            rule_map[rule_id].append((rule_file.name, description))

    return rule_map, per_file_count


def print_summary(per_file_count: Dict[str, int]) -> None:
    print("Rule count by file:")
    for file_name, count in per_file_count.items():
        print(f"  - {file_name}: {count}")
    print(f"  - TOTAL: {sum(per_file_count.values())}")


def print_duplicates(rule_map: DefaultDict[str, List[Tuple[str, str]]]) -> int:
    duplicates = {rule_id: entries for rule_id, entries in rule_map.items() if len(entries) > 1}
    if not duplicates:
        print("\nNo duplicate rule IDs found.")
        return 0

    print("\nDuplicate rule IDs detected:")
    for rule_id, entries in sorted(duplicates.items()):
        print(f"  - Rule {rule_id}")
        for file_name, description in entries:
            print(f"    * {file_name}: {description or 'No description'}")
    return 1


def print_deprecated_overlap(rule_map: DefaultDict[str, List[Tuple[str, str]]]) -> int:
    overlaps = []
    for rule_id, entries in sorted(rule_map.items()):
        file_names = {file_name for file_name, _ in entries}
        if DEPRECATED_FILE in file_names and len(file_names) > 1:
            overlaps.append((rule_id, sorted(file_names)))

    if not overlaps:
        print(f"\nNo overlaps found involving {DEPRECATED_FILE}.")
        return 0

    print(f"\nDeprecated file overlaps detected in {DEPRECATED_FILE}:")
    for rule_id, file_names in overlaps:
        print(f"  - Rule {rule_id}: {', '.join(file_names)}")
    return 1


def main() -> int:
    if not RULES_DIR.exists():
        print(f"Rules directory not found: {RULES_DIR}", file=sys.stderr)
        return 1

    rule_files = find_rule_files(RULES_DIR)
    if not rule_files:
        print(f"No XML rule files found in: {RULES_DIR}", file=sys.stderr)
        return 1

    rule_map, per_file_count = collect_rules(rule_files)
    print_summary(per_file_count)
    duplicate_exit = print_duplicates(rule_map)
    overlap_exit = print_deprecated_overlap(rule_map)

    if duplicate_exit or overlap_exit:
        print("\nValidation finished with findings.")
        return 1

    print("\nValidation finished successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
