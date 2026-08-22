// GENERATED FILE - DO NOT EDIT.
//
// Every string here comes from locale/<code>.yaml. To change wording,
// edit locale/en.yaml. To add a language, copy locale/en.yaml to
// locale/<code>.yaml and translate the right-hand side. Then run
// `python tool/gen_locale.py`, or the refresh-locales workflow.
//
// Deliberately hand-rolled rather than built on flutter_localizations
// and intl. Those would pull two packages into a dependency set that
// CI installs with --enforce-lockfile, and add a code generation step
// to a build F-Droid reproduces byte for byte. Localizations and
// LocalizationsDelegate are core Flutter, so none of that is needed.

import 'package:flutter/widgets.dart';

abstract class S {
  /// The nearest translation to the reader's phone, falling back to
  /// English for a language nobody has contributed yet.
  static S of(BuildContext context) =>
      Localizations.of<S>(context, S) ?? const SEn();

  const S();

  /// Languages with a locale/<code>.yaml file.
  static const supported = <Locale>[
    Locale('en'),
  ];

  static const delegate = _SDelegate();

  String get appTitle => 'LocReminder';
}

/// English
class SEn extends S {
  const SEn();
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      S.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<S> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return const SEn();
      default:
        return const SEn();
    }
  }

  @override
  bool shouldReload(_SDelegate old) => false;
}
