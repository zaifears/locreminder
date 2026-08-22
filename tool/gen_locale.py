#!/usr/bin/env python3
"""Turns locale/<code>.yaml into every file the app actually reads.

One hand-edited file per language, three generated formats, because three
different things render this app's text and only one of them is Flutter:

    locale/bn.yaml  ->  lib/l10n/strings.g.dart              the Flutter UI
                    ->  android/.../values-bn/strings.xml    the alarm
                    ->  fastlane/metadata/android/bn/        the F-Droid page

The alarm is deliberately not Flutter: it rings through a native Activity and
notification so it works when the Flutter engine is not running, which means
its text has to be an Android resource. The store listing is read by F-Droid
from the repository and never by the app at all. A contributor should not
have to know any of that, so they edit one file and this fills in the rest.

Run it with `python tool/gen_locale.py`, or through the refresh-locales
workflow. It is never run by the release build: the generated files are
committed, and CI only checks they still match their source. That keeps
code generation out of a build F-Droid reproduces byte for byte.
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
LOCALE_DIR = os.path.join(ROOT, "locale")
BASE = "en"

PLACEHOLDER = re.compile(r"\{(\w+)\}")


def die(message: str) -> None:
    sys.exit("locale: " + message)


def read(path: str) -> str:
    return io.open(path, encoding="utf-8").read()


def write(path: str, text: str) -> bool:
    """Writes only when the content actually changes; reports whether it did.

    Always LF, and the comparison ignores line endings entirely. This repo is
    developed on Windows with core.autocrlf on and built on Linux, so one
    committed file is CRLF on one machine and LF on the other. Comparing raw
    bytes would make --check fail on whichever platform did not generate it,
    which looks exactly like a stale file and is not one. .gitattributes pins
    these paths to LF so the working trees agree as well.
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)
    normalised = text.replace("\r\n", "\n")
    if os.path.exists(path) and read(path).replace("\r\n", "\n") == normalised:
        return False
    io.open(path, "w", encoding="utf-8", newline="\n").write(normalised)
    return True


def load(code: str) -> dict:
    with io.open(os.path.join(LOCALE_DIR, code + ".yaml"), encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def locales() -> list[str]:
    """Every language file, base first so it can act as the fallback."""
    found = sorted(
        name[:-5] for name in os.listdir(LOCALE_DIR) if name.endswith(".yaml")
    )
    if BASE not in found:
        die("locale/%s.yaml is missing, and it is the fallback for every key" % BASE)
    return [BASE] + [code for code in found if code != BASE]


# ---------------------------------------------------------------- validation


def check_against_base(code: str, data: dict, base: dict) -> None:
    """Keeps a translation honest about what it is translating.

    A missing key is fine and falls back to English, but a key that does not
    exist upstream, or one whose placeholders differ, is a typo that would
    otherwise surface as a crash or a blank on someone's phone.
    """
    for section in ("app", "alarm"):
        base_section = base.get(section) or {}
        for key, value in (data.get(section) or {}).items():
            if key not in base_section:
                die("%s.yaml: %s.%s is not a key in %s.yaml" % (code, section, key, BASE))

            expected = placeholders_of(base_section[key])
            actual = placeholders_of(value)
            if expected != actual:
                die(
                    "%s.yaml: %s.%s uses %s but %s.yaml uses %s"
                    % (
                        code,
                        section,
                        key,
                        sorted(actual) or "no placeholders",
                        BASE,
                        sorted(expected) or "no placeholders",
                    )
                )


def placeholders_of(value) -> set:
    if isinstance(value, dict):
        found = set()
        for form in value.values():
            found |= set(PLACEHOLDER.findall(str(form)))
        # {count} is supplied by the plural machinery itself, not by the caller.
        return found - {"count"}
    return set(PLACEHOLDER.findall(str(value)))


def ordered_placeholders(text: str) -> list[str]:
    seen, order = set(), []
    for name in PLACEHOLDER.findall(text):
        if name not in seen:
            seen.add(name)
            order.append(name)
    return order


# --------------------------------------------------------------------- Dart


def dart_literal(text: str) -> str:
    """A single-quoted Dart literal, with placeholders left as interpolations."""
    out = text.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    out = out.replace("\n", "\\n")
    # Put the interpolation back: the escape above turned $ into \$, and
    # {name} has to become ${name} to read the parameter.
    return PLACEHOLDER.sub(lambda m: "${%s}" % m.group(1), out)


def dart_member(key: str, value) -> str:
    """One getter, or one method where the string takes arguments."""
    if isinstance(value, dict):
        args = ["int count"] + [
            "String %s" % name for name in sorted(placeholders_of(value))
        ]
        one = dart_literal(str(value.get("one", value.get("other", ""))))
        other = dart_literal(str(value.get("other", "")))
        return (
            "  String %s(%s) =>\n      count == 1 ? '%s' : '%s';"
            % (key, ", ".join(args), one, other)
        )

    names = ordered_placeholders(str(value))
    body = dart_literal(str(value))
    if not names:
        return "  String get %s => '%s';" % (key, body)
    args = ", ".join("String %s" % name for name in names)
    return "  String %s(%s) => '%s';" % (key, args, body)


def generate_dart(all_data: dict) -> str:
    base_app = all_data[BASE]["app"]
    codes = list(all_data)

    lines = [
        "// GENERATED FILE - DO NOT EDIT.",
        "//",
        "// Every string here comes from locale/<code>.yaml. To change wording,",
        "// edit locale/en.yaml. To add a language, copy locale/en.yaml to",
        "// locale/<code>.yaml and translate the right-hand side. Then run",
        "// `python tool/gen_locale.py`, or the refresh-locales workflow.",
        "//",
        "// Deliberately hand-rolled rather than built on flutter_localizations",
        "// and intl. Those would pull two packages into a dependency set that",
        "// CI installs with --enforce-lockfile, and add a code generation step",
        "// to a build F-Droid reproduces byte for byte. Localizations and",
        "// LocalizationsDelegate are core Flutter, so none of that is needed.",
        "",
        "import 'package:flutter/widgets.dart';",
        "",
        "abstract class S {",
        "  /// The nearest translation to the reader's phone, falling back to",
        "  /// English for a language nobody has contributed yet.",
        "  static S of(BuildContext context) =>",
        "      Localizations.of<S>(context, S) ?? const S%s();" % BASE.capitalize(),
        "",
        "  const S();",
        "",
        "  /// Languages with a locale/<code>.yaml file.",
        "  static const supported = <Locale>[",
    ]
    lines += ["    Locale('%s')," % code for code in codes]
    lines += [
        "  ];",
        "",
        "  static const delegate = _SDelegate();",
        "",
    ]
    lines += ["  " + dart_member(key, value).strip() for key in base_app for value in [base_app[key]]]
    lines += ["}", ""]

    for code in codes:
        data = all_data[code]["app"]
        name = "S" + code.capitalize()
        members = []
        for key in base_app:
            # The base language lives on S itself, so repeating it here would
            # be noise. Every other language overrides only what it has
            # actually translated, and inherits the English wording for the
            # rest — which is what makes a half-finished translation usable.
            if code != BASE and key in data:
                members.append("  @override")
                members.append("  " + dart_member(key, data[key]).strip())

        lines += [
            "/// %s" % all_data[code]["meta"]["name"],
            "class %s extends S {" % name,
            "  const %s();" % name,
        ]
        if members:
            lines.append("")
            lines += members
        lines += ["}", ""]

    lines += [
        "class _SDelegate extends LocalizationsDelegate<S> {",
        "  const _SDelegate();",
        "",
        "  @override",
        "  bool isSupported(Locale locale) =>",
        "      S.supported.any((l) => l.languageCode == locale.languageCode);",
        "",
        "  @override",
        "  Future<S> load(Locale locale) async {",
        "    switch (locale.languageCode) {",
    ]
    for code in codes:
        lines.append("      case '%s':" % code)
        lines.append("        return const S%s();" % code.capitalize())
    lines += [
        "      default:",
        "        return const S%s();" % BASE.capitalize(),
        "    }",
        "  }",
        "",
        "  @override",
        "  bool shouldReload(_SDelegate old) => false;",
        "}",
        "",
    ]
    return "\n".join(lines)


# ------------------------------------------------------------------ Android


def xml_escape(text: str) -> str:
    out = (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("'", "\\'")
        .replace('"', '\\"')
    )
    return out.replace("\n", "\\n")


def generate_android(code: str, data: dict) -> str:
    alarm = data.get("alarm") or {}
    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        "<!-- GENERATED FILE - DO NOT EDIT. Source: locale/%s.yaml -->" % code,
        "<resources>",
    ]
    for key, value in alarm.items():
        if isinstance(value, dict):
            # Android's own plural resource, so the alarm notification counts
            # correctly in languages that do not inflect the way English does.
            lines.append('    <plurals name="%s">' % key)
            for form in ("one", "other"):
                if form in value:
                    body = PLACEHOLDER.sub("%d", xml_escape(str(value[form])))
                    lines.append('        <item quantity="%s">%s</item>' % (form, body))
            lines.append("    </plurals>")
            continue

        body = xml_escape(str(value))
        for index, name in enumerate(ordered_placeholders(str(value)), start=1):
            body = body.replace("{%s}" % name, "%%%d$s" % index)
        lines.append('    <string name="%s">%s</string>' % (key, body))

    lines += ["</resources>", ""]
    return "\n".join(lines)


# ----------------------------------------------------------------- Fastlane


def generate_fastlane(code: str, data: dict, root: str) -> list[str]:
    """The F-Droid listing. Returns the paths it touched."""
    store = data.get("store") or {}
    if not store:
        return []

    # F-Droid expects en-US rather than a bare en; everything else is the
    # plain language code unless the file says otherwise.
    folder = data["meta"].get("fastlane", "en-US" if code == BASE else code)
    base = os.path.join(root, "fastlane", "metadata", "android", folder)

    written = []
    for key, filename in (
        ("title", "title.txt"),
        ("shortDescription", "short_description.txt"),
        ("fullDescription", "full_description.txt"),
    ):
        if key not in store:
            continue
        path = os.path.join(base, filename)
        body = str(store[key]).rstrip("\n") + "\n"
        # Only the ones that actually changed, so --check does not report
        # every listing file as stale on every run.
        if write(path, body):
            written.append(path)
    return written


# --------------------------------------------------------------------- main


def main() -> int:
    check_only = "--check" in sys.argv

    codes = locales()
    all_data = {}
    for code in codes:
        data = load(code)
        for required in ("meta", "app"):
            if required not in data:
                die("%s.yaml has no '%s:' section" % (code, required))
        if "name" not in data["meta"]:
            die("%s.yaml: meta.name should say what the language is called" % code)
        all_data[code] = data

    for code in codes:
        if code != BASE:
            check_against_base(code, all_data[code], all_data[BASE])

    changed = []

    dart_path = os.path.join(ROOT, "lib", "l10n", "strings.g.dart")
    if write(dart_path, generate_dart(all_data)):
        changed.append(dart_path)

    for code in codes:
        if not all_data[code].get("alarm"):
            continue
        # The base language is the default resource folder, which is what
        # Android falls back to for any locale nobody has translated.
        folder = "values" if code == BASE else "values-" + code
        path = os.path.join(
            ROOT, "android", "app", "src", "main", "res", folder, "strings.xml"
        )
        if write(path, generate_android(code, all_data[code])):
            changed.append(path)

        for path in generate_fastlane(code, all_data[code], ROOT):
            changed.append(path)

    if check_only:
        if changed:
            print("These generated files no longer match locale/*.yaml:")
            for path in changed:
                print("  " + os.path.relpath(path, ROOT).replace(os.sep, "/"))
            print("\nRun: python tool/gen_locale.py")
            return 1
        print("Generated files match locale/*.yaml.")
        return 0

    print("%d language%s: %s" % (len(codes), "" if len(codes) == 1 else "s", ", ".join(codes)))
    app_count = len(all_data[BASE]["app"])
    alarm_count = len(all_data[BASE].get("alarm") or {})
    print(
        "%d app string%s, %d alarm string%s"
        % (app_count, "" if app_count == 1 else "s",
           alarm_count, "" if alarm_count == 1 else "s")
    )
    if changed:
        for path in changed:
            print("  wrote " + os.path.relpath(path, ROOT).replace(os.sep, "/"))
    else:
        print("  everything already up to date")
    return 0


if __name__ == "__main__":
    sys.exit(main())
