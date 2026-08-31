/// One pause card. OK dismisses. Stay on this screen. Shows again if the issue remains.
library;

import "package:flutter/foundation.dart";

class PauseNote {
  const PauseNote(
      {required this.code,
      required this.title,
      required this.line,
      this.ok = "OK"});
  final String code;
  final String title;
  final String line;
  final String ok;
}

const _copy = {
  "no_internet": PauseNote(
      code: "no_internet",
      title: "The line is quiet",
      line:
          "This phone has no internet right now. You stay on this page. Nothing was sent."),
  "location_denied": PauseNote(
      code: "location_denied",
      title: "Location stayed off",
      line:
          "SaHayak did not get location. Pick a city instead. You stay here."),
  "location_off": PauseNote(
      code: "location_off",
      title: "Location is not available",
      line: "Use the city list. We never follow you in the background."),
  "server_quiet": PauseNote(
      code: "server_quiet",
      title: "SaHayak could not answer",
      line:
          "The helping-hand line is not reaching this computer. You stay on this page."),
  "session_ended": PauseNote(
      code: "session_ended",
      title: "Please sign in again when you are ready",
      line:
          "This session ended. You are still on this page. Nothing was posted."),
  "account_paused": PauseNote(
      code: "account_paused",
      title: "This account is paused",
      line: "Write to the owner. You stay here. We did not move you away."),
  "too_many": PauseNote(
      code: "too_many",
      title: "A short pause",
      line: "Too many tries just now. Stay here. Wait a moment, then OK."),
  "generic": PauseNote(
      code: "generic",
      title: "A small pause",
      line:
          "Something needed a moment. You stay on this page. Nothing extra was sent."),
};

class PauseBus extends ChangeNotifier {
  PauseNote? current;
  bool _mute = false;

  void showCode(String code) {
    show(_copy[code] ?? _copy["generic"]!);
  }

  void showMap(Map<String, dynamic>? block) {
    if (block == null) return;
    final code = block["code"] as String? ?? "generic";
    show(PauseNote(
      code: code,
      title:
          block["title"] as String? ?? (_copy[code]?.title ?? "A small pause"),
      line: block["line"] as String? ?? (_copy[code]?.line ?? ""),
      ok: block["ok"] as String? ?? "OK",
    ));
  }

  void show(PauseNote note) {
    if (_mute || current != null) return;
    current = note;
    notifyListeners();
  }

  void ok() {
    current = null;
    _mute = true;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      _mute = false;
    });
  }
}

final pauseBus = PauseBus();
