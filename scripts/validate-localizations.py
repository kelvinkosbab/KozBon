#!/usr/bin/env python3
"""Validate KozBon's localized string catalogs against the Swift code that
consumes them. Seven hard checks, each reported on stderr:

1. `Localizable.xcstrings` is valid JSON.
2. Every key in the catalog has translations in all expected locales
   (see `EXPECTED_LOCALES`). Missing translations would surface
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
5. `InfoPlist.xcstrings` is valid JSON and locale-complete. These are
   the system-presented permission prompts (`NSLocalNetworkUsage-
   Description`, `NSSiriUsageDescription`); a missing locale means iOS
   shows an English prompt in an otherwise localized alert. Entries
   marked "do not translate" (the app's brand name) are exempt.
6. `KozBon/Localizable.xcstrings` is valid JSON and locale-complete.
   This is the app target's own catalog, which backs the App Intents
   surface (Siri phrasing, Spotlight keywords, the Shortcuts action
   editor). App Intents strings cannot live in `BonjourLocalization` —
   the compiler requires them to resolve against the main bundle.
7. `AppShortcuts.xcstrings` is valid JSON, locale-complete, and every
   translated Siri phrase keeps the `${applicationName}` token. These
   must live in the app target — Xcode disables App Shortcut
   localization for SPM targets.

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
# The app target's Info.plist string catalog. Unlike `Localizable.xcstrings`,
# nothing in Swift references these keys — iOS reads them directly when it
# presents a permission prompt — so only the locale-completeness check
# (check 2) applies here, not the source-drift checks (3 and 4).
INFO_PLIST_CATALOG_PATH = REPO_ROOT / "KozBon/InfoPlist.xcstrings"
# The app target's own catalog. App Intents strings are forced to live here
# rather than in `BonjourLocalization`: the compiler rejects a
# `LocalizedStringResource` pointing at a package bundle with "AppIntents
# requires 'LocalizedStringResource' to use the main bundle". Same
# locale-completeness rule, no Swift-side reference check — the keys are
# referenced from `BonjourAppIntents`, not `Strings.swift`.
APP_TARGET_CATALOG_PATH = REPO_ROOT / "KozBon/Localizable.xcstrings"
# Spoken Siri phrases for the App Shortcuts. Must live in the app target:
# Xcode passes `--no-app-shortcuts-localization` to the App Intents extractor
# for every SPM target and omits it only for the app target, so a provider
# declared in a package cannot be localized (and doesn't reach
# `Metadata.appintents` at all).
APP_SHORTCUTS_CATALOG_PATH = REPO_ROOT / "KozBon/AppShortcuts.xcstrings"
# Siri substitutes the app name for this token. A translation that drops it
# yields a phrase with no app name, which Siri cannot match to this app.
APP_NAME_TOKEN = "${applicationName}"
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

# The languages KozBon ships in. Adding a new language means adding
# entries to every existing key in the catalog AND extending this set;
# the validator will then start failing for any key still missing the
# new locale, which is exactly what we want.
#
# `ar` (Arabic) and `he` (Hebrew) are right-to-left — adding them at the
# string-catalog layer is the first step; mirroring SwiftUI layout
# (`.environment(\.layoutDirection, .rightToLeft)`, directional symbol
# flipping, leading/trailing audits) is the second.
EXPECTED_LOCALES = frozenset({"en", "es", "fr", "de", "ja", "zh-Hans", "ar", "he"})


def load_catalog(path: Path = CATALOG_PATH) -> dict | None:
    """Parse a .xcstrings file. Returns the dict on success, None on
    JSON failure (already reported to stderr)."""
    try:
        with path.open() as f:
            return json.load(f)
    except FileNotFoundError:
        print(
            f"ERROR: {path.name} not found at {path}",
            file=sys.stderr,
        )
        return None
    except json.JSONDecodeError as exc:
        print(
            f"ERROR: {path.name} is not valid JSON: {exc}",
            file=sys.stderr,
        )
        return None


def is_do_not_translate(entry: dict) -> bool:
    """True when the entry's comment marks it as untranslatable.

    Xcode's String Catalog editor tags an entry "Don't Translate" when its
    comment contains this phrase, and exports it as `translate="no"` in
    XLIFF. Brand names (`CFBundleName`) live here — demanding 8 locales for
    a string that must stay "KozBon" everywhere would be a permanent,
    unfixable failure."""
    return "do not translate" in (entry.get("comment") or "").lower()


def check_app_name_token(catalog: dict) -> list[str]:
    """Every Siri phrase whose source contains the app-name token must keep
    it in each translation.

    Dropping `${applicationName}` produces a phrase with no app name in it.
    Siri has nothing to match against this app, so the shortcut silently
    stops being reachable by voice in that language — a failure no build
    step or runtime error surfaces."""
    failures: list[str] = []
    for key, entry in catalog.get("strings", {}).items():
        if APP_NAME_TOKEN not in key:
            continue
        for locale, localization in sorted(entry.get("localizations", {}).items()):
            value = localization.get("stringUnit", {}).get("value", "")
            if APP_NAME_TOKEN not in value:
                failures.append(f"  {key!r} [{locale}]: dropped {APP_NAME_TOKEN}")
    return failures


def check_translation_completeness(catalog: dict) -> list[str]:
    """Return a list of error lines for any key missing a locale."""
    failures: list[str] = []
    for key, entry in catalog.get("strings", {}).items():
        if is_do_not_translate(entry):
            continue
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

    # Check 5: the app target's Info.plist catalog. Locale completeness only —
    # iOS resolves these keys itself, so there is no Swift side to drift from.
    info_plist_catalog = load_catalog(INFO_PLIST_CATALOG_PATH)
    if info_plist_catalog is None:
        return 1

    info_plist_missing = check_translation_completeness(info_plist_catalog)
    if info_plist_missing:
        failures.append(
            "InfoPlist.xcstrings missing translations (iOS shows the English "
            "permission prompt for these locales):"
        )
        failures.extend(info_plist_missing)

    # Check 6: the app target's catalog, which backs the App Intents surface
    # (Siri, Spotlight, the Shortcuts action editor).
    app_target_catalog = load_catalog(APP_TARGET_CATALOG_PATH)
    if app_target_catalog is None:
        return 1

    app_target_missing = check_translation_completeness(app_target_catalog)
    if app_target_missing:
        failures.append(
            "KozBon/Localizable.xcstrings missing translations (Siri and the "
            "Shortcuts app fall back to English for these locales):"
        )
        failures.extend(app_target_missing)

    # Check 7: the spoken Siri phrases — locale-complete, and every
    # translation keeps the app-name token Siri matches against.
    app_shortcuts_catalog = load_catalog(APP_SHORTCUTS_CATALOG_PATH)
    if app_shortcuts_catalog is None:
        return 1

    shortcuts_missing = check_translation_completeness(app_shortcuts_catalog)
    if shortcuts_missing:
        failures.append(
            "AppShortcuts.xcstrings missing translations (Siri only accepts "
            "the English phrasing for these locales):"
        )
        failures.extend(shortcuts_missing)

    dropped_token = check_app_name_token(app_shortcuts_catalog)
    if dropped_token:
        failures.append(
            f"AppShortcuts.xcstrings translations dropped {APP_NAME_TOKEN} "
            "(Siri cannot match a phrase with no app name in it):"
        )
        failures.extend(dropped_token)

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1

    info_plist_translatable = sum(
        1
        for entry in info_plist_catalog.get("strings", {}).values()
        if not is_do_not_translate(entry)
    )
    print(
        f"OK: {len(catalog_keys)} keys validated across "
        f"{len(EXPECTED_LOCALES)} locales; "
        f"{len(swift_keys)} Swift references and "
        f"{len(library_keys)} service-type details resolved; "
        f"{info_plist_translatable} InfoPlist keys and "
        f"{len(app_target_catalog.get('strings', {}))} app-target keys and "
        f"{len(app_shortcuts_catalog.get('strings', {}))} Siri phrases validated."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
