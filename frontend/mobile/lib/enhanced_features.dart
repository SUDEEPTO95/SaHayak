/// Enhanced visual components for calm, dignified blood request experience.
/// Bag progress, surgeon waiting pulse, walk directions, holds, night mode.
library;

import "package:flutter/material.dart";

const Color kSos = Color(0xFFC42B4A);
const Color kTrust = Color(0xFF1AA58A);
const Color kGold = Color(0xFFE8C07A);
const Color kInk = Color(0xFF0C0610);

// Bag progress: empty → promised → in
enum BagStatus { empty, promised, done }

BagStatus bagStatusFromString(String? status) {
  return switch (status) {
    "in" => BagStatus.done,
    "promised" => BagStatus.promised,
    _ => BagStatus.empty,
  };
}

/// Visual representation of blood bag units needed and received.
/// Shows filled vs empty bags instead of just numbers.
class BagProgressVisual extends StatelessWidget {
  const BagProgressVisual({
    super.key,
    required this.total,
    required this.accepted,
    required this.remaining,
  });

  final int total;
  final int accepted;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final bags = <Widget>[];
    
    // Create bag icons based on progress
    for (int i = 0; i < total; i++) {
      if (i < accepted) {
        // In: filled red bag
        bags.add(
          Tooltip(
            message: "Unit ${ i + 1} accepted",
            child: Icon(Icons.water_drop, color: kSos, size: 28),
          ),
        );
      } else if (i < accepted + (total - accepted - remaining)) {
        // Promised: half-filled yellow bag
        bags.add(
          Tooltip(
            message: "Unit ${i + 1} promised",
            child: Icon(Icons.water_drop_outlined, color: kGold, size: 28),
          ),
        );
      } else {
        // Empty: outline bag
        bags.add(
          Tooltip(
            message: "Unit ${i + 1} needed",
            child: Icon(Icons.water_drop_outlined, color: Colors.grey, size: 28),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: bags,
        ),
        const SizedBox(height: 8),
        Text(
          "$accepted/$total units",
          style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Pulsing animation for "surgeon still waiting" state.
/// Shows when request is open and units still needed.
class SurgeonWaitingPulse extends StatefulWidget {
  const SurgeonWaitingPulse({
    super.key,
    required this.unitsNeeded,
    required this.isActive,
  });

  final int unitsNeeded;
  final bool isActive;

  @override
  State<SurgeonWaitingPulse> createState() => _SurgeonWaitingPulseState();
}

class _SurgeonWaitingPulseState extends State<SurgeonWaitingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SurgeonWaitingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.2),
              border: Border.all(color: kGold, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, color: kGold, size: 18),
                const SizedBox(width: 6),
                Text(
                  "Surgeon waiting • ${widget.unitsNeeded} more",
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Structured walk-to-door directions instead of plain text.
/// Emphasizes: hospital · ward · blood bank door — not bedside.
class WalkToDoorCard extends StatelessWidget {
  const WalkToDoorCard({
    super.key,
    required this.hospital,
    required this.ward,
    required this.language,
  });

  final String hospital;
  final String ward;
  final String language;

  @override
  Widget build(BuildContext context) {
    final hi = language.toLowerCase().startsWith("hi");
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A14),
        border: Border.all(color: kTrust, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: kTrust, size: 20),
              const SizedBox(width: 8),
              Text(
                hi ? "इसी जगह जाइए" : "Go to this place",
                style: const TextStyle(
                  color: kTrust,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hospital name (large)
          Text(
            hospital,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Ward info
          Row(
            children: [
              Text(
                hi ? "वार्ड " : "Ward ",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                ward,
                style: const TextStyle(
                  color: kGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Blood bank door emphasis
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kTrust.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hi
                  ? "ब्लड बैंक का दरवाज़ा — बिस्तर पर नहीं"
                  : "Blood bank door — not the bedside",
              style: const TextStyle(
                color: kTrust,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Phone rule
          Row(
            children: [
              Icon(Icons.phone, color: kGold, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hi ? "फोन स्वीकार के बाद ही" : "Phone only after you accepted",
                  style: const TextStyle(color: kGold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gold ring indicator for fasting or fever hold.
/// Shows around donor's name or avatar.
class DonorHoldRing extends StatelessWidget {
  const DonorHoldRing({
    super.key,
    required this.reason,
    required this.child,
  });

  final String? reason; // "fasting", "fever", null
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reason == null) {
      return child;
    }

    final tooltip = switch (reason) {
      "fasting" => "Today I rest — fasting",
      "fever" => "Today I rest — fever",
      _ => "Today I rest",
    };

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: kGold,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: kGold.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// "Still need" visual for family guest link.
/// Replaces "1 unit promised" with visual indicator.
class StillNeedBadge extends StatelessWidget {
  const StillNeedBadge({
    super.key,
    required this.count,
    required this.language,
  });

  final int count;
  final String language;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final hi = language.toLowerCase().startsWith("hi");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kSos.withValues(alpha: 0.2),
        border: Border.all(color: kSos, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: kSos, size: 14),
          const SizedBox(width: 4),
          Text(
            hi
                ? "अभी $count चाहिए"
                : "Still need $count",
            style: const TextStyle(
              color: kSos,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Women-first indicator badge.
/// Shows when women donors are being pinged first.
class WomenFirstIndicator extends StatelessWidget {
  const WomenFirstIndicator({
    super.key,
    required this.isActive,
    required this.language,
  });

  final bool isActive;
  final String language;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    final hi = language.toLowerCase().startsWith("hi");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kTrust.withValues(alpha: 0.2),
        border: Border.all(color: kTrust, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, color: kTrust, size: 12),
          const SizedBox(width: 4),
          Text(
            hi ? "महिला पहले" : "Women first",
            style: const TextStyle(
              color: kTrust,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-attendant merge notification.
/// Shows when two phones requested same bed (pride moment).
class TwoAttendantMergeNotice extends StatelessWidget {
  const TwoAttendantMergeNotice({
    super.key,
    required this.language,
  });

  final String language;

  @override
  Widget build(BuildContext context) {
    final hi = language.toLowerCase().startsWith("hi");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kGold.withValues(alpha: 0.1),
        border: Border.all(color: kGold, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: kGold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hi
                  ? "दो फोन से एक ही आपात। दोबारा पिंग नहीं। गर्व की बात!"
                  : "Same emergency confirmed from two phones. We did not double-ping. Pride moment.",
              style: const TextStyle(
                color: kGold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
