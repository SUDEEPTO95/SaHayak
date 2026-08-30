"""Validation helpers for new feature endpoints."""
from __future__ import annotations

from typing import Any


def validate_donor_hold(body: dict[str, Any]) -> tuple[bool, str | None]:
    """
    Validate fasting/fever hold request.
    Returns (is_valid, error_code)
    """
    fasting = body.get("fasting", False)
    fever = body.get("fever", False)
    
    # Both cannot be true simultaneously
    if fasting and fever:
        return False, "cannot_hold_both"
    
    # At least one should be set if turning on hold
    if not (fasting or fever) and body.get("clear") is not True:
        return False, "hold_needs_reason"
    
    return True, None


def validate_night_mode(body: dict[str, Any]) -> tuple[bool, str | None]:
    """
    Validate night mode toggle.
    Returns (is_valid, error_code)
    """
    on = body.get("on")
    
    if on is None:
        return False, "missing_on_flag"
    
    if not isinstance(on, bool):
        return False, "on_must_be_bool"
    
    return True, None


def validate_language_code(lang: str | None) -> bool:
    """Validate language code (en, hi, etc.)."""
    if not lang:
        return True  # Optional, defaults to en
    return lang.lower() in ("en", "hi", "mr", "bn", "ta", "te", "kn", "ml")


def validate_donor_profile_extended(profile: dict[str, Any]) -> tuple[bool, str | None]:
    """
    Validate extended donor profile fields.
    Returns (is_valid, error_code)
    """
    # Validate fasting/fever holds
    fasting = profile.get("fasting_hold", False)
    fever = profile.get("fever_hold", False)
    if fasting and fever:
        return False, "cannot_hold_both"
    
    # Validate language
    if "language" in profile:
        if not validate_language_code(profile.get("language")):
            return False, "invalid_language"
    
    # Validate woman flag
    if "woman" in profile:
        if not isinstance(profile.get("woman"), bool):
            return False, "woman_must_be_bool"
    
    # Validate lat/lng if provided
    if "lat" in profile or "lng" in profile:
        try:
            lat = float(profile.get("lat", 0))
            lng = float(profile.get("lng", 0))
            if not (-90 <= lat <= 90 and -180 <= lng <= 180):
                return False, "invalid_coordinates"
        except (TypeError, ValueError):
            return False, "coordinates_not_numeric"
    
    return True, None


def validate_blood_request_enhanced(body: dict[str, Any]) -> tuple[bool, str | None]:
    """
    Validate enhanced blood request fields.
    Returns (is_valid, error_code)
    """
    # Validate language
    if "language" in body:
        if not validate_language_code(body.get("language")):
            return False, "invalid_language"
    
    # Validate women_first flag
    if "women_first" in body:
        if not isinstance(body.get("women_first"), bool):
            return False, "women_first_must_be_bool"
    
    # Validate urgency
    urgency = body.get("urgency", "critical")
    if urgency not in ("critical", "scheduled"):
        return False, "invalid_urgency"
    
    # Validate lane
    lane = body.get("lane", "sos")
    if lane not in ("sos", "regular"):
        return False, "invalid_lane"
    
    return True, None


def get_error_http_status(error_code: str) -> int:
    """Map error codes to HTTP status codes."""
    error_status_map = {
        "missing_on_flag": 400,
        "on_must_be_bool": 400,
        "cannot_hold_both": 400,
        "hold_needs_reason": 400,
        "invalid_language": 400,
        "woman_must_be_bool": 400,
        "invalid_coordinates": 400,
        "coordinates_not_numeric": 400,
        "invalid_urgency": 400,
        "invalid_lane": 400,
        "women_first_must_be_bool": 400,
        "not_a_donor": 404,
        "hold_active": 409,
    }
    return error_status_map.get(error_code, 400)
