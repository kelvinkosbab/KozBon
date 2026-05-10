#!/usr/bin/env python3
"""Validate KozBon's localized string catalog against the Swift code that
consumes it. Four hard checks, each reported on stderr:

1. `Localizable.xcstrings` is valid JSON.
2. Every key in the catalog has translations in all 6 expected locales
   (en, es, fr, de, ja, zh-Hans). Missing translations would surface
   to users as the raw English fallback or, worse, the literal key.
3. Every `.init("key", bundle: ...)` and `NSLocalizedString("key", ...)`
   reference in `Strings.swift` resolves to a key in the catalog, and
   no catalog entry is unreferenced. Drift here means either Swift
   code at runtime returns the literal key, or the catalog has dead
   translations no one consumes.
4. Every `detail: "..."` literal in the service-type library exists as
   a catalog key (the string itself is the key, via
   `BonjourServiceType.localizedDetail`). Drift here downgrades
   non-English users to English for that one service.

Exits 0 on success, 1 on any failure. Run locally:

    python3 scripts/validate-localizations.py

CI invokes this in `.github/workflows/localizations.yml` on every PR
that touches the catalog, `Strings.swift`, or the service-type library.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CATALOG_PATH = (
    REPO_ROOT
    / "KozBonPackages/BonjourLocalization/Sources/Resources/Localizable.xcstrings"
)
STRINGS_SWIFT_PATH = (
    REPO_ROOT / "KozBonPackages/BonjourLocalization/Sources/Strings.swift"
)
# Service-type detail strings double as catalog keys via
# `BonjourServiceType.localizedDetail`, which calls
# `String(localized: String.LocalizationValue(detail), bundle: ...)`. Every
# `detail: "..."` literal in the library is therefore a live reference into the
# catalog — we need to harvest them or the orphan check produces ~150 false
# positives.
LIBRARY_PATH = (
    REPO_ROOT
    / "KozBonPackages/BonjourModels/Sources/ServiceType/MyServiceType+Library.swift"
)

# The six languages KozBon ships in. Adding a new language means adding
# entries to every existing key in the catalog AND extending this set;
# the validator will then start failing for any key still missing the
# new locale, which is exactly what we want.
EXPECTED_LOCALES = frozenset({"en", "es", "fr", "de", "ja", "zh-Hans"})


def load_catalog() -> dict | None:
    """Parse the .xcstrings file. Returns the dict on success, None on
    JSON failure (already reported to stderr)."""
    try:
        with CATALOG_PATH.open() as f:
            return json.load(f)
    except FileNotFoundError:
        print(
            f"ERROR: Localizable.xcstrings not found at {CATALOG_PATH}",
            file=sys.stderr,
        )
        return None
    except json.JSONDecodeError as exc:
        print(
            f"ERROR: Localizable.xcstrings is not valid JSON: {exc}",
            file=sys.stderr,
        )
        return None


def check_translation_completeness(catalog: dict) -> list[str]:
    """Return a list of error lines for any key missing a locale."""
    failures: list[str] = []
    for key, entry in catalog.get("strings", {}).items():
        localizations = entry.get("localizations", {})
        present = frozenset(localizations.keys())
        missing = EXPECTED_LOCALES - present
        if missing:
            failures.append(f"  {key}: missing {', '.join(sorted(missing))}")
    return failures


# Regex matches the two ways KozBon references catalog keys from Swift:
#
#   .init("nav_nearby_services", bundle: ...)        — LocalizedStringResource
#   NSLocalizedString("chat_confirm_...", bundle:..) — String(format:) callers
#
# Both patterns put the key as the first string literal argument.
_LSR_PATTERN = re.compile(r'\.init\(\s*"([^"]+)"\s*,\s*bundle:')
_NSLOCALIZED_PATTERN = re.compile(r'NSLocalizedString\(\s*"([^"]+)"')

# Service-type library entries: `detail: "literal English description"`. The
# string itself is the catalog key — see `BonjourServiceType.localizedDetail`.
_DETAIL_PATTERN = re.compile(r'detail:\s*"((?:[^"\\]|\\.)*)"')


def extract_swift_keys() -> set[str]:
    """Parse Strings.swift and return every catalog key it references."""
    text = STRINGS_SWIFT_PATH.read_text()
    keys = set(_LSR_PATTERN.findall(text))
    keys |= set(_NSLOCALIZED_PATTERN.findall(text))
    return keys


# Swift string-literal escape sequences we expect to encounter in the
# library. Anything else is rare enough that we'd rather fail loudly than
# silently miscompare. We deliberately don't use `unicode_escape` because it
# treats the input as Latin-1, mangling multi-byte UTF-8 (e.g. em-dashes,
# accented characters) — which the library uses heavily.
_SWIFT_ESCAPES = {
    r"\\": "\\",
    r"\"": '"',
    r"\n": "\n",
    r"\t": "\t",
    r"\r": "\r",
    r"\0": "\0",
}


def _unescape_swift_string(literal: str) -> str:
    """Convert escape sequences in a Swift string literal to their resolved
    characters, preserving non-ASCII bytes verbatim."""
    result = []
    i = 0
    while i < len(literal):
        if literal[i] == "\\" and i + 1 < len(literal):
            pair = literal[i : i + 2]
            if pair in _SWIFT_ESCAPES:
                result.append(_SWIFT_ESCAPES[pair])
                i += 2
                continue
        result.append(literal[i])
        i += 1
    return "".join(result)


def extract_library_detail_keys() -> set[str]:
    """Parse the service-type library and return every `detail:` literal.

    These strings serve as catalog keys via `localizedDetail` — anything
    matched here is a live reference into the catalog, even though it never
    appears in `Strings.swift`."""
    text = LIBRARY_PATH.read_text()
    return {_unescape_swift_string(match) for match in _DETAIL_PATTERN.findall(text)}


def main() -> int:
    catalog = load_catalog()
    if catalog is None:
        return 1

    failures: list[str] = []

    # Check 2: translation completeness across all expected locales.
    missing_translations = check_translation_completeness(catalog)
    if missing_translations:
        failures.append("Missing translations:")
        failures.extend(missing_translations)

    # Check 3 & 4: catalog ↔ source drift. KozBon references catalog keys
    # from two places — explicit `Strings.*` accessors in `Strings.swift`,
    # and the service-type library where each `detail: "..."` literal is
    # itself the catalog key (resolved at runtime via `localizedDetail`).
    catalog_keys = frozenset(catalog.get("strings", {}).keys())
    swift_keys = extract_swift_keys()
    library_keys = extract_library_detail_keys()
    referenced_keys = swift_keys | library_keys
    dangling_swift = sorted(swift_keys - catalog_keys)
    dangling_library = sorted(library_keys - catalog_keys)
    orphaned = sorted(catalog_keys - referenced_keys)

    if dangling_swift:
        failures.append("Strings.swift references keys missing from the catalog:")
        for key in dangling_swift:
            failures.append(f"  {key}")

    if dangling_library:
        failures.append(
            "Service-type library `detail` strings missing from the catalog "
            "(non-English users will see English for these — runtime fallback "
            "via `localizedDetail`):"
        )
        for key in dangling_library:
            failures.append(f"  {key}")

    if orphaned:
        failures.append(
            "Catalog entries not referenced by Strings.swift or the service-type "
            "library (dead):"
        )
        for key in orphaned:
            failures.append(f"  {key}")

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1

    print(
        f"OK: {len(catalog_keys)} keys validated across "
        f"{len(EXPECTED_LOCALES)} locales; "
        f"{len(swift_keys)} Swift references and "
        f"{len(library_keys)} service-type details resolved."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
