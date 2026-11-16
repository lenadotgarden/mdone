#!/usr/bin/env python3
"""Fail when a user-facing string of the Things code has no French translation.

Scans the Things files (Features/Things, Platform/*/Things*, DesignSystem/
Components/Things, Domain/Mapping) for `String(localized:)`, `Text("...")`,
`Button("...")`, `Label("...")`, `TextField("...")`, `.help("...")`, menus and
accessibility labels, then checks each literal against
mDone/Localizable.xcstrings: the key must exist and carry an `fr` value.

Literals that are previews or sample data are skipped through SKIP below.
Run: scripts/check-things-localization.py   (no dependency, stdlib only)
"""

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CATALOG = REPO / "mDone" / "Localizable.xcstrings"
LANG = "fr"

# Sample data used by previews. Never shown to a user.
SKIP = {
    "Buy bread", "Call Kate", "Canceled item", "Done item", "Errand", "Home",
    "Important", "Next actions", "Nothing for today", "Selected",
    "Someday idea", "Website", "Write the quarterly report",
    "Enjoy the free time.", "Numbers from finance first",
}

PATTERN = re.compile(
    r'(?:String\(localized:\s*|\bText\(|\.help\(|Button\(|Label\(|TextField\(|'
    r'Toggle\(|Section\(|Menu\(|navigationTitle\(|accessibilityLabel\(|'
    r'accessibilityHint\(|prompt:\s*|title:\s*|CommandMenu\()\s*'
    r'"((?:[^"\\]|\\.)*)"'
)


def things_files():
    roots = [
        REPO / "mDone" / "Features" / "Things",
        REPO / "mDone" / "DesignSystem" / "Components" / "Things",
        REPO / "mDone" / "Domain" / "Mapping",
        REPO / "mDone" / "Platform" / "macOS",
        REPO / "mDone" / "Platform" / "iOS",
    ]
    for root in roots:
        for path in sorted(root.rglob("*.swift")):
            if "Things" in path.name:
                yield path


def has_french(strings, key):
    entry = strings.get(key)
    if not entry:
        return False
    return LANG in entry.get("localizations", {})


def key_candidates(literal):
    """Catalog keys a Swift literal can compile to (interpolation placeholders)."""
    literal = literal.replace("\\u{201C}", "\u201c").replace("\\u{201D}", "\u201d")
    if "\\(" not in literal:
        return [literal]
    pieces, depth, current, index = [], 0, "", 0
    while index < len(literal):
        if depth == 0 and literal.startswith("\\(", index):
            pieces.append(current)
            current, depth, index = "", 1, index + 2
        elif depth > 0:
            depth += {"(": 1, ")": -1}.get(literal[index], 0)
            index += 1
        else:
            current += literal[index]
            index += 1
    pieces.append(current)
    # An interpolation is a string (%@) or an integer (%lld); try every mix.
    out = [pieces[0]]
    for piece in pieces[1:]:
        out = [base + spec + piece for base in out for spec in ("%@", "%lld")]
    return out


def main():
    strings = json.loads(CATALOG.read_text(encoding="utf-8"))["strings"]
    problems = []
    for path in things_files():
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.strip().startswith("//"):
                continue
            for match in PATTERN.finditer(line):
                before = line[max(0, match.start() - 14):match.end()]
                if "verbatim" in before:
                    continue
                literal = match.group(1)
                if literal in SKIP or not re.search(r"[A-Za-z]{2,}", literal):
                    continue
                if not any(has_french(strings, k) for k in key_candidates(literal)):
                    problems.append(f"{path.relative_to(REPO)}:{number}: no {LANG} for {literal!r}")
    if problems:
        print("\n".join(problems))
        print(f"{len(problems)} string(s) without a {LANG} translation")
        return 1
    print(f"Things strings: all have a {LANG} translation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
