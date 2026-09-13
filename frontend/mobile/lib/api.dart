/// HTTP to middleware /v1 only. No matching on device.
library;

import "dart:convert";

import "package:http/http.dart" as http;
import "package:shared_preferences/shared_preferences.dart";

import "block.dart";

const String kApiBase = String.fromEnvironment(
  "SAHAYAK_API_BASE",
  defaultValue: "http://127.0.0.1:8080",
);

class Api {
  String? token;

  Map<String, String> get _h => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(Uri.parse("$kApiBase$path"), headers: _h);
      return _map(res.body, res.statusCode);
    } catch (_) {
      pauseBus.showCode("no_internet");
      return {"error": "no_internet", "human": "The line is quiet. You stay here."};
    }
  }

  Future<Map<String, dynamic>> post(String path, Object body) async {
    try {
      final res = await http.post(
        Uri.parse("$kApiBase$path"),
        headers: _h,
        body: jsonEncode(body),
      );
      return _map(res.body, res.statusCode);
    } catch (_) {
      pauseBus.showCode("no_internet");
      return {"error": "no_internet", "human": "The line is quiet. You stay here."};
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http.delete(Uri.parse("$kApiBase$path"), headers: _h);
      return _map(res.body, res.statusCode);
    } catch (_) {
      pauseBus.showCode("no_internet");
      return {"error": "no_internet", "human": "The line is quiet. You stay here."};
    }
  }

  Map<String, dynamic> _map(String body, [int status = 200]) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded["block"] is Map) {
          pauseBus.showMap(Map<String, dynamic>.from(decoded["block"] as Map));
        } else if (status >= 500) {
          pauseBus.showCode("server_quiet");
        } else if (status == 401) {
          pauseBus.showCode("session_ended");
        } else if (status == 429) {
          pauseBus.showCode("too_many");
        }
        return decoded;
      }
      return {"human": decoded.toString()};
    } catch (_) {
      if (status >= 500) pauseBus.showCode("server_quiet");
      return {"human": body};
    }
  }

  Future<void> persistToken() async {
    final p = await SharedPreferences.getInstance();
    if (token == null) {
      await p.remove("token");
    } else {
      await p.setString("token", token!);
    }
  }

  Future<bool> restore() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString("token");
    if (token == null) return false;
    final me = await get("/v1/me");
    if (me["user"] is Map) return true;
    token = null;
    await persistToken();
    return false;
  }
}

final api = Api();

// Enhanced feature API methods
Future<Map<String, dynamic>> getFeatureFlags() async {
  return api.get("/v1/feature-flags");
}

Future<Map<String, dynamic>> getGraceDate() async {
  return api.get("/v1/grace-date");
}

Future<Map<String, dynamic>> setNightMode(bool on) async {
  return api.post("/v1/night-mode", {"on": on});
}

Future<Map<String, dynamic>> setDonorHold({
  bool fasting = false,
  bool fever = false,
}) async {
  return api.post("/v1/donors/me/hold", {
    "fasting": fasting,
    "fever": fever,
  });
}

Future<Map<String, dynamic>> getHeatmap() async {
  return api.get("/v1/heatmap");
}

Future<Map<String, dynamic>> getOpenRequestsWithProgress() async {
  return api.get("/v1/blood-requests/open");
}

String humanOf(Map<String, dynamic> j, [String fallback = "Done."]) {
  final h = j["human"];
  if (h is String && h.isNotEmpty) return h;
  final e = j["error"];
  if (e is String && e.isNotEmpty) return e;
  return fallback;
}
