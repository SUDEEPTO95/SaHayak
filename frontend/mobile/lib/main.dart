/// SaHayak citizen app. UI talks only to /v1.
library;

import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_map/flutter_map.dart";
import "package:geolocator/geolocator.dart";
import "package:latlong2/latlong.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:url_launcher/url_launcher.dart";

import "api.dart";
import "block.dart";
import "donor_features.dart";
import "enhanced_features.dart";
import "l10n.dart";
import "system_indicators.dart";

const Color kSos = Color(0xFFC42B4A);
const Color kTrust = Color(0xFF1AA58A);
const Color kInk = Color(0xFF0C0610);
const Color kGold = Color(0xFFE8C07A);

const groups = ["O-", "O+", "A-", "A+", "B-", "B+", "AB-", "AB+"];
const cities = {
  "Kolkata": LatLng(22.5726, 88.3639),
  "Howrah": LatLng(22.5958, 88.2636),
  "Delhi": LatLng(28.6139, 77.2090),
  "Mumbai": LatLng(19.0760, 72.8777),
  "Chennai": LatLng(13.0827, 80.2707),
  "Bengaluru": LatLng(12.9716, 77.5946),
};

void main() {
  runApp(const SaHayakApp());
}

class SaHayakApp extends StatefulWidget {
  const SaHayakApp({super.key});
  @override
  State<SaHayakApp> createState() => _SaHayakAppState();
}

class _SaHayakAppState extends State<SaHayakApp> {
  bool hi = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SaHayak",
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kInk,
        colorScheme: const ColorScheme.dark(
            primary: kSos, secondary: kTrust, surface: Color(0xFF1A0A14)),
        useMaterial3: true,
      ),
      home: GateScreen(hi: hi, onLang: (v) => setState(() => hi = v)),
      builder: (context, child) {
        return ListenableBuilder(
          listenable: pauseBus,
          builder: (context, _) {
            return Stack(
              children: [
                child ?? const SizedBox.expand(),
                if (pauseBus.current != null)
                  PauseVeil(note: pauseBus.current!),
              ],
            );
          },
        );
      },
    );
  }
}

class Stage extends StatelessWidget {
  const Stage({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF140810), Color(0xFF1A0A14), Color(0xFF0A1214)],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
            top: -60, left: -40, child: _Orb(const Color(0xFFC42B4A), 220)),
        Positioned(
            bottom: 80, right: -50, child: _Orb(const Color(0xFF1AA58A), 180)),
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb(this.color, this.size);
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: color.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: kGold.withValues(alpha: 0.35)),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: child,
        ),
      ),
    );
  }
}

class Mark extends StatelessWidget {
  const Mark({super.key, required this.line, this.trailing});
  final String line;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const SweepGradient(colors: [kGold, kSos, kTrust, kGold]),
          ),
          child: const Center(child: ThreeDrops()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SaHayak",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kGold,
                      height: 1)),
              Text(kTaglineSoft,
                  style: TextStyle(
                      letterSpacing: 2.4,
                      fontSize: 11,
                      color: kGold.withValues(alpha: 0.95))),
              if (line.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(line, style: const TextStyle(height: 1.35, fontSize: 14)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

const kTaglineSoft = "blood help nearby";

class ThreeDrops extends StatelessWidget {
  const ThreeDrops({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 32,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
              left: 0,
              bottom: 4,
              child: Icon(Icons.water_drop_rounded,
                  size: 14, color: kGold.withValues(alpha: 0.7))),
          Positioned(
              right: 0,
              bottom: 6,
              child: Icon(Icons.water_drop_rounded,
                  size: 10, color: kGold.withValues(alpha: 0.5))),
          const Icon(Icons.water_drop_rounded, size: 22, color: kGold),
        ],
      ),
    );
  }
}

class Giant extends StatelessWidget {
  const Giant(
      {super.key,
      required this.label,
      required this.sub,
      required this.sos,
      required this.onTap,
      required this.icon});
  final String label;
  final String sub;
  final bool sos;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: "$label. $sub",
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: sos ? kSos : kTrust,
          minimumSize: const Size.fromHeight(108),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PauseVeil extends StatelessWidget {
  const PauseVeil({super.key, required this.note});
  final PauseNote note;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB8140810),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: kGold.withValues(alpha: 0.35)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x331A0A14), Color(0xF0140810)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ThreeDrops(),
                    const SizedBox(height: 12),
                    const Text("A SMALL PAUSE",
                        style: TextStyle(
                            color: kGold,
                            fontSize: 11,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(note.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25)),
                    const SizedBox(height: 10),
                    Text(note.line,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.45)),
                    const SizedBox(height: 8),
                    Text("YOU STAY ON THIS PAGE",
                        style: TextStyle(
                            color: kGold.withValues(alpha: 0.9),
                            fontSize: 11,
                            letterSpacing: 1.8)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: pauseBus.ok,
                        style: FilledButton.styleFrom(
                            backgroundColor: kTrust,
                            minimumSize: const Size.fromHeight(52)),
                        child: Text(note.ok,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MiniMap extends StatelessWidget {
  const MiniMap({super.key, required this.center, this.markers = const []});
  final LatLng center;
  final List<Marker> markers;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "app.sahayak.india",
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                    point: center,
                    radius: 32,
                    color: kGold.withValues(alpha: 0.18),
                    borderColor: kGold,
                    borderStrokeWidth: 1),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}

Future<LatLng?> askLocation(BuildContext context, L t) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: kInk,
      title: Text(t.locTitle),
      content: Text(t.locBody),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t.cityInstead)),
        FilledButton(
            onPressed: () => Navigator.pop(c, true), child: Text(t.useGps)),
      ],
    ),
  );
  if (ok != true) return null;
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied)
    perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    pauseBus.showCode("location_denied");
    return null;
  }
  final p = await Geolocator.getCurrentPosition();
  return LatLng(p.latitude, p.longitude);
}

class GateScreen extends StatefulWidget {
  const GateScreen({super.key, required this.hi, required this.onLang});
  final bool hi;
  final ValueChanged<bool> onLang;
  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  final email = TextEditingController(text: "priya@sahayak.local");
  final code = TextEditingController();
  bool mobile = false;
  String msg = "";
  bool busy = true;

  @override
  void initState() {
    super.initState();
    api.restore().then((ok) {
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    HomeScreen(hi: widget.hi, onLang: widget.onLang)));
      } else {
        setState(() => busy = false);
      }
    });
  }

  L get t => L(widget.hi);

  Future<void> _otp() async {
    final j = await api.post(
        "/v1/auth/otp/request",
        mobile
            ? {"channel": "mobile", "phone": email.text, "email": ""}
            : {"channel": "email", "email": email.text, "phone": ""});
    final dev = j["dev_otp"];
    if (dev is String) code.text = dev;
    setState(() => msg = humanOf(j, t.sendCode));
  }

  Future<void> _verify() async {
    final j = await api.post(
      "/v1/auth/otp/verify",
      mobile
          ? {
              "channel": "mobile",
              "phone": email.text,
              "email": "",
              "code": code.text
            }
          : {
              "channel": "email",
              "email": email.text,
              "phone": "",
              "code": code.text
            },
    );
    if (j["token"] is String) {
      api.token = j["token"] as String;
      await api.persistToken();
      final p = await SharedPreferences.getInstance();
      final queued = p.getString("offline_sos");
      if (queued != null) {
        await api.post("/v1/offline-queue", jsonDecode(queued));
        await p.remove("offline_sos");
      }
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  HomeScreen(hi: widget.hi, onLang: widget.onLang)));
    } else {
      setState(() => msg = humanOf(
          j,
          widget.hi
              ? "वह कोड सही नहीं था। फिर कोशिश करें।"
              : "That code didn't match. Please try again."));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Scaffold(
          body: Stage(
              child: Center(child: CircularProgressIndicator(color: kGold))));
    }
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Mark(
                line: "",
                trailing: TextButton(
                    onPressed: () => widget.onLang(!widget.hi),
                    child: Text(widget.hi ? "EN" : "हिन्दी",
                        style: const TextStyle(color: kGold))),
              ),
              const SizedBox(height: 20),
              Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.getCode.toUpperCase(),
                        style: const TextStyle(
                            letterSpacing: 2, fontSize: 11, color: kGold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                            label: Text(t.viaEmail),
                            selected: !mobile,
                            selectedColor: kGold,
                            onSelected: (_) => setState(() => mobile = false)),
                        ChoiceChip(
                            label: Text(t.viaMobile),
                            selected: mobile,
                            selectedColor: kGold,
                            onSelected: (_) => setState(() => mobile = true)),
                      ],
                    ),
                    TextField(
                      controller: email,
                      decoration: InputDecoration(
                          labelText: mobile ? t.mobile : t.email),
                      keyboardType: mobile
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _otp,
                        style: FilledButton.styleFrom(
                            backgroundColor: kTrust,
                            minimumSize: const Size.fromHeight(52)),
                        child: Text(t.sendCode)),
                    const SizedBox(height: 22),
                    Divider(color: kGold.withValues(alpha: 0.22)),
                    const SizedBox(height: 18),
                    Text(t.enterCode.toUpperCase(),
                        style: const TextStyle(
                            letterSpacing: 2, fontSize: 11, color: kGold)),
                    TextField(
                        controller: code,
                        decoration: InputDecoration(labelText: t.six),
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _verify,
                        style: FilledButton.styleFrom(
                            backgroundColor: kSos,
                            minimumSize: const Size.fromHeight(52)),
                        child: Text(t.enter)),
                    const SizedBox(height: 12),
                    Text(msg, style: const TextStyle(height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.hi, required this.onLang});
  final bool hi;
  final ValueChanged<bool> onLang;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool hi;
  @override
  void initState() {
    super.initState();
    hi = widget.hi;
  }

  L get t => L(hi);

  void _flip() {
    setState(() => hi = !hi);
    widget.onLang(hi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Mark(
                  line: t.homeHint,
                  trailing: TextButton(
                      onPressed: _flip,
                      child: Text(hi ? "EN" : "हिन्दी",
                          style: const TextStyle(color: kGold))),
                ),
                const SizedBox(height: 36),
                Giant(
                  icon: Icons.water_drop_rounded,
                  label: t.need,
                  sub: t.needSub,
                  sos: true,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NeedBloodScreen(hi: hi))),
                ),
                const SizedBox(height: 16),
                Giant(
                  icon: Icons.volunteer_activism_rounded,
                  label: t.donate,
                  sub: t.donSub,
                  sos: false,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => DonateScreen(hi: hi))),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MoreScreen(hi: hi))),
                  child: Text(t.more, style: const TextStyle(color: kGold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NeedBloodScreen extends StatefulWidget {
  const NeedBloodScreen({super.key, required this.hi});
  final bool hi;
  @override
  State<NeedBloodScreen> createState() => _NeedBloodScreenState();
}

class _NeedBloodScreenState extends State<NeedBloodScreen> {
  String group = "B+";
  String city = "Kolkata";
  String component = "whole";
  String urgency = "critical";
  final paste = TextEditingController();
  final slip = TextEditingController();
  final hospital = TextEditingController(text: "SSKM");
  final ward = TextEditingController(text: "7");
  final bed = TextEditingController(text: "12");
  final units = TextEditingController(text: "2");
  final phone = TextEditingController();
  final guardian = TextEditingController();
  bool minor = false;
  bool womenFirst = false;
  bool night = false;
  bool saver = false;
  String lastId = "";
  LatLng here = cities["Kolkata"]!;
  String status = "";
  List<Map<String, dynamic>> notebook = [];

  L get t => L(widget.hi);

  @override
  void initState() {
    super.initState();
    _loadNotebook();
  }

  Future<void> _loadNotebook() async {
    final j = await api.get("/v1/family-notebook");
    final rows = j["people"] as List<dynamic>? ?? [];
    if (!mounted) return;
    setState(() => notebook =
        rows.map((e) => Map<String, dynamic>.from(e as Map)).toList());
  }

  Future<void> _gps() async {
    final p = await askLocation(context, t);
    if (p != null) setState(() => here = p);
  }

  Future<void> _fillSlip() async {
    final j = await api.post("/v1/need/slip", {
      "text": slip.text.isNotEmpty ? slip.text : paste.text,
      "language": widget.hi ? "hi" : "en",
      "has_photo": false,
    });
    final p = j["parsed"] as Map<String, dynamic>? ?? {};
    setState(() {
      if (p["recipient_group"] is String)
        group = p["recipient_group"] as String;
      if ((p["hospital_name"] as String?)?.isNotEmpty == true)
        hospital.text = p["hospital_name"] as String;
      if ((p["ward"] as String?)?.isNotEmpty == true)
        ward.text = p["ward"] as String;
      if ((p["bed"] as String?)?.isNotEmpty == true)
        bed.text = p["bed"] as String;
      if (p["units"] != null) units.text = "${p["units"]}";
      if (p["component"] is String) component = p["component"] as String;
      if (p["urgency"] is String) urgency = p["urgency"] as String;
      status = humanOf(j);
    });
  }

  Future<void> _fillPaste() async {
    final j = await api.post("/v1/need/parse",
        {"text": paste.text, "language": widget.hi ? "hi" : "en"});
    final p = j["parsed"] as Map<String, dynamic>? ?? {};
    setState(() {
      if (p["recipient_group"] is String)
        group = p["recipient_group"] as String;
      if ((p["hospital_name"] as String?)?.isNotEmpty == true)
        hospital.text = p["hospital_name"] as String;
      if ((p["ward"] as String?)?.isNotEmpty == true)
        ward.text = p["ward"] as String;
      if ((p["bed"] as String?)?.isNotEmpty == true)
        bed.text = p["bed"] as String;
      if (p["units"] != null) units.text = "${p["units"]}";
      if (p["component"] is String) component = p["component"] as String;
      if (p["urgency"] is String) urgency = p["urgency"] as String;
      status = humanOf(j);
    });
  }

  Future<void> _send() async {
    await api.post(
        "/v1/me", {"phone": phone.text, "language": widget.hi ? "hi" : "en"});
    final body = {
      "recipient_group": group,
      "component": component,
      "units": int.tryParse(units.text) ?? 2,
      "lat": here.latitude,
      "lng": here.longitude,
      "hospital_name": hospital.text,
      "ward": ward.text,
      "bed": bed.text,
      "urgency": urgency,
      "language": widget.hi ? "hi" : "en",
      "minor_patient": minor,
      "guardian_name": guardian.text,
      "women_first": womenFirst,
    };
    try {
      final j = await api.post("/v1/blood-requests", body);
      final rec = j["request"] as Map<String, dynamic>? ?? {};
      final guest = rec["guest_url"] ?? "";
      lastId = rec["id"] as String? ?? "";
      setState(() => status = "${humanOf(j)}\n$kApiBase$guest");
      if (j["merged"] != true && context.mounted) {
        pauseBus.show(PauseNote(
            code: "breath",
            title: widget.hi
                ? "आपका भरोसे का परिवार पहले सुन रहा है"
                : "Your trusted family is hearing first",
            line: widget.hi
                ? "यहीं रुकें। आठ सेकंड। कुछ और नहीं भेजा गया।"
                : "Stay here for a moment. Nothing else was sent yet."));
        Future<void>.delayed(const Duration(seconds: 8), pauseBus.ok);
      }
    } catch (_) {
      final p = await SharedPreferences.getInstance();
      await p.setString("offline_sos", jsonEncode(body));
      setState(() => status = widget.hi
          ? "इंटरनेट नहीं है। यह फोन पर सेव हो गया। इंटरनेट आने पर SaHayak फिर खोलें।"
          : "No internet right now. Saved on this phone. Open SaHayak again once you have internet.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Mark(line: t.locBody),
              const SizedBox(height: 12),
              if (!saver) MiniMap(center: here),
              SwitchListTile(
                  title: const Text("Night skin"),
                  value: night,
                  onChanged: (v) => setState(() => night = v)),
              DataSaverStrip(
                  onDismiss:
                      saver ? () => setState(() => saver = false) : null),
              SwitchListTile(
                  title: const Text("Data saver — city list is enough"),
                  value: saver,
                  onChanged: (v) => setState(() => saver = v)),
              SwitchListTile(
                  title: const Text("Women-first whisper (optional)"),
                  value: womenFirst,
                  onChanged: (v) => setState(() => womenFirst = v)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                FilledButton.icon(
                    onPressed: _gps,
                    icon: const Icon(Icons.place_outlined),
                    style: FilledButton.styleFrom(backgroundColor: kTrust),
                    label: Text(t.useGps)),
                DropdownButton<String>(
                  value: city,
                  dropdownColor: kInk,
                  items: cities.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    city = v!;
                    here = cities[v]!;
                  }),
                ),
              ]),
              Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: paste,
                      maxLines: 3,
                      decoration: InputDecoration(
                          labelText: t.paste,
                          hintText: "B+ 2 units SSKM ward 7 now"),
                    ),
                    TextButton.icon(
                        onPressed: _fillPaste,
                        icon:
                            const Icon(Icons.chat_bubble_outline, color: kGold),
                        label: Text(t.fillForm,
                            style: const TextStyle(color: kGold))),
                    TextField(
                      controller: slip,
                      decoration: InputDecoration(
                          labelText: t.slipLine,
                          hintText: "B+ 2 units SSKM ward 7"),
                    ),
                    TextButton.icon(
                        onPressed: _fillSlip,
                        icon: const Icon(Icons.document_scanner_outlined,
                            color: kGold),
                        label: Text(t.slipFill,
                            style: const TextStyle(color: kGold))),
                    if (notebook.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: notebook
                            .map(
                              (p) => ActionChip(
                                label: Text("${p["who"]} · ${p["group"]}"),
                                onPressed: () =>
                                    setState(() => group = "${p["group"]}"),
                              ),
                            )
                            .toList(),
                      ),
                    Wrap(
                      spacing: 8,
                      children: groups
                          .map((g) => ChoiceChip(
                              label: Text(g),
                              selected: group == g,
                              selectedColor: kGold,
                              onSelected: (_) => setState(() => group = g)))
                          .toList(),
                    ),
                    TextField(
                        decoration: InputDecoration(labelText: t.hospital),
                        controller: hospital),
                    TextField(
                        decoration: const InputDecoration(labelText: "Ward"),
                        controller: ward),
                    TextField(
                        decoration: const InputDecoration(labelText: "Bed"),
                        controller: bed),
                    TextField(
                        decoration: const InputDecoration(labelText: "Units"),
                        controller: units,
                        keyboardType: TextInputType.number),
                    DropdownButton<String>(
                      value: component,
                      dropdownColor: kInk,
                      items: const [
                        DropdownMenuItem(value: "whole", child: Text("Whole")),
                        DropdownMenuItem(
                            value: "platelets", child: Text("Platelets")),
                        DropdownMenuItem(
                            value: "plasma", child: Text("Plasma")),
                      ],
                      onChanged: (v) => setState(() => component = v!),
                    ),
                    DropdownButton<String>(
                      value: urgency,
                      dropdownColor: kInk,
                      items: const [
                        DropdownMenuItem(
                            value: "critical", child: Text("Tonight / now")),
                        DropdownMenuItem(
                            value: "scheduled", child: Text("Planned surgery")),
                      ],
                      onChanged: (v) => setState(() => urgency = v!),
                    ),
                    TextField(
                        decoration: const InputDecoration(
                            labelText: "Your phone (after accept only)"),
                        controller: phone),
                    SwitchListTile(
                        title: const Text("Child patient"),
                        value: minor,
                        onChanged: (v) => setState(() => minor = v)),
                    if (minor)
                      TextField(
                          decoration:
                              const InputDecoration(labelText: "Guardian name"),
                          controller: guardian),
                    const SizedBox(height: 12),
                    Giant(
                        icon: Icons.send_rounded,
                        label: t.send,
                        sub: t.sendSub,
                        sos: true,
                        onTap: _send),
                    if (lastId.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final j = await api
                              .post("/v1/blood-requests/$lastId/undo", {});
                          if (mounted) setState(() => status = humanOf(j));
                        },
                        child: Text(
                            widget.hi
                                ? "गलत ग्रुप? वापस लें (2 मिनट)"
                                : "Picked the wrong blood group? Undo it (2 minutes)",
                            style: const TextStyle(color: kGold)),
                      ),
                    if (lastId.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          final j = await api.post(
                              "/v1/blood-requests/$lastId/still-need", {});
                          if (mounted) setState(() => status = humanOf(j));
                        },
                        child: Text(
                            widget.hi
                                ? "अभी भी रक्त चाहिए"
                                : "Still waiting for blood",
                            style: const TextStyle(color: kGold)),
                      ),
                    const SizedBox(height: 12),
                    Text(status,
                        style: const TextStyle(height: 1.45, fontSize: 16)),
                    if (lastId.isNotEmpty)
                      WalkToDoorCard(
                          hospital: hospital.text,
                          ward: ward.text,
                          language: widget.hi ? "hi" : "en"),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:
                            Text(t.home, style: const TextStyle(color: kGold))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key, required this.hi});
  final bool hi;
  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  String group = "O+";
  bool available = true;
  bool selfHold = false;
  bool woman = false;
  bool fastingHold = false;
  bool feverHold = false;
  int? lastDonationDaysAgo;
  int eligibleAfterDays = 90;
  bool nightMode = false;
  String city = "Kolkata";
  LatLng here = cities["Kolkata"]!;
  String status = "";
  List<dynamic> open = [];
  final phone = TextEditingController(text: "9000000000");

  L get t => L(widget.hi);

  Future<void> _save() async {
    final donorResult = await api.post("/v1/donors/me", {
      "blood_group": group,
      "lat": here.latitude,
      "lng": here.longitude,
      "available": available,
      "self_hold": selfHold,
      "phone": phone.text,
      "city": city,
      "woman": woman,
      "fasting_hold": fastingHold,
      "fever_hold": feverHold,
      "language": widget.hi ? "hi" : "en",
    });
    final g = await api.get("/v1/grace-date");
    final j = await api.get("/v1/blood-requests/open");
    final me = await api.get("/v1/me");
    setState(() {
      open = j["requests"] as List<dynamic>? ?? [];
      eligibleAfterDays =
          (g["next_eligible_days_after_donation"] as num?)?.toInt() ?? 90;
      lastDonationDaysAgo = (me["last_donation_days_ago"] as num?)?.toInt();
      status = humanOf(donorResult, humanOf(j));
    });
  }

  Future<void> _setHold({bool? fasting, bool? fever}) async {
    final nextFasting = fasting ?? fastingHold;
    final nextFever = fever ?? feverHold;
    if (nextFasting && nextFever) {
      setState(() => status = widget.hi
          ? "एक साथ दोनों होल्ड नहीं चुन सकते।"
          : "Choose fasting or fever, not both.");
      return;
    }
    final j = await setDonorHold(fasting: nextFasting, fever: nextFever);
    if (!mounted) return;
    setState(() {
      fastingHold = nextFasting;
      feverHold = nextFever;
      status = humanOf(j);
    });
  }

  Future<void> _accept(String id) async {
    final j = await api.post("/v1/blood-requests/$id/accept", {});
    final tel = j["phone"] as String? ?? "";
    setState(() => status = humanOf(j));
    if (tel.isNotEmpty) {
      await launchUrl(Uri.parse("tel:$tel"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pins = open.map((r) {
      final m = r as Map<String, dynamic>;
      return Marker(
        point: LatLng((m["lat"] as num?)?.toDouble() ?? here.latitude,
            (m["lng"] as num?)?.toDouble() ?? here.longitude),
        child: const Icon(Icons.water_drop, color: kSos),
      );
    }).toList();
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Mark(line: t.locBodyDon),
              NightModeToggle(
                isActive: nightMode,
                language: widget.hi ? "hi" : "en",
                onToggle: (v) async {
                  final j = await setNightMode(v);
                  if (mounted)
                    setState(() {
                      nightMode = v;
                      status = humanOf(j);
                    });
                },
              ),
              MiniMap(center: here, markers: pins),
              TextButton.icon(
                onPressed: () async {
                  final p = await askLocation(context, t);
                  if (p != null) setState(() => here = p);
                },
                icon: const Icon(Icons.place_outlined, color: kGold),
                label: Text(t.useGps, style: const TextStyle(color: kGold)),
              ),
              Glass(
                child: Column(
                  children: [
                    DonorHoldCard(
                      fastingActive: fastingHold,
                      feverActive: feverHold,
                      language: widget.hi ? "hi" : "en",
                      onFastingToggle: (v) =>
                          _setHold(fasting: v, fever: v ? false : feverHold),
                      onFeverToggle: (v) =>
                          _setHold(fever: v, fasting: v ? false : fastingHold),
                    ),
                    const SizedBox(height: 12),
                    GraceDateCard(
                      lastDonationDaysAgo: lastDonationDaysAgo,
                      nextEligibleDaysAway: eligibleAfterDays,
                      language: widget.hi ? "hi" : "en",
                    ),
                    Wrap(
                      spacing: 8,
                      children: groups
                          .map((g) => ChoiceChip(
                              label: Text(g),
                              selected: group == g,
                              selectedColor: kGold,
                              onSelected: (_) => setState(() => group = g)))
                          .toList(),
                    ),
                    SwitchListTile(
                        title: Text(t.available),
                        value: available,
                        onChanged: (v) => setState(() => available = v)),
                    SwitchListTile(
                        title: Text(t.skipPings),
                        value: selfHold,
                        onChanged: (v) => setState(() => selfHold = v)),
                    TextField(
                        controller: phone,
                        decoration: const InputDecoration(labelText: "Phone")),
                    FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check),
                        style: FilledButton.styleFrom(backgroundColor: kTrust),
                        label: Text(t.donate)),
                    Text(status, style: const TextStyle(height: 1.45)),
                    ...open.map((r) {
                      final m = r as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                            "${m["recipient_group"]} at ${m["hospital_name"]}"),
                        subtitle:
                            Text("${t.phoneHidden} · ${m["units_progress"]}"),
                        isThreeLine: true,
                        trailing: TextButton(
                            onPressed: () => _accept(m["id"] as String),
                            child: Text(t.iCanGo)),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: kInk,
                            title: Text("${m["hospital_name"]}"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BagProgressVisual(
                                  total: (m["bag_progress"]?["total"] as num?)
                                          ?.toInt() ??
                                      0,
                                  accepted:
                                      (m["bag_progress"]?["accepted"] as num?)
                                              ?.toInt() ??
                                          0,
                                  remaining:
                                      (m["bag_progress"]?["remaining"] as num?)
                                              ?.toInt() ??
                                          0,
                                ),
                                SurgeonWaitingPulse(
                                  unitsNeeded:
                                      (m["bag_progress"]?["remaining"] as num?)
                                              ?.toInt() ??
                                          0,
                                  isActive: m["surgeon_waiting"] == true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:
                            Text(t.home, style: const TextStyle(color: kGold))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.hi});
  final bool hi;
  L get t => L(hi);

  Future<void> _snack(BuildContext context, String path, [Object? body]) async {
    final j = body == null ? await api.get(path) : await api.post(path, body);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(humanOf(j, jsonEncode(j)))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Mark(line: t.more),
              Glass(
                child: Column(
                  children: [
                    ListTile(
                        leading: const Icon(Icons.inbox_outlined, color: kGold),
                        title: Text(hi ? "मेरे संदेश" : "My messages"),
                        subtitle: Text(hi
                            ? "जो लोगों ने आपको भेजा"
                            : "What people sent you"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const HumanScreen("Inbox", "/v1/inbox")))),
                    ListTile(
                        leading:
                            const Icon(Icons.chat_bubble_outline, color: kGold),
                        title: Text(hi ? "सवाल पूछें" : "Ask a question"),
                        subtitle: Text(hi
                            ? "आसान भाषा में जवाब मिलेगा"
                            : "Get a simple answer, in plain words"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AssistantScreen()))),
                    ListTile(
                        leading: const Icon(Icons.place_outlined, color: kGold),
                        title: Text(hi ? "पास की मदद" : "Help near me"),
                        subtitle: Text(hi
                            ? "पास के ब्लड बैंक और मदद"
                            : "Blood banks and helpers close to you"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HumanScreen(
                                    "Directory", "/v1/directory")))),
                    ListTile(
                        leading:
                            const Icon(Icons.menu_book_outlined, color: kGold),
                        title: Text(hi ? "परिवार के नाम" : "Family names"),
                        subtitle: Text(hi
                            ? "सिर्फ़ आपके लिए। किसी को नहीं दिखेगा।"
                            : "Just for you. No one else can see this."),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EasyExtraScreen(
                                    kind: EasyKind.notebook, hi: hi)))),
                    ListTile(
                        leading: const Icon(Icons.event_repeat, color: kGold),
                        title: Text(hi
                            ? "हर महीने की ज़रूरत"
                            : "Blood needed every month"),
                        subtitle: Text(hi
                            ? "जैसे थैलेसीमिया या डायलिसिस"
                            : "For ongoing needs like thalassemia or dialysis"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EasyExtraScreen(
                                    kind: EasyKind.lane, hi: hi)))),
                    ListTile(
                        leading:
                            const Icon(Icons.groups_outlined, color: kGold),
                        title: Text(hi
                            ? "आज इसी अस्पताल में"
                            : "Same hospital tonight"),
                        subtitle: Text(hi
                            ? "इंतज़ार या गाड़ी साथ में बाँटें"
                            : "Share a wait or a ride with others here"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EasyExtraScreen(
                                    kind: EasyKind.sameNight, hi: hi)))),
                    ListTile(
                        leading: const Icon(Icons.train_outlined, color: kGold),
                        title: Text(hi
                            ? "इस ट्रेन में मदद"
                            : "Help on this train ride"),
                        subtitle: Text(hi
                            ? "उतरने के बाद यह अपने आप बंद हो जाता है"
                            : "Turns off by itself when your ride ends"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EasyExtraScreen(
                                    kind: EasyKind.ride, hi: hi)))),
                    ListTile(
                        leading: const Icon(Icons.nights_stay_outlined,
                            color: kGold),
                        title: Text(hi ? "रात में खुला" : "Open at night"),
                        subtitle: Text(hi
                            ? "रात 10 बजे के बाद खुले ब्लड बैंक"
                            : "Blood banks open after 10pm"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EasyExtraScreen(
                                    kind: EasyKind.night, hi: hi)))),
                    ListTile(
                        leading:
                            const Icon(Icons.favorite_border, color: kGold),
                        title: Text(
                            hi ? "मेरा भरोसे का परिवार" : "My trusted family"),
                        subtitle: Text(hi
                            ? "यही लोग सबसे पहले सुनेंगे"
                            : "These are the people who hear from you first"),
                        onTap: () => _snack(context, "/v1/family-ring",
                            ["trusted-1", "trusted-2"])),
                    ListTile(
                        leading:
                            const Icon(Icons.groups_outlined, color: kGold),
                        title: Text(hi ? "मेरे पड़ोसी" : "My neighbours"),
                        subtitle: Text(hi
                            ? "आपकी सोसाइटी या इलाके के लोग"
                            : "People in your building or local area"),
                        onTap: () => _snack(context, "/v1/society-ring",
                            {"society_id": "demo-society"})),
                    ListTile(
                        leading: const Icon(Icons.schedule, color: kGold),
                        title: Text(hi
                            ? "मैं कब दे सकता हूँ"
                            : "When I can give blood"),
                        subtitle: Text(hi
                            ? "जगह और समय बताएँ"
                            : "Tell others the place and time you're free"),
                        onTap: () => _snack(context, "/v1/give-windows",
                            {"place": "Howrah", "until": "19:00"})),
                    ListTile(
                        leading: const Icon(Icons.directions_car_outlined,
                            color: kGold),
                        title: Text(hi
                            ? "बिना रक्त दिए मदद"
                            : "Help without giving blood"),
                        subtitle: Text(hi
                            ? "गाड़ी या साथ देकर मदद करें"
                            : "Offer a ride or keep someone company"),
                        onTap: () => _snack(context, "/v1/help-without-blood",
                            {"kind": "ride"})),
                    ListTile(
                        leading:
                            const Icon(Icons.visibility_outlined, color: kGold),
                        title: Text(hi
                            ? "दुर्लभ ग्रुप की सूचना"
                            : "Alert for rare blood types"),
                        subtitle: Text(hi
                            ? "सिर्फ़ दुर्लभ ग्रुप चाहिए हो तभी बताएँ"
                            : "Only tell me when a rare blood type is needed"),
                        onTap: () =>
                            _snack(context, "/v1/rare-watch", ["Bombay"])),
                    ListTile(
                        leading:
                            const Icon(Icons.shield_outlined, color: kGold),
                        title: Text(hi
                            ? "मैं सुरक्षित हूँ - बताएँ"
                            : "Tell family I'm safe"),
                        subtitle: Text(hi
                            ? "पहुँचने का समय बताएँ"
                            : "Share when you expect to arrive"),
                        onTap: () => _snack(
                            context, "/v1/checkin", {"eta_minutes": 20})),
                    ListTile(
                        leading:
                            const Icon(Icons.campaign_outlined, color: kGold),
                        title:
                            Text(hi ? "रक्तदान शिविर" : "Blood donation camps"),
                        subtitle: Text(hi
                            ? "पास का शिविर खोजें और सीट बुक करें"
                            : "Find one near you and book your seat"),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const HumanScreen("Camps", "/v1/camps")))),
                    ListTile(
                      leading: const Icon(Icons.content_copy, color: kGold),
                      title: Text(hi
                          ? "व्हाट्सऐप के लिए स्थिति कॉपी करें"
                          : "Copy update for WhatsApp"),
                      onTap: () async {
                        final mine = await api.get("/v1/blood-requests/mine");
                        final rows = mine["requests"] as List<dynamic>? ?? [];
                        if (rows.isEmpty) {
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Send Need blood first.")));
                          return;
                        }
                        final id = (rows.first as Map)["id"];
                        final card = await api.get("/v1/status-card/$id");
                        await Clipboard.setData(ClipboardData(
                            text: humanOf(card, jsonEncode(card))));
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Copied. You paste it yourself.")));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: kSos),
                      title:
                          Text(t.delete, style: const TextStyle(color: kSos)),
                      onTap: () async {
                        final j = await api.delete("/v1/me");
                        api.token = null;
                        await api.persistToken();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(humanOf(j))));
                          Navigator.popUntil(context, (r) => r.isFirst);
                        }
                      },
                    ),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:
                            Text(t.home, style: const TextStyle(color: kGold))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HumanScreen extends StatefulWidget {
  const HumanScreen(this.title, this.path, {super.key});
  final String title;
  final String path;
  @override
  State<HumanScreen> createState() => _HumanScreenState();
}

class _HumanScreenState extends State<HumanScreen> {
  String body = "One moment…";
  @override
  void initState() {
    super.initState();
    api
        .get(widget.path)
        .then((j) => setState(() => body = humanOf(j, jsonEncode(j))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Glass(
                child: Text(body,
                    style: const TextStyle(fontSize: 18, height: 1.5))),
          ),
        ),
      ),
    );
  }
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final text = TextEditingController(text: "need B+ at SSKM");
  String out =
      "Ask me anything about getting or giving blood. I answer in simple words.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Glass(
              child: Column(
                children: [
                  TextField(controller: text),
                  FilledButton(
                    onPressed: () async {
                      final j = await api.post("/v1/assistant/messages",
                          {"text": text.text, "lat": "22.57", "lng": "88.36"});
                      setState(() => out = humanOf(j));
                    },
                    child: const Text("Ask"),
                  ),
                  const SizedBox(height: 12),
                  Text(out, style: const TextStyle(height: 1.45)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum EasyKind { notebook, lane, sameNight, ride, night }

class EasyExtraScreen extends StatefulWidget {
  const EasyExtraScreen({super.key, required this.kind, required this.hi});
  final EasyKind kind;
  final bool hi;
  @override
  State<EasyExtraScreen> createState() => _EasyExtraScreenState();
}

class _EasyExtraScreenState extends State<EasyExtraScreen> {
  String group = "O-";
  String corridor = "Sealdah";
  String due = "12";
  String status = "";
  List<Map<String, dynamic>> people = [];
  List<dynamic> mates = [];
  List<dynamic> night = [];
  final who = TextEditingController();
  final hosp = TextEditingController(text: "SSKM");
  final units = TextEditingController(text: "1");

  String get title {
    switch (widget.kind) {
      case EasyKind.notebook:
        return widget.hi ? "परिवार के नाम" : "Family names";
      case EasyKind.lane:
        return widget.hi ? "हर महीने की ज़रूरत" : "Blood needed every month";
      case EasyKind.sameNight:
        return widget.hi ? "आज इसी अस्पताल में" : "Same hospital tonight";
      case EasyKind.ride:
        return widget.hi ? "इस ट्रेन में मदद" : "Help on this train ride";
      case EasyKind.night:
        return widget.hi ? "रात में खुला" : "Open at night";
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.kind == EasyKind.notebook) _loadNb();
    if (widget.kind == EasyKind.night) _night();
  }

  Future<void> _loadNb() async {
    final j = await api.get("/v1/family-notebook");
    final rows = j["people"] as List<dynamic>? ?? [];
    if (!mounted) return;
    setState(() {
      people = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      status = humanOf(j);
    });
  }

  Future<void> _night() async {
    final j = await api.get("/v1/directory?night=true");
    if (!mounted) return;
    setState(() {
      night = j["entries"] as List<dynamic>? ?? [];
      status = humanOf(j);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stage(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Mark(line: title),
              Glass(child: _body()),
              const SizedBox(height: 12),
              Text(status, style: const TextStyle(height: 1.45, fontSize: 16)),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("More", style: TextStyle(color: kGold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (widget.kind) {
      case EasyKind.notebook:
        return Column(
          children: [
            TextField(
                controller: who,
                decoration:
                    const InputDecoration(labelText: "Who", hintText: "Dadi")),
            Wrap(
              spacing: 8,
              children: groups
                  .map((g) => ChoiceChip(
                      label: Text(g),
                      selected: group == g,
                      selectedColor: kGold,
                      onSelected: (_) => setState(() => group = g)))
                  .toList(),
            ),
            FilledButton.icon(
              onPressed: () async {
                final j = await api.post(
                    "/v1/family-notebook", {"who": who.text, "group": group});
                if (!mounted) return;
                setState(() => status = humanOf(j));
                await _loadNb();
              },
              icon: const Icon(Icons.check),
              style: FilledButton.styleFrom(backgroundColor: kTrust),
              label: const Text("Save this name"),
            ),
            ...people.map((p) => ListTile(
                title: Text("${p["who"]} · ${p["group"]}"),
                subtitle: const Text("Private. Not on a map."))),
          ],
        );
      case EasyKind.lane:
        return Column(
          children: [
            Text(widget.hi
                ? "हर महीने की ज़रूरत। शांत तरीके से। सिर्फ़ भरोसे के परिवार को बताया जाता है।"
                : "For a need that repeats every month. Sent quietly, only to your trusted family."),
            Wrap(
              spacing: 8,
              children: groups
                  .map((g) => ChoiceChip(
                      label: Text(g),
                      selected: group == g,
                      selectedColor: kGold,
                      onSelected: (_) => setState(() => group = g)))
                  .toList(),
            ),
            TextField(
                controller: hosp,
                decoration: const InputDecoration(labelText: "Hospital")),
            TextField(
                controller: units,
                decoration: const InputDecoration(labelText: "Units"),
                keyboardType: TextInputType.number),
            DropdownButton<String>(
              value: due,
              dropdownColor: kInk,
              items: [
                for (var i = 1; i <= 28; i++)
                  DropdownMenuItem(value: "$i", child: Text("Day $i"))
              ],
              onChanged: (v) => setState(() => due = v!),
            ),
            FilledButton.icon(
              onPressed: () async {
                final j = await api.post("/v1/blood-requests", {
                  "recipient_group": group,
                  "component": "whole",
                  "units": int.tryParse(units.text) ?? 1,
                  "lat": 22.5726,
                  "lng": 88.3639,
                  "hospital_name": hosp.text,
                  "urgency": "scheduled",
                  "lane": "regular",
                  "due_on": due,
                  "language": widget.hi ? "hi" : "en",
                });
                if (!mounted) return;
                setState(() => status = humanOf(j));
              },
              icon: const Icon(Icons.send),
              style: FilledButton.styleFrom(backgroundColor: kTrust),
              label: const Text("Ask quietly for this bag"),
            ),
          ],
        );
      case EasyKind.sameNight:
        return Column(
          children: [
            TextField(
                controller: hosp,
                decoration: const InputDecoration(labelText: "Hospital")),
            FilledButton.icon(
              onPressed: () async {
                final j = await api.get(
                    "/v1/same-night?hospital=${Uri.encodeQueryComponent(hosp.text)}");
                if (!mounted) return;
                setState(() {
                  mates = j["mates"] as List<dynamic>? ?? [];
                  status = humanOf(j);
                });
              },
              icon: const Icon(Icons.visibility_outlined),
              style: FilledButton.styleFrom(backgroundColor: kTrust),
              label: const Text("Who else is here?"),
            ),
            ...mates.map((m) {
              final row = m as Map;
              return ListTile(
                  title: Text("${row["group"]} · ${row["units_progress"]}"),
                  subtitle: Text("Ward ${row["ward"] ?? "—"} · no phone"));
            }),
            TextButton.icon(
              onPressed: () async {
                final j = await api.post("/v1/same-night/share",
                    {"hospital_name": hosp.text, "kind": "wait"});
                if (mounted) setState(() => status = humanOf(j));
              },
              icon: const Icon(Icons.hourglass_empty, color: kGold),
              label: const Text("Offer a shared wait",
                  style: TextStyle(color: kGold)),
            ),
            TextButton.icon(
              onPressed: () async {
                final j = await api.post("/v1/same-night/share",
                    {"hospital_name": hosp.text, "kind": "cab"});
                if (mounted) setState(() => status = humanOf(j));
              },
              icon: const Icon(Icons.directions_car_outlined, color: kGold),
              label: const Text("Offer a shared cab",
                  style: TextStyle(color: kGold)),
            ),
          ],
        );
      case EasyKind.ride:
        return Column(
          children: [
            Wrap(
              spacing: 8,
              children: ["Howrah", "Sealdah", "New Delhi"]
                  .map((c) => ChoiceChip(
                      label: Text(c),
                      selected: corridor == c,
                      selectedColor: kGold,
                      onSelected: (_) => setState(() => corridor = c)))
                  .toList(),
            ),
            FilledButton.icon(
              onPressed: () async {
                final j = await api.post("/v1/give-windows", {
                  "kind": "ride",
                  "corridor": corridor,
                  "minutes": 40,
                  "lat": 22.57,
                  "lng": 88.36
                });
                if (mounted) setState(() => status = humanOf(j));
              },
              icon: const Icon(Icons.train),
              style: FilledButton.styleFrom(backgroundColor: kTrust),
              label: const Text("I am on this local"),
            ),
          ],
        );
      case EasyKind.night:
        return Column(
          children: night.isEmpty
              ? [const Text("Looking for night desks…")]
              : night.map((e) {
                  final row = e as Map;
                  return ListTile(
                    leading: const Icon(Icons.nights_stay, color: kGold),
                    title: Text("${row["name"]}"),
                    subtitle: Text("${row["hours"]} · ${row["phone"] ?? ""}"),
                  );
                }).toList(),
        );
    }
  }
}
