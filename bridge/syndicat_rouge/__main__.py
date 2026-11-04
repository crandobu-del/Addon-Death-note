import argparse
import json
import os
from pathlib import Path
import re
import sqlite3
import sys
from .delivery import Queue, categories
from .discord import CATEGORIES, WebhookTransport
from .export_reader import BridgeError, read_export, strict_json, text


def configuration(path):
    if not path:
        return {"enabled": False, "categories": sorted(CATEGORIES), "webhook_env": "SYNDICAT_DISCORD_WEBHOOK", "guild_id": None}
    try:
        with Path(path).open("rb") as stream:
            raw = stream.read(16_385)
        if len(raw) > 16_384:
            raise BridgeError("config_limit")
        data = strict_json(raw.decode("utf-8"))
    except (OSError, UnicodeError):
        raise BridgeError("config_unreadable") from None
    if not isinstance(data, dict) or set(data) != {"enabled", "categories", "webhook_env", "guild_id"}:
        raise BridgeError("invalid_config")
    if type(data["enabled"]) is not bool or not isinstance(data["categories"], list):
        raise BridgeError("invalid_config")
    categories(data["categories"])
    text(data["guild_id"])
    if not isinstance(data["webhook_env"], str) or not re.fullmatch(r"[A-Z][A-Z0-9_]{0,79}", data["webhook_env"]):
        raise BridgeError("invalid_config")
    return data


def preview(data, selected=CATEGORIES):
    with Queue() as queue:
        queue.enqueue(data, selected)
        jobs = queue.status(with_payload=True)
        return {"version": 1, "mode": data["mode"], "guildName": data["guildName"], "delivery_enabled": False,
                "messages": [row for row in jobs if row["status"] == "pending"],
                "not_published": sum(row["status"] != "pending" for row in jobs)}


def main(argv=None):
    parser = argparse.ArgumentParser(description="Le Syndicat Rouge — relais Discord optionnel")
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("preview", "enqueue", "status", "send", "recover", "resolve"):
        command = commands.add_parser(name)
        if name in ("preview", "enqueue"):
            command.add_argument("export")
        command.add_argument("--config")
        if name == "preview":
            command.add_argument("--output")
        else:
            command.add_argument("--state", default="bridge/state/queue.sqlite3")
        if name == "recover":
            command.add_argument("--confirm-stopped", action="store_true")
        if name == "resolve":
            command.add_argument("event_id")
            command.add_argument("outcome", choices=("delivered", "retry", "cancel"))
            command.add_argument("--message-id")
    args = parser.parse_args(argv)
    try:
        config = configuration(args.config)
        if args.command == "preview":
            data = read_export(args.export)
            result = preview(data, config["categories"])
        else:
            with Queue(args.state) as queue:
                if args.command == "enqueue":
                    data = read_export(args.export)
                    if not config["guild_id"] or config["guild_id"] != data["guildId"]:
                        raise BridgeError("configured_guild_mismatch")
                    result = queue.enqueue(data, config["categories"])
                elif args.command == "send":
                    if config["enabled"] is not True:
                        raise BridgeError("relay_disabled")
                    if queue.meta("guildId") != config["guild_id"]:
                        raise BridgeError("configured_guild_mismatch")
                    if queue.meta("mode") != "live":
                        raise BridgeError("demo_sending_forbidden")
                    url = os.environ.get(config["webhook_env"])
                    if not url:
                        raise BridgeError("webhook_not_configured")
                    result = queue.dispatch(WebhookTransport(url), enabled=True, selected=config["categories"])
                elif args.command == "recover":
                    if not args.confirm_stopped:
                        raise BridgeError("recovery_confirmation_required")
                    result = {"uncertain": queue.recover()}
                elif args.command == "resolve":
                    queue.resolve(args.event_id, args.outcome, args.message_id)
                    result = {"resolved": args.event_id}
                else:
                    result = {"active_sender": bool(queue.meta("active_sender", "")), "mode": queue.meta("mode"),
                              "rate_limit_paused": bool(queue.meta("rate_limit_paused", "")),
                              "next_allowed_at": float(queue.meta("next_allowed_at", 0)), "jobs": queue.status()}
        rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
        if getattr(args, "output", None):
            Path(args.output).write_text(rendered, encoding="utf-8")
        else:
            print(rendered)
        return 0
    except BridgeError as error:
        print(json.dumps({"error": str(error)}), file=sys.stderr)
        return 2
    except (OSError, sqlite3.Error):
        print('{"error":"local_state_unavailable"}', file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
