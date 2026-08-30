"""Enhanced features for calm, dignified blood request experience.

Implements: bag progress visual, surgeon waiting pulse, walk directions,
fasting/fever holds, language bridge, night mode, heatmap visualization.
"""
from __future__ import annotations

import time
from typing import Any, Literal

# Bag status tracking
BAG_STATUS_TYPES = Literal["empty", "promised", "in"]


def calculate_bag_status(rec: dict[str, Any]) -> BAG_STATUS_TYPES:
    """Calculate visual bag status: empty → promised → in."""
    units_needed = int(rec.get("units_needed") or 0)
    units_accepted = int(rec.get("units_accepted") or 0)
    
    if units_needed <= 0:
        return "empty"
    if units_accepted >= units_needed:
        return "in"
    if units_accepted > 0:
        return "promised"
    return "empty"


def surgeon_still_waiting(rec: dict[str, Any]) -> bool:
    """Check if this request should pulse (surgeon waiting for more units)."""
    if rec.get("status") != "open":
        return False
    units_needed = int(rec.get("units_needed") or 0)
    units_accepted = int(rec.get("units_accepted") or 0)
    return units_accepted > 0 and units_accepted < units_needed


def two_attendant_merge_flag(rec: dict[str, Any]) -> bool:
    """Check if this is a merge from two attendants requesting same bed."""
    # Flag set during merge_twins step in orchestration
    return rec.get("merged_from_two_phones", False)


def donor_self_hold_reason(donor: dict[str, Any]) -> str | None:
    """Return reason for donor self-hold, or None if not holding."""
    if donor.get("fasting_hold"):
        return "fasting"
    if donor.get("fever_hold"):
        return "fever"
    if donor.get("self_hold"):
        return "general"
    return None


def should_use_night_mode(user: dict[str, Any], current_hour: int | None = None) -> bool:
    """Check if night mode should be active for this user."""
    if current_hour is None:
        current_hour = int(time.time() // 3600) % 24
    
    # User explicitly enabled night mode
    if user.get("night_mode"):
        return True
    
    # Hindi + late night (22:00 - 06:00) = auto night mode
    if user.get("language", "en").lower().startswith("hi"):
        return current_hour >= 22 or current_hour < 6
    
    return False


def language_preference_for_donor(donor: dict[str, Any]) -> str:
    """Get the language this donor should see content in."""
    return (donor.get("language") or "en").lower()


def low_battery_strip_active(battery_percent: int | None) -> bool:
    """Check if low-battery warning strip should show."""
    if battery_percent is None:
        return False
    return battery_percent < 20


def data_saver_strip_active(data_saver_mode: bool | None) -> bool:
    """Check if data-saver warning strip should show."""
    return bool(data_saver_mode)


def dead_button_status(
    otp_gateway_enabled: bool,
    fcm_enabled: bool,
    sms_provider_available: bool,
) -> dict[str, Any] | None:
    """Return button status warning if any channel is unavailable."""
    if not otp_gateway_enabled and not sms_provider_available:
        return {
            "code": "no_otp_gateway",
            "message": "Code stays on this computer",
            "sub": "SMS gateway not available",
        }
    if not fcm_enabled:
        return {
            "code": "no_fcm",
            "message": "Message stays on this phone",
            "sub": "Push notifications not available",
        }
    return None


def bag_progress_visual(rec: dict[str, Any]) -> dict[str, Any]:
    """Return visual representation of bag progress."""
    units_needed = int(rec.get("units_needed") or 0)
    units_accepted = int(rec.get("units_accepted") or 0)
    
    bags = []
    for i in range(units_needed):
        if i < units_accepted:
            bags.append("in")  # 🔴 already accepted
        else:
            # Check if promised (in matching/escalation)
            bags.append("empty")  # ⚪ still needed
    
    return {
        "total": units_needed,
        "accepted": units_accepted,
        "remaining": max(0, units_needed - units_accepted),
        "bags": bags,  # List of "in", "promised", "empty"
        "status": calculate_bag_status(rec),
    }


def walk_to_door_visual(rec: dict[str, Any], language: str = "en") -> dict[str, Any]:
    """Return structured walk-to-door directions (not just text)."""
    hosp = rec.get("hospital_name") or "hospital"
    ward = rec.get("ward") or "—"
    
    hi = language.lower().startswith("hi")
    
    return {
        "hospital": hosp,
        "ward": ward,
        "destination": "blood_bank_door" if not hi else "ब्लड_बैंक_का_दरवाज़ा",
        "avoid": "bedside" if not hi else "बिस्तर",
        "phone_timing": "after_accept" if not hi else "स्वीकार_के_बाद",
        "emphasis_line": f"{hosp} · Ward {ward} · blood bank door — not bedside" if not hi else f"{hosp} · वार्ड {ward} · ब्लड बैंक का दरवाज़ा — बिस्तर पर नहीं",
        "phone_rule": "Phone only after you accepted" if not hi else "फोन स्वीकार के बाद ही",
    }


def heatmap_point(req: dict[str, Any]) -> dict[str, Any]:
    """Convert request to heatmap point (no names, just location + intensity)."""
    if req.get("status") != "open":
        return {}
    
    units_needed = int(req.get("units_needed") or 1)
    units_accepted = int(req.get("units_accepted") or 0)
    
    # Intensity: higher = more urgent
    # Critical + no accepts yet = highest
    urgency = 100 if req.get("urgency") == "critical" else 60
    fulfillment = max(0, 100 - (units_accepted / units_needed * 100)) if units_needed else 100
    intensity = (urgency + fulfillment) / 2
    
    return {
        "lat": float(req.get("lat") or 0),
        "lng": float(req.get("lng") or 0),
        "intensity": intensity,  # 0-100, for color gradient
        "units_needed": units_needed,
        "units_accepted": units_accepted,
    }


def two_phone_merge_message(language: str = "en") -> str:
    """Message when two attendants requested the same bed."""
    hi = language.lower().startswith("hi")
    if hi:
        return "यही आपात पहले से खुली है। दूसरी पोस्ट नहीं बनाई। एक ही रिक्वेस्ट, दो फोन।"
    return "Same emergency. One request. Two phones confirmed it. We did not double-ping. Pride moment."


def feature_capability_check(features: dict[str, bool]) -> dict[str, bool]:
    """Return which UI features should be active on client."""
    return {
        "bag_progress_visual": features.get("bag_progress_visual_enabled", False),
        "surgeon_waiting_pulse": features.get("surgeon_waiting_pulse_enabled", False),
        "low_battery_strip": features.get("low_battery_strip_enabled", False),
        "hindi_night_mode": features.get("hindi_night_mode_enabled", False),
        "dead_button_honesty": features.get("dead_button_honesty_enabled", False),
        "walk_door_visual": True,  # Always on if backend supports
        "fasting_fever_ring": True,  # Always on if donor supports
        "language_bridge": features.get("language_bridge_enabled", False),
        "heatmap_visualization": features.get("heatmap_visualization_enabled", False),
        "two_attendant_merge": features.get("two_attendant_lock_enabled", False),
    }
