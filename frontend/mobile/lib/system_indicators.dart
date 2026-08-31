/// Utility widgets for battery, data saver, dead buttons, and system indicators.
library;

import "package:flutter/material.dart";

const Color kGold = Color(0xFFE8C07A);
const Color kSos = Color(0xFFC42B4A);
const Color kInk = Color(0xFF0C0610);

/// Low-battery warning strip.
/// Shows when battery < 20%. Same page, no popup.
class LowBatteryStrip extends StatelessWidget {
  const LowBatteryStrip({
    super.key,
    required this.batteryPercent,
    required this.onDismiss,
  });

  final int batteryPercent;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (batteryPercent >= 20) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kSos.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: kSos, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.battery_alert,
            color: kSos,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Low battery ($batteryPercent%)",
                  style: const TextStyle(
                    color: kSos,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "Maps off. Use city list.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Data-saver mode warning strip.
/// Shows when data saver is on. Same page, no popup.
class DataSaverStrip extends StatelessWidget {
  const DataSaverStrip({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kGold.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: kGold, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.data_saver_on,
            color: kGold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Data saver on",
                  style: TextStyle(
                    color: kGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "Maps off. Use city list.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Dead-button honesty: Button shows status BEFORE tap.
/// If SMS/FCM gateway unavailable, button says so.
class DeadButtonButton extends StatelessWidget {
  const DeadButtonButton({
    super.key,
    required this.label,
    required this.subLabel,
    required this.isAvailable,
    required this.onPressed,
    this.icon = Icons.send,
  });

  final String label;
  final String subLabel;
  final bool isAvailable;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: isAvailable ? onPressed : null,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: isAvailable ? kSos : Colors.grey[700],
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            disabledBackgroundColor: Colors.grey[800],
            disabledForegroundColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subLabel,
          style: TextStyle(
            color: isAvailable ? Colors.grey : kSos,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Button state indicator card.
/// Shows why button is disabled (no SMS gateway, no FCM, etc).
class ButtonStatusCard extends StatelessWidget {
  const ButtonStatusCard({
    super.key,
    required this.issues,
  });

  final List<({String title, String message})> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSos.withValues(alpha: 0.1),
        border: Border.all(color: kSos, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "These are off right now:",
            style: TextStyle(
              color: kGold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...issues.map((issue) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: kSos, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          issue.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          issue.message,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 4),
          const Text(
            "Code stays on this computer. No internet needed.",
            style: TextStyle(
              color: kGold,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-button night mode toggle for attendants.
/// 2am ward: huge type, two buttons, gold on black.
class NightModeToggle extends StatelessWidget {
  const NightModeToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
    required this.language,
  });

  final bool isActive;
  final ValueChanged<bool> onToggle;
  final String language;

  @override
  Widget build(BuildContext context) {
    final hi = language.toLowerCase().startsWith("hi");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(!isActive),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isActive
                      ? kGold.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive ? kGold : Colors.grey[700]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dark_mode,
                        color: isActive ? kGold : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hi ? "रात का मोड" : "Night mode",
                        style: TextStyle(
                          color: isActive ? kGold : Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
