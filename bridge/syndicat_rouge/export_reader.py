"""Strict JSON import, never a Lua/SavedVariables interpreter."""
import json
import math
from pathlib import Path

MAX_BYTES = 1_048_576
MAX_RECORDS = 128


class BridgeError(ValueError):
    """Public diagnostics are fixed codes and never include credentials."""


def text(value, limit=120):
    if not isinstance(value, str) or not value or any(ord(c) < 32 or ord(c) == 127 or 0xD800 <= ord(c) <= 0xDFFF for c in value):
        raise BridgeError("invalid_text")
    if len(value.encode("utf-8")) > limit:
        raise BridgeError("text_limit")
    return value


def integer(value, minimum=0, maximum=9_007_199_254_740_991):
    if type(value) is not int or not minimum <= value <= maximum:
        raise BridgeError("invalid_integer")
    return value


def fields(value, required, optional=()):
    if not isinstance(value, dict) or not set(required) <= value.keys() or value.keys() - set(required) - set(optional):
        raise BridgeError("invalid_fields")


def actor(value):
    fields(value, ("id", "name", "realm"), ("race", "class", "level", "raceID", "classID", "sex"))
    result = {"id": text(value["id"]), "name": text(value["name"], 80), "realm": text(value["realm"], 80)}
    for key in ("race", "class"):
        if key in value:
            result[key] = text(value[key], 40)
    if "level" in value:
        result["level"] = integer(value["level"], 1, 100)
    for key in ("raceID", "classID"):
        if key in value:
            result[key] = integer(value[key], 1, 1000)
    if "sex" in value:
        if value["sex"] not in ("male", "female"):
            raise BridgeError("invalid_actor_sex")
        result["sex"] = value["sex"]
    return result


def location(value):
    fields(value, ("zone",), ("mapId", "x", "y"))
    result = {"zone": text(value["zone"], 160)}
    if "mapId" in value:
        result["mapId"] = integer(value["mapId"], 1)
    if ("x" in value) != ("y" in value):
        raise BridgeError("invalid_coordinates")
    if "x" in value:
        if "mapId" not in value:
            raise BridgeError("invalid_coordinates")
        for key in ("x", "y"):
            number = value[key]
            if type(number) not in (int, float) or not math.isfinite(number) or not 0 <= number <= 1:
                raise BridgeError("invalid_coordinates")
            result[key] = number
    return result


def array(value):
    if not isinstance(value, list) or len(value) > MAX_RECORDS:
        raise BridgeError("record_limit")
    return value


def validate_export(data):
    fields(data, ("version", "target", "mode", "guildId", "guildName", "incidents", "claims"))
    if type(data["version"]) is not int or data["version"] != 1 or data["target"] != "forever":
        raise BridgeError("unsupported_export")
    if data["mode"] not in ("demo", "live"):
        raise BridgeError("invalid_mode")
    result = {"version": 1, "target": "forever", "mode": data["mode"], "guildId": text(data["guildId"]),
              "guildName": text(data["guildName"], 80), "incidents": [], "claims": []}
    known = {}
    for row in array(data["incidents"]):
        fields(row, ("id", "guildId", "enemy", "victim", "occurredAt", "location", "source"))
        item = {"id": text(row["id"]), "guildId": text(row["guildId"]), "enemy": actor(row["enemy"]),
                "victim": actor(row["victim"]), "occurredAt": integer(row["occurredAt"], 0, 4_102_444_799),
                "location": location(row["location"]), "source": row["source"]}
        if item["guildId"] != result["guildId"] or item["enemy"]["id"] == item["victim"]["id"]:
            raise BridgeError("invalid_incident")
        if item["source"] not in ("demo", "manual", "observed"):
            raise BridgeError("invalid_source")
        if result["mode"] == "live" and item["source"] == "demo":
            raise BridgeError("demo_fact_in_live_export")
        if item["id"] in known:
            raise BridgeError("duplicate_incident_id")
        known[item["id"]] = item
        result["incidents"].append(item)
    seen = set()
    for row in array(data["claims"]):
        fields(row, ("id", "guildId", "enemyId", "avenger", "occurredAt", "incidentIds"))
        ids = [text(value) for value in array(row["incidentIds"])]
        item = {"id": text(row["id"]), "guildId": text(row["guildId"]), "enemyId": text(row["enemyId"]),
                "avenger": actor(row["avenger"]), "occurredAt": integer(row["occurredAt"], 0, 4_102_444_799), "incidentIds": sorted(ids)}
        if not ids or len(ids) != len(set(ids)) or item["guildId"] != result["guildId"]:
            raise BridgeError("invalid_claim")
        if item["avenger"]["id"] == item["enemyId"] or item["id"] in seen:
            raise BridgeError("invalid_claim")
        for incident_id in ids:
            incident = known.get(incident_id)
            if not incident or incident["enemy"]["id"] != item["enemyId"] or incident["occurredAt"] > item["occurredAt"]:
                raise BridgeError("invalid_claim_reference")
        seen.add(item["id"])
        result["claims"].append(item)
    result["incidents"].sort(key=lambda row: row["id"])
    result["claims"].sort(key=lambda row: row["id"])
    return result


def strict_json(raw):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise BridgeError("duplicate_json_key")
            result[key] = value
        return result

    def constant(_value):
        raise BridgeError("invalid_json_number")

    try:
        return json.loads(raw, object_pairs_hook=pairs, parse_constant=constant)
    except (ValueError, RecursionError) as error:
        if isinstance(error, BridgeError):
            raise
        raise BridgeError("invalid_json") from None


def read_export(path):
    try:
        with Path(path).open("rb") as stream:
            raw = stream.read(MAX_BYTES + 1)
        if len(raw) > MAX_BYTES:
            raise BridgeError("file_limit")
        return validate_export(strict_json(raw.decode("utf-8")))
    except (OSError, UnicodeError):
        raise BridgeError("export_unreadable") from None
