#!/usr/bin/env python3
"""Builds docs/LANGUAGE.md: every translatable string in the app, in one list.

Written because counting strings is easy and listing them is not. Dart joins
adjacent string literals into one string, so a paragraph of vendor advice is
four literals across four lines in the source and one sentence on screen.
Anything that reads the source line by line reports it as four fragments,
which is useless to a translator.

Run: python tool/extract_strings.py
"""

from __future__ import annotations

import io
import os
import re
import sys

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is needed: pip install pyyaml")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Where each file's strings belong in the finished document.
AREAS = [
    ("lib/screens/onboarding_screen.dart", "First run", "Shown once, before anything else. The user has not agreed to anything yet, so this text is what persuades them the permissions are reasonable."),
    ("lib/screens/home_screen.dart", "The map screen", "The screen people actually live in. Includes every transient message."),
    ("lib/screens/location_picker_screen.dart", "Choosing a destination", "Search, the radius slider, and the speed advice."),
    ("lib/screens/reliability_screen.dart", "Will it ring?", "The diagnostics screen. The most important text in the app after the alarm itself."),
    ("lib/services/oem_service.dart", "Phone-specific advice", "Per-manufacturer instructions for stopping the phone killing background apps. The largest block, and the one most worth translating: a user who cannot follow it gets no alarm at all."),
    ("lib/screens/settings_screen.dart", "Settings", ""),
    ("lib/widgets/alarm_sound_section.dart", "Alarm sound", ""),
    ("lib/screens/about_screen.dart", "About", ""),
    ("lib/widgets/map_tiles.dart", "Map styles", ""),
    ("lib/widgets/app_drawer.dart", "Navigation drawer", ""),
    ("lib/services/geocoding_service.dart", "Search failures", ""),
    ("lib/services/permission_service.dart", "Permissions", ""),
    ("lib/models/place_result.dart", "Search results", ""),
    ("lib/services/app_version.dart", "Version", ""),
    ("lib/services/radius_advice.dart", "Radius advice", ""),
    ("lib/main.dart", "App shell", ""),
]

# Literals that are never shown to anyone.
NEVER_SHOWN = re.compile(
    r"^(https?://|package:|dart:|assets/|com\.zaifears|[a-z_]+$|[A-Z_]+$|\{[a-z]\}|"
    r"[a-z]+/[a-z]+$|%\d|\.\w+$)"
)
NOT_TEXT = re.compile(r"^[^A-Za-z]*$")


def strip_comments(src: str) -> str:
    """Blanks comments while keeping the file's shape, so offsets still line up."""
    out = []
    i, n = 0, len(src)
    while i < n:
        ch = src[i]
        if ch in "'\"":
            # Skip over a string literal wholesale; a // inside one is not a
            # comment, and this is the whole reason for scanning rather than
            # regexing.
            quote = ch
            out.append(ch)
            i += 1
            while i < n and src[i] != quote:
                if src[i] == "\\" and i + 1 < n:
                    out.append(src[i]); i += 1
                if src[i] == "\n":
                    break
                out.append(src[i]); i += 1
            if i < n:
                out.append(src[i]); i += 1
            continue
        if src.startswith("//", i):
            while i < n and src[i] != "\n":
                out.append(" "); i += 1
            continue
        if src.startswith("/*", i):
            while i < n and not src.startswith("*/", i):
                out.append("\n" if src[i] == "\n" else " "); i += 1
            out.append("  "); i += 2
            continue
        out.append(ch); i += 1
    return "".join(out)


def scan_literals(src: str):
    """Yields (offset, end, text) for every Dart string literal.

    Scanned rather than matched with a regular expression, because Dart lets
    an interpolation contain its own string:

        'Already rang: ${labels.join(', ')}'

    To a regex the quote before the comma closes the literal, so the string
    comes out truncated at "Already rang: ${labels.join(" and the rest is
    read as source. Tracking brace depth is the only way to know that quote
    is inside an expression rather than ending anything.
    """
    i, n = 0, len(src)
    while i < n:
        ch = src[i]
        if ch not in "'\"":
            i += 1
            continue

        # Raw strings take no escapes and no interpolation.
        raw = i > 0 and src[i - 1] == "r"
        triple = src.startswith(ch * 3, i)
        quote = ch * 3 if triple else ch
        j = i + len(quote)
        body = []
        depth = 0

        while j < n:
            c = src[j]
            if not raw and c == "\\" and j + 1 < n:
                body.append(src[j:j + 2])
                j += 2
                continue
            if depth == 0 and not raw and src.startswith("${", j):
                depth = 1
                body.append("${")
                j += 2
                continue
            if depth:
                # Inside an interpolation. Quotes here belong to the
                # expression, so step over any nested literal wholesale.
                if c in "'\"":
                    for _, sub_end, sub_text in scan_literals(src[j:j + 400]):
                        body.append(c + sub_text + c)
                        j += sub_end
                        break
                    else:
                        j += 1
                    continue
                if c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                body.append(c)
                j += 1
                continue
            if src.startswith(quote, j):
                yield i, j + len(quote), "".join(body)
                # Past the closing quote, not onto it. Resuming *at* it read
                # every close as the next open, so the source between two
                # literals came back as a literal of its own: a list like
                # ['xiaomi', 'redmi'] extracted the ", " between them.
                j += len(quote)
                break
            if c == "\n" and not triple:
                break
            body.append(c)
            j += 1
        i = max(j, i + 1)


def literals_with_runs(src: str):
    """Yields (line, text) with adjacent literals joined into one string.

    Dart concatenates string literals that sit next to each other, so a
    paragraph of vendor advice is four literals across four lines in the
    source and one sentence on screen. Reporting the four separately would
    hand a translator fragments that end mid-word.
    """
    found = list(scan_literals(src))
    used = set()
    for index, (start, end, text) in enumerate(found):
        if index in used:
            continue
        parts = [text]
        reach = end
        step = index + 1
        while step < len(found):
            nxt_start, nxt_end, nxt_text = found[step]
            # Only whitespace between them means Dart joins the two.
            if src[reach:nxt_start].strip():
                break
            parts.append(nxt_text)
            used.add(step)
            reach = nxt_end
            step += 1
        yield src[:start].count("\n") + 1, "".join(parts)


def is_shown(text: str) -> bool:
    if len(text) < 2 or NOT_TEXT.match(text):
        return False
    if NEVER_SHOWN.match(text):
        return False
    # Import paths are string literals too, and they sit at the top of every
    # file, so they are the first thing an extractor finds and the easiest
    # thing to mistake for a heading.
    if text.endswith(".dart") or text.startswith("../"):
        return False
    # A URL inside the text means a user agent or a link target, not a
    # sentence. Real prose in this app never carries one.
    if "http://" in text or "https://" in text:
        return False
    # A lone lowercase word with no space is nearly always a key or an id.
    if " " not in text and text[0].islower() and "'" not in text:
        return False
    return True


CALL = re.compile(r"\.\w+\([^()]*\)")
IDENTIFIER = re.compile(r"[A-Za-z_]\w*")


def unescape(text: str) -> str:
    """Turns Dart escapes back into the characters they stand for.

    A translator is shown the sentence, not the source. Leaving the escape
    in makes "Android\'s" look like something that must be preserved
    exactly, and someone would dutifully copy the backslash into their own
    language.
    """
    out = []
    i = 0
    while i < len(text):
        if text[i] == "\\" and i + 1 < len(text):
            nxt = text[i + 1]
            out.append({"n": " ", "t": " "}.get(nxt, nxt))
            i += 2
            continue
        out.append(text[i])
        i += 1
    return "".join(out)


def to_placeholders(text: str) -> str:
    """Turns Dart interpolation into a name a translator can move around.

    A translator cannot be shown `${(metres / 1000).toStringAsFixed(1)} km`
    and asked to keep it intact. What matters to them is that a number
    appears there and may go somewhere else in their sentence, which is
    exactly what {metres} says.
    """

    def name(expression: str) -> str:
        # Drop method calls first: metres.round() is about metres, not round.
        bare = CALL.sub("", expression).strip("() ")
        parts = IDENTIFIER.findall(bare)
        if not parts:
            return "value"
        # A dotted path names its last part (e.name -> name); anything else
        # takes the first identifier it contains.
        return parts[-1] if bare.replace(".", "").isalnum() else parts[0]

    out = re.sub(r"\$\{([^{}]*)\}", lambda m: "{%s}" % name(m.group(1)), text)
    return re.sub(r"\$([A-Za-z_]\w*)", lambda m: "{%s}" % m.group(1), out)


def key_for(text: str, taken: set) -> str:
    words = re.findall(r"[A-Za-z]+", text)[:5]
    if not words:
        words = ["text"]
    key = words[0].lower() + "".join(w.capitalize() for w in words[1:])
    key = key[:44]
    base, n = key, 2
    while key in taken:
        key = "%s%d" % (base, n)
        n += 1
    taken.add(key)
    return key


def already_migrated() -> set:
    path = os.path.join(ROOT, "locale", "en.yaml")
    with io.open(path, encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    done = set()
    for section in ("app", "alarm"):
        for value in (data.get(section) or {}).values():
            if isinstance(value, dict):
                done |= {str(v) for v in value.values()}
            else:
                done.add(str(value))
    return done


def md_cell(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ")


def main() -> int:
    done = already_migrated()
    taken = set()
    sections = []
    total = 0

    for relative, heading, blurb in AREAS:
        path = os.path.join(ROOT, relative.replace("/", os.sep))
        if not os.path.exists(path):
            continue
        src = strip_comments(io.open(path, encoding="utf-8").read())

        rows, seen = [], set()
        for _, text in literals_with_runs(src):
            if not is_shown(text) or text in seen:
                continue
            seen.add(text)
            shown_text = unescape(to_placeholders(text))
            if shown_text in done or text in done:
                continue
            rows.append((key_for(shown_text, taken), shown_text))

        if rows:
            sections.append((heading, relative, blurb, rows))
            total += len(rows)

    return render(sections, total, done)


HEADER = """# Every word in LocReminder

This is the complete list of text a translator would replace. Nothing in the
app is missing from it, including the parts Android draws rather than Flutter.

## How to use this

1. Copy this file, or work through it in place.
2. Fill in the empty **Your language** column. You do not have to do all of
   it. Anything left blank stays English, and a part-finished translation is
   still worth sending.
3. Hand the filled-in file to Claude Code and ask it to produce
   `locale/<code>.yaml` from it. That is one file, and it is the only file
   the app needs.

You never have to touch Dart, Kotlin, or XML. If you would rather write the
YAML yourself, copy `locale/en.yaml` and translate the right-hand side; the
keys in the tables below are the same keys.

## Rules

**Words in curly braces** like `{place}` are filled in by the app while it is
running. Keep every one of them, spelled exactly the same. You may move them
anywhere in the sentence, which is the whole reason they exist: word order is
not the same in every language.

**Plurals** appear as two rows, *one* and *other*. If your language does not
split them the way English does, put the same text in both.

**Do not translate these**, ever:

| | Why |
|---|---|
| LocReminder | The app's name. |
| OpenStreetMap, OpenTopoMap, CyclOSM | Project names, and the map credit is a licence requirement. |
| Xiaomi, MIUI, HyperOS, Samsung, One UI, Oppo, ColorOS, Vivo, Funtouch, OnePlus, OxygenOS, Huawei, EMUI, Honor, MagicOS, Meizu, Flyme, Asus, ZenUI, Transsion, HiOS, XOS, TCL, Alcatel, HTC, Sense, Sharp, Kyocera, MediaTek, DuraSpeed, Amazon, Fire OS, Walton, Symphony, Lava, Micromax | Phone makers and their software. |
| Settings menu names in the **Phone-specific advice** section | Those menus appear on the phone in *its* language. If your phone shows them in your language, translate them to match exactly what is on screen. If it shows them in English, leave them in English. Getting this wrong sends someone hunting for a setting that does not exist. |

**Keep the arrows** (→) in settings paths. They separate one menu level from
the next.

"""


def render(sections, total, done) -> int:
    out = [HEADER]

    out.append("## What is here\n")
    out.append("| Section | Strings |")
    out.append("|---|---:|")
    for heading, _, _, rows in sections:
        out.append("| [%s](#%s) | %d |" % (heading, slug(heading), len(rows)))
    app_done = len(yaml_section("app"))
    alarm_done = sum(
        len(v) if isinstance(v, dict) else 1 for v in yaml_section("alarm").values()
    )
    store_done = len(yaml_section("store"))
    out.append("| [Already moved over](#already-moved-over) | %d |" % app_done)
    out.append("| [The alarm](#the-alarm) | %d |" % alarm_done)
    out.append("| [The F-Droid listing](#the-f-droid-listing) | %d |" % store_done)
    out.append(
        "| **Everything** | **%d** |" % (total + app_done + alarm_done + store_done)
    )
    out.append("")

    for heading, relative, blurb, rows in sections:
        out.append("## %s\n" % heading)
        if blurb:
            out.append(blurb + "\n")
        out.append("`%s`\n" % relative)
        out.append("| Key | English | Your language |")
        out.append("|---|---|---|")
        for key, text in rows:
            out.append("| `%s` | %s | |" % (key, md_cell(text)))
        out.append("")

    out.append(app_done_section())
    out.append(alarm_section())
    out.append(store_section())

    path = os.path.join(ROOT, "docs", "LANGUAGE.md")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    body = "\n".join(out).rstrip() + "\n"
    io.open(path, "w", encoding="utf-8", newline="\n").write(body)
    print(
        "docs/LANGUAGE.md: %d strings in all (%d of them still hardcoded)"
        % (total + app_done + alarm_done + store_done, total)
    )
    return 0


def slug(heading: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", heading.lower()).strip("-")


def yaml_section(name: str) -> dict:
    path = os.path.join(ROOT, "locale", "en.yaml")
    with io.open(path, encoding="utf-8") as handle:
        return yaml.safe_load(handle).get(name) or {}


def app_done_section() -> str:
    """The app strings already living in locale/en.yaml.

    Listed for the same reason as everything else: this document claims to be
    every word in the app, and a string being further along in the migration
    than its neighbours is of no interest whatsoever to a translator.
    """
    rows = [
        "## Already moved over\n",
        "App text that has already been moved into the language file. Nothing",
        "special about it: it needs translating like the rest.\n",
        "`locale/en.yaml`, under `app:`\n",
        "| Key | English | Your language |",
        "|---|---|---|",
    ]
    for key, value in yaml_section("app").items():
        if isinstance(value, dict):
            for form, text in value.items():
                rows.append("| `%s` (%s) | %s | |" % (key, form, md_cell(str(text))))
        else:
            rows.append("| `%s` | %s | |" % (key, md_cell(str(value))))
    return "\n".join(rows) + "\n"


def alarm_section() -> str:
    rows = ["## The alarm\n",
            "What the alarm itself says, plus the ongoing notification while it is",
            "watching. Drawn by Android rather than by the app, so that it still works",
            "when the app is not running.\n",
            "`locale/en.yaml`, under `alarm:`\n",
            "| Key | English | Your language |",
            "|---|---|---|"]
    for key, value in yaml_section("alarm").items():
        if isinstance(value, dict):
            for form, text in value.items():
                rows.append("| `%s` (%s) | %s | |" % (key, form, md_cell(str(text))))
        else:
            rows.append("| `%s` | %s | |" % (key, md_cell(str(value))))
    return "\n".join(rows) + "\n"


def store_section() -> str:
    store = yaml_section("store")
    rows = ["## The F-Droid listing\n",
            "What people read before they install. Not shown inside the app.\n",
            "`locale/en.yaml`, under `store:`\n"]
    for key, value in store.items():
        rows.append("### `%s`\n" % key)
        rows.append("```")
        rows.append(str(value).rstrip())
        rows.append("```\n")
    return "\n".join(rows)


if __name__ == "__main__":
    sys.exit(main())
