/// Night mode theme and donor hold management for enhanced experience.
library;

import "package:flutter/material.dart";

const Color kSos = Color(0xFFC42B4A);
const Color kTrust = Color(0xFF1AA58A);
const Color kGold = Color(0xFFE8C07A);
const Color kInk = Color(0xFF0C0610);

/// Night mode theme for 2am ward attendants.
/// Huge text, two buttons, gold on black.
class NightModeTheme {
  static ThemeData create() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      colorScheme: const ColorScheme.dark(
        primary: kGold,
        secondary: kGold,
        surface: Color(0xFF050505),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: kGold,
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        displayMedium: TextStyle(
          color: kGold,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      useMaterial3: true,
    );
  }
}

/// Donor hold status display and management.
/// Shows fasting/fever hold with visual indicator.
class DonorHoldCard extends StatelessWidget {
  const DonorHoldCard({
    super.key,
    required this.fastingActive,
    required this.feverActive,
    required this.onFastingToggle,
    required this.onFeverToggle,
    required this.language,
  });

  final bool fastingActive;
  final bool feverActive;
  final ValueChanged<bool> onFastingToggle;
  final ValueChanged<bool> onFeverToggle;
  final String language;

  @override
  Widget build(BuildContext context) {
    final hi = language.toLowerCase().startsWith("hi");
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A14),
        border: Border.all(
          color: (fastingActive || feverActive) ? kGold : Colors.grey[700]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.healing,
                color: (fastingActive || feverActive) ? kGold : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hi ? "आज की स्थिति" : "Today's status",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Fasting hold toggle
          _HoldToggleRow(
            icon: Icons.restaurant,
            label: hi ? "भूखा हूँ" : "Fasting",
            isActive: fastingActive,
            onToggle: onFastingToggle,
            sublabel: hi ? "खाना खा लूँ तो फिर हाजिर" : "Will be available after eating",
          ),
          const SizedBox(height: 12),
          
          // Fever hold toggle
          _HoldToggleRow(
            icon: Icons.local_fire_department,
            label: hi ? "बुख़ार है" : "Have fever",
            isActive: feverActive,
            onToggle: onFeverToggle,
            sublabel: hi ? "ठीक हो जाऊँ तो बुलाना" : "Call when I'm well",
          ),
          
          if (fastingActive || feverActive) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: kGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hi
                          ? "कोई भी पिंग नहीं। आराम करो। ठीक हो जाने के बाद ही आएँ।"
                          : "You won't be pinged. Rest and recover. Come back later.",
                      style: const TextStyle(
                        color: kGold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HoldToggleRow extends StatelessWidget {
  const _HoldToggleRow({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onToggle,
    required this.sublabel,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isActive),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? kGold.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isActive ? kGold : Colors.grey[700]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? kGold : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? kGold : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? kGold : Colors.grey[700],
                border: Border.all(
                  color: isActive ? kGold : Colors.grey[600]!,
                  width: 2,
                ),
              ),
              child: isActive
                  ? const Icon(Icons.check, color: kInk, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Grace date information card.
/// "You gave ~N days ago. Informational, not medical advice."
class GraceDateCard extends StatelessWidget {
  const GraceDateCard({
    super.key,
    required this.lastDonationDaysAgo,
    required this.nextEligibleDaysAway,
    required this.language,
  });

  final int? lastDonationDaysAgo;
  final int nextEligibleDaysAway;
  final String language;

  @override
  Widget build(BuildContext context) {
    final hi = language.toLowerCase().startsWith("hi");
    
    if (lastDonationDaysAgo == null || lastDonationDaysAgo! < 0) {
      return const SizedBox.shrink();
    }

    final isEligible = lastDonationDaysAgo! >= nextEligibleDaysAway;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isEligible ? const Color(0xFF1AA58A) : kSos).withValues(alpha: 0.1),
        border: Border.all(
          color: isEligible ? const Color(0xFF1AA58A) : kSos,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isEligible ? Icons.check_circle : Icons.schedule,
            color: isEligible ? const Color(0xFF1AA58A) : kSos,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEligible
                      ? (hi ? "आप अब दे सकते हैं" : "You're eligible now")
                      : (hi
                          ? "आप अभी नहीं दे सकते"
                          : "Not eligible yet"),
                  style: TextStyle(
                    color: isEligible
                        ? const Color(0xFF1AA58A)
                        : kSos,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hi
                      ? "आपने $lastDonationDaysAgo दिन पहले दिया था"
                      : "You donated $lastDonationDaysAgo days ago",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hi
                      ? "चिकित्सीय सलाह नहीं। सिर्फ़ जानकारी।"
                      : "Not medical advice. Informational only.",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
