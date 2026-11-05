"""Discord formatting and an explicit, bounded webhook transport."""
from dataclasses import dataclass
from datetime import datetime, timezone
import json
import math
import re
import urllib.error
import urllib.parse
import urllib.request
from .export_reader import BridgeError

CATEGORIES = frozenset(("new_wanted", "bounty_increased", "vengeance"))


def safe(value):
    # No ping parsing is allowed; escaping also keeps player names from
    # changing the message's formatting.
    return re.sub(r"([\\`*_~|<>])", r"\\\1", str(value)).replace("@", "@\u200b")


def payload(title, description, mode):
    prefix = "DÉMONSTRATION — " if mode == "demo" else ""
    content = f"**{prefix}{title}**\n{description}"
    if len(content) > 2000:
        raise BridgeError("message_limit")
    return {"username": "Le Syndicat Rouge — Tableau des primes", "content": content,
            "allowed_mentions": {"parse": []}}


def bounty_payload(enemy, incidents, mode, increased=False, reward=None):
    latest = max(incidents, key=lambda item: (item["occurredAt"], item["id"]))
    stamp = datetime.fromtimestamp(latest["occurredAt"], timezone.utc).strftime("%d/%m/%Y %H:%M UTC")
    title = "Prime augmentée" if increased else "Nouveau recherché"
    description = f"{safe(enemy['name'])} ({safe(enemy['realm'])}) — prime de recherche : {len(incidents)}.\n"
    description += f"Dernier incident : {safe(latest['victim']['name'])}, {safe(latest['location']['zone'])} · {stamp}."
    if reward is not None:
        description += f"\nRécompense actuellement disponible : +{reward} réputation."
    return payload(title, description, mode)


def vengeance_payload(claim, incidents, mode, correction=False):
    related = [incidents[key] for key in claim["incidentIds"]]
    enemy = related[0]["enemy"]
    if correction:
        return payload("Correction : vengeance contestée",
                       f"La vengeance de {safe(claim['avenger']['name'])} contre {safe(enemy['name'])} est désormais contestée.\n"
                       "La réputation correspondante est suspendue, dans l’attente d’un arbitrage.", mode)
    victims = sorted({item["victim"]["name"] for item in related})
    names = ", ".join(safe(name) for name in victims[:5])
    if len(victims) > 5:
        names += f" et {len(victims)-5} autre(s) membre(s)"
    return payload("Vengeance accomplie", f"{safe(claim['avenger']['name'])} a éliminé {safe(enemy['name'])}.\n"
                   f"Membres vengés : {names}.\n+{len(related)} réputation · {len(related)} incident(s) clôturé(s).", mode)


@dataclass(frozen=True)
class Result:
    kind: str
    code: str
    message_id: str | None = None
    delay: float = 0


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, _request, _file, _code, _message, _headers, _url):
        return None


def validate_webhook(url):
    try:
        parsed = urllib.parse.urlsplit(url)
        valid = parsed.scheme == "https" and parsed.hostname == "discord.com" and parsed.port in (None, 443)
        valid = valid and not parsed.username and not parsed.password and not parsed.query and not parsed.fragment
        valid = valid and re.fullmatch(r"/api(?:/v[0-9]+)?/webhooks/[0-9]{5,30}/[A-Za-z0-9._-]{40,200}", parsed.path)
    except (TypeError, ValueError):
        valid = False
    if not valid:
        raise BridgeError("invalid_webhook_url")
    return url


def delay(value):
    try:
        result = float(value)
        return result if math.isfinite(result) and 0 <= result <= 31_536_000 else None
    except (TypeError, ValueError):
        return None


class WebhookTransport:
    def __init__(self, url, opener=None):
        self.url = validate_webhook(url)
        self.opener = opener or urllib.request.build_opener(NoRedirect())

    def __call__(self, message):
        body = json.dumps(message, ensure_ascii=False).encode("utf-8")
        request = urllib.request.Request(self.url + "?wait=true", data=body,
                                         headers={"Content-Type": "application/json", "User-Agent": "SyndicatRougeRelay/0.3"}, method="POST")
        try:
            with self.opener.open(request, timeout=10) as response:
                status, headers, raw = response.status, response.headers, response.read(65_537)
        except urllib.error.HTTPError as error:
            status, headers, raw = error.code, error.headers, error.read(65_537)
        except (OSError, TimeoutError, urllib.error.URLError):
            return Result("uncertain", "network_uncertain")
        if len(raw) > 65_536:
            return Result("uncertain", "response_limit")
        try:
            data = json.loads(raw) if raw else {}
        except (ValueError, UnicodeError):
            data = {}
        if not isinstance(data, dict):
            data = {}
        if status == 429:
            retry = delay(headers.get("Retry-After"))
            if retry is None:
                retry = delay(data.get("retry_after"))
            return Result("retry", "rate_limited", delay=max(retry, 0.1)) if retry is not None else Result("uncertain", "rate_limit_unknown")
        if 200 <= status < 300:
            message_id = data.get("id")
            if not isinstance(message_id, str) or not re.fullmatch(r"[0-9]{1,30}", message_id):
                return Result("uncertain", "confirmation_missing")
            cooldown = delay(headers.get("X-RateLimit-Reset-After")) if headers.get("X-RateLimit-Remaining") == "0" else 0
            if cooldown is None:
                return Result("confirmed", "rate_limit_unknown", message_id)
            return Result("confirmed", "sent", message_id, delay=cooldown)
        if status >= 500:
            return Result("uncertain", "server_uncertain")
        return Result("failed", "http_rejected")
