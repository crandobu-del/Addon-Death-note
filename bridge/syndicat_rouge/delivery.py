"""Persistent, single-sender queue. Uncertain outcomes are never auto-retried."""
from collections import defaultdict
from contextlib import contextmanager
import hashlib
import json
from pathlib import Path
import sqlite3
import time
import uuid
from .discord import CATEGORIES, Result, bounty_payload, vengeance_payload
from .export_reader import BridgeError, validate_export


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def event_id(kind, identity):
    return kind + ":" + hashlib.sha256(canonical(identity).encode("utf-8")).hexdigest()


def categories(values):
    if not isinstance(values, (list, tuple, set, frozenset)) or any(not isinstance(value, str) for value in values):
        raise BridgeError("unknown_category")
    result = frozenset(values)
    if result - CATEGORIES:
        raise BridgeError("unknown_category")
    return result


class Queue:
    def __init__(self, path=":memory:", clock=time.time):
        self.clock = clock
        if str(path) != ":memory:":
            Path(path).parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(str(path), isolation_level=None, timeout=1)
        self.db.row_factory = sqlite3.Row
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS facts (
                kind TEXT NOT NULL, id TEXT NOT NULL, body TEXT NOT NULL, PRIMARY KEY(kind,id));
            CREATE TABLE IF NOT EXISTS jobs (
                sequence INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT UNIQUE NOT NULL,
                category TEXT NOT NULL, entity TEXT NOT NULL, payload TEXT NOT NULL,
                status TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0,
                next_at REAL NOT NULL DEFAULT 0, message_id TEXT, code TEXT,
                obsolete INTEGER NOT NULL DEFAULT 0);
        """)

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        self.db.close()

    @contextmanager
    def transaction(self):
        self.db.execute("BEGIN IMMEDIATE")
        try:
            yield
        except BaseException:
            self.db.execute("ROLLBACK")
            raise
        else:
            self.db.execute("COMMIT")

    def meta(self, key, default=None):
        row = self.db.execute("SELECT value FROM meta WHERE key=?", (key,)).fetchone()
        return row[0] if row else default

    def set_meta(self, key, value):
        self.db.execute("INSERT INTO meta VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", (key, str(value)))

    def idle(self):
        if self.meta("active_sender", ""):
            raise BridgeError("queue_busy")

    def facts(self, kind):
        return {row["id"]: json.loads(row["body"]) for row in self.db.execute("SELECT id,body FROM facts WHERE kind=?", (kind,))}

    def job(self, identity):
        return self.db.execute("SELECT * FROM jobs WHERE id=?", (identity,)).fetchone()

    def schedule(self, identity, category, entity, message, selected, held=False):
        status = "held" if held else ("pending" if category in selected or category == "correction" else "skipped")
        self.db.execute("INSERT OR IGNORE INTO jobs(id,category,entity,payload,status) VALUES (?,?,?,?,?)",
                        (identity, category, entity, canonical(message), status))

    def enqueue(self, raw_export, selected=CATEGORIES):
        data = validate_export(raw_export)
        selected = categories(selected)
        with self.transaction():
            self.idle()
            for key in ("guildId", "guildName", "mode"):
                if self.meta(key) is not None and self.meta(key) != data[key]:
                    raise BridgeError("queue_identity_mismatch")
                self.set_meta(key, data[key])
            previous = self.facts("incident")
            added = []
            for kind, source in (("incident", data["incidents"]), ("claim", data["claims"])):
                for row in source:
                    body = canonical(row)
                    old = self.db.execute("SELECT body FROM facts WHERE kind=? AND id=?", (kind, row["id"])).fetchone()
                    if old and old[0] != body:
                        raise BridgeError("fact_id_conflict")
                    if not old:
                        self.db.execute("INSERT INTO facts VALUES (?,?,?)", (kind, row["id"], body))
                        if kind == "incident":
                            added.append(row)
            if self.db.execute("SELECT COUNT(*) FROM facts").fetchone()[0] > 5000:
                raise BridgeError("queue_capacity")
            all_incidents = self.facts("incident")
            by_enemy = defaultdict(list)
            for row in all_incidents.values():
                by_enemy[row["enemy"]["id"]].append(row)
            known_enemies = {row["enemy"]["id"] for row in previous.values()}
            for enemy_id in sorted({row["enemy"]["id"] for row in added}):
                related = by_enemy[enemy_id]
                newest = max(related, key=lambda row: (row["occurredAt"], row["id"]))
                wanted_id = event_id("wanted", enemy_id)
                wanted_job = self.job(wanted_id)
                message = bounty_payload(newest["enemy"], related, data["mode"])
                if enemy_id not in known_enemies:
                    self.schedule(wanted_id, "new_wanted", enemy_id, message, selected)
                elif wanted_job and wanted_job["status"] == "pending":
                    self.db.execute("UPDATE jobs SET payload=?,status=? WHERE id=?",
                                    (canonical(message), "pending" if "new_wanted" in selected else "skipped", wanted_id))
                else:
                    self.db.execute("UPDATE jobs SET status='cancelled',code='coalesced' WHERE entity=? AND category='bounty_increased' AND status='pending'", (enemy_id,))
                    identity = event_id("bounty", [enemy_id, sorted(row["id"] for row in related)])
                    self.schedule(identity, "bounty_increased", enemy_id, bounty_payload(newest["enemy"], related, data["mode"], True), selected)
            claims = self.facts("claim")
            owners = defaultdict(set)
            for claim in claims.values():
                for incident_id in claim["incidentIds"]:
                    owners[incident_id].add(claim["id"])
            conflicted = {identity for values in owners.values() if len(values) > 1 for identity in values}
            for identity, claim in sorted(claims.items()):
                job_id = event_id("vengeance", identity)
                old = self.job(job_id)
                if identity not in conflicted:
                    self.schedule(job_id, "vengeance", identity, vengeance_payload(claim, all_incidents, data["mode"]), selected)
                    continue
                if not old:
                    continue
                self.db.execute("UPDATE jobs SET obsolete=1 WHERE id=?", (job_id,))
                if old["status"] in ("pending", "held"):
                    self.db.execute("UPDATE jobs SET status='cancelled',code='disputed' WHERE id=?", (job_id,))
                if old["status"] in ("sent", "uncertain", "sending"):
                    correction_id = event_id("correction", identity)
                    self.schedule(correction_id, "correction", identity, vengeance_payload(claim, all_incidents, data["mode"], True), selected,
                                  held=old["status"] != "sent")
            claimed_ids = {key for claim in claims.values() for key in claim["incidentIds"]}
            for row in self.db.execute("SELECT id,category,entity FROM jobs WHERE status='pending' AND category IN ('new_wanted','bounty_increased')").fetchall():
                related = by_enemy[row["entity"]]
                available = sum(item["id"] not in claimed_ids for item in related)
                if not available:
                    self.db.execute("UPDATE jobs SET status='cancelled',code='target_inactive' WHERE id=?", (row["id"],))
                else:
                    newest = max(related, key=lambda item: (item["occurredAt"], item["id"]))
                    message = bounty_payload(newest["enemy"], related, data["mode"], row["category"] == "bounty_increased", available)
                    self.db.execute("UPDATE jobs SET payload=? WHERE id=?", (canonical(message), row["id"]))
            self.set_meta("categories", canonical(sorted(selected)))
        return self.status()

    def status(self, with_payload=False):
        output = []
        for row in self.db.execute("SELECT * FROM jobs ORDER BY sequence"):
            item = {key: row[key] for key in ("id", "category", "status", "attempts", "next_at", "message_id", "code")}
            if with_payload:
                item["payload"] = json.loads(row["payload"])
            output.append(item)
        return output

    def dispatch(self, transport, *, enabled=False, selected=CATEGORIES, limit=25):
        if enabled is not True:
            raise BridgeError("relay_disabled")
        selected = categories(selected)
        token = uuid.uuid4().hex
        with self.transaction():
            self.idle()
            if self.meta("mode") != "live":
                raise BridgeError("demo_sending_forbidden")
            if self.db.execute("SELECT 1 FROM jobs WHERE status='uncertain' LIMIT 1").fetchone():
                raise BridgeError("uncertain_jobs")
            if self.meta("rate_limit_paused", ""):
                raise BridgeError("rate_limit_unknown")
            self.set_meta("active_sender", token)
        outcomes = []
        try:
            for _ in range(limit):
                with self.transaction():
                    if self.meta("active_sender") != token:
                        raise BridgeError("sender_lease_lost")
                    now = self.clock()
                    if float(self.meta("next_allowed_at", 0)) > now:
                        break
                    row = self.db.execute("SELECT * FROM jobs WHERE status='pending' AND next_at<=? ORDER BY sequence LIMIT 1", (now,)).fetchone()
                    if not row:
                        break
                    if row["category"] not in selected and row["category"] != "correction":
                        self.db.execute("UPDATE jobs SET status='skipped',code='category_disabled' WHERE id=?", (row["id"],))
                        continue
                    self.db.execute("UPDATE jobs SET status='sending',attempts=attempts+1 WHERE id=?", (row["id"],))
                try:
                    result = transport(json.loads(row["payload"]))
                    if not isinstance(result, Result) or result.kind not in ("confirmed", "retry", "failed", "uncertain"):
                        result = Result("uncertain", "transport_uncertain")
                except Exception:
                    result = Result("uncertain", "transport_uncertain")
                with self.transaction():
                    if self.meta("active_sender") != token:
                        raise BridgeError("sender_lease_lost")
                    status = {"confirmed": "sent", "retry": "pending", "failed": "failed", "uncertain": "uncertain"}[result.kind]
                    next_at = self.clock() + result.delay
                    self.db.execute("UPDATE jobs SET status=?,code=?,message_id=?,next_at=? WHERE id=?",
                                    (status, result.code, result.message_id, next_at, row["id"]))
                    if result.delay:
                        self.set_meta("next_allowed_at", next_at)
                    if result.code == "rate_limit_unknown":
                        self.set_meta("rate_limit_paused", "1")
                    outcomes.append({"id": row["id"], "status": status, "code": result.code})
                if result.kind != "confirmed" or result.code == "rate_limit_unknown":
                    break
        finally:
            with self.transaction():
                if self.meta("active_sender") == token:
                    self.db.execute("UPDATE jobs SET status='uncertain',code='interrupted' WHERE status='sending'")
                    self.set_meta("active_sender", "")
        return outcomes

    def recover(self):
        # Explicit operator action after ensuring no sender process is running.
        with self.transaction():
            count = self.db.execute("UPDATE jobs SET status='uncertain',code='interrupted' WHERE status='sending'").rowcount
            self.set_meta("active_sender", "")
            self.set_meta("rate_limit_paused", "")
        return count

    def resolve(self, identity, outcome, message_id=None):
        if outcome not in ("delivered", "retry", "cancel"):
            raise BridgeError("invalid_resolution")
        with self.transaction():
            self.idle()
            row = self.job(identity)
            if not row or row["status"] != "uncertain":
                raise BridgeError("job_not_uncertain")
            if outcome == "retry" and row["obsolete"]:
                raise BridgeError("obsolete_retry_forbidden")
            if outcome == "delivered" and (not isinstance(message_id, str) or not message_id.isascii() or not message_id.isdigit() or len(message_id) > 30):
                raise BridgeError("message_id_required")
            status = {"delivered": "sent", "retry": "pending", "cancel": "cancelled"}[outcome]
            self.db.execute("UPDATE jobs SET status=?,message_id=?,code='operator_resolved',next_at=0 WHERE id=?", (status, message_id, identity))
            if row["category"] == "vengeance":
                correction = event_id("correction", row["entity"])
                self.db.execute("UPDATE jobs SET status=? WHERE id=? AND status='held'",
                                ("pending" if outcome == "delivered" else "cancelled", correction))
