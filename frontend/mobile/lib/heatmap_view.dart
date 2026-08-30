/// Heatmap visualization for need density (golden fog, no names/phones).
library;

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";

const Color kGold = Color(0xFFE8C07A);
const Color kInk = Color(0xFF0C0610);

/// Heatmap point with intensity for visualization.
class HeatmapPoint {
  HeatmapPoint({
    required this.lat,
    required this.lng,
    required this.intensity, // 0-100
    required this.unitsNeeded,
    required this.unitsAccepted,
  });

  final double lat;
  final double lng;
  final double intensity;
  final int unitsNeeded;
  final int unitsAccepted;

  LatLng get latlng => LatLng(lat, lng);
}

/// Golden fog heatmap layer.
/// Shows need density without revealing names or phones.
class HeatmapVisualizationLayer extends StatelessWidget {
  const HeatmapVisualizationLayer({
    super.key,
    required this.points,
    required this.language,
  });

  final List<HeatmapPoint> points;
  final String language;

  Color _colorForIntensity(double intensity) {
    // Gradient: low intensity (cool) → high intensity (hot/gold)
    if (intensity < 25) return const Color(0xFF8B7355).withValues(alpha: 0.3); // Brown
    if (intensity < 50) return const Color(0xFFCD7F32).withValues(alpha: 0.4); // Bronze
    if (intensity < 75) return kGold.withValues(alpha: 0.5); // Gold
    return kGold.withValues(alpha: 0.7); // Bright gold
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(
        child: Text(
          language.toLowerCase().startsWith("hi")
              ? "कोई खुली रिक्वेस्ट नहीं"
              : "No open requests",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              points.fold(0.0, (sum, p) => sum + p.lat) / points.length,
              points.fold(0.0, (sum, p) => sum + p.lng) / points.length,
            ),
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ["a", "b", "c"],
              userAgentPackageName: "com.sahayak.mobile",
            ),
            MarkerLayer(
              markers: points.map((p) {
                final color = _colorForIntensity(p.intensity);
                final size = 15 + (p.intensity / 100 * 20); // 15-35px
                
                return Marker(
                  point: p.latlng,
                  width: size,
                  height: size,
                  child: Tooltip(
                    message:
                        "${p.unitsNeeded} units needed, ${p.unitsAccepted} accepted",
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        
        // Legend and info
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kInk.withValues(alpha: 0.9),
              border: Border.all(color: kGold, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.toLowerCase().startsWith("hi")
                      ? "जरूरत का घनत्व"
                      : "Need intensity",
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B7355).withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      language.toLowerCase().startsWith("hi")
                          ? "कम"
                          : "Low",
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGold.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      language.toLowerCase().startsWith("hi")
                          ? "अधिक"
                          : "High",
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  language.toLowerCase().startsWith("hi")
                      ? "कोई नाम या फोन नहीं"
                      : "No names or phones",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple heatmap grid (alternative to map-based visualization).
/// Shows need density in a grid format.
class HeatmapGridView extends StatelessWidget {
  const HeatmapGridView({
    super.key,
    required this.points,
    required this.language,
  });

  final List<HeatmapPoint> points;
  final String language;

  Color _colorForIntensity(double intensity) {
    if (intensity < 25) return Colors.grey[800]!;
    if (intensity < 50) return const Color(0xFFCD7F32);
    if (intensity < 75) return kGold;
    return kGold;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.toLowerCase().startsWith("hi")
                  ? "खुली रिक्वेस्ट (नाम नहीं, सिर्फ़ गहराई)"
                  : "Open requests (no names, intensity only)",
              style: const TextStyle(
                color: kGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              Center(
                child: Text(
                  language.toLowerCase().startsWith("hi")
                      ? "अभी कोई खुली रिक्वेस्ट नहीं"
                      : "No open requests right now",
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              ...points
                  .asMap()
                  .entries
                  .map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    final color = _colorForIntensity(p.intensity);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          border: Border.all(color: color, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    language.toLowerCase().startsWith("hi")
                                        ? "रिक्वेस्ट ${i + 1}"
                                        : "Request ${i + 1}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    language.toLowerCase().startsWith("hi")
                                        ? "${p.unitsNeeded} चाहिए, ${p.unitsAccepted} मिल गए"
                                        : "${p.unitsNeeded} needed, ${p.unitsAccepted} accepted",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${p.intensity.toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
          ],
        ),
      ),
    );
  }
}
