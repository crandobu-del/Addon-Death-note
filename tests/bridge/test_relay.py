import contextlib
import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
import urllib.error

from bridge.syndicat_rouge.__main__ import main, preview, configuration
from bridge.syndicat_rouge.delivery import Queue, event_id
from bridge.syndicat_rouge.discord import CATEGORIES, NoRedirect, Result, WebhookTransport, validate_webhook
from bridge.syndicat_rouge.export_reader import BridgeError, read_export, strict_json, validate_export

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/discord-export-demo.json"
URL = "https://discord.com/api/webhooks/123456/" + "x" * 60


def actor(identity):
    return {"id": identity, "name": identity, "realm": "Forever"}


def incident(identity="i"):
    return {"id": identity, "guildId": "guild", "enemy": actor("enemy"), "victim": actor("lyra"),
            "occurredAt": 100, "source": "observed", "location": {"zone": "Strangleronce"}}


def claim(identity="v", avenger="kaelan"):
    return {"id": identity, "guildId": "guild", "enemyId": "enemy", "avenger": actor(avenger),
            "occurredAt": 200, "incidentIds": ["i"]}


def export(incidents=None, claims=None, mode="live"):
    return {"version": 1, "target": "forever", "mode": mode, "guildId": "guild", "guildName": "Le Syndicat Rouge",
            "incidents": incidents if incidents is not None else [incident()], "claims": claims or []}


def confirmed(_message):
    return Result("confirmed", "sent", "123456789")


class Response(io.BytesIO):
    def __init__(self, status, data, headers=None):
        super().__init__(json.dumps(data).encode())
        self.status = status
        self.headers = headers or {}


class Opener:
    def __init__(self, status=200, data=None, headers=None, error=None):
        self.status, self.data, self.headers, self.error = status, data or {}, headers or {}, error
        self.requests = []

    def open(self, request, timeout):
        self.requests.append(request)
        if self.error:
            raise self.error
        return Response(self.status, self.data, self.headers)


class ReaderTests(unittest.TestCase):
    def test_actual_lua_export_is_valid_and_demo(self):
        data = read_export(FIXTURE)
        self.assertEqual(data["mode"], "demo")
        self.assertEqual(len(data["incidents"]), 8)
        self.assertEqual(len(data["claims"]), 3)
        self.assertNotIn("notificationState", data)

    def test_unknown_fields_versions_targets_and_bad_numbers(self):
        for key, value in (("version", 999), ("version", True), ("target", "retail"), ("mode", "unknown")):
            data = export(); data[key] = value
            with self.assertRaises(BridgeError): validate_export(data)
        data = export(); data["preferences"] = {"secret": "not-an-export"}
        with self.assertRaises(BridgeError): validate_export(data)
        for timestamp in (True, -1, 9_007_199_254_740_991, float("inf")):
            data = export(); data["incidents"][0]["occurredAt"] = timestamp
            with self.assertRaises(BridgeError): validate_export(data)

    def test_coordinates_and_text_are_bounded(self):
        data = export(); data["incidents"][0]["location"]["x"] = 0.4
        with self.assertRaises(BridgeError): validate_export(data)
        data = export(); data["incidents"][0]["enemy"]["name"] = "a\nname"
        with self.assertRaises(BridgeError): validate_export(data)
        data = export(); data["incidents"][0]["enemy"]["name"] = "é" * 50
        with self.assertRaises(BridgeError): validate_export(data)

    def test_duplicates_refs_time_and_forged_rewards_are_rejected(self):
        data = export([incident(), incident()])
        with self.assertRaises(BridgeError): validate_export(data)
        for change in (lambda c: c.update(incidentIds=["missing"]), lambda c: c.update(occurredAt=99),
                       lambda c: c.update(reward=999), lambda c: c.update(incidentIds=["i", "i"])):
            data = export(claims=[claim()]); change(data["claims"][0])
            with self.assertRaises(BridgeError): validate_export(data)

    def test_demo_facts_cannot_be_relabelled_live_by_only_changing_mode(self):
        data = export(); data["incidents"][0]["source"] = "demo"
        with self.assertRaisesRegex(BridgeError, "demo_fact_in_live_export"): validate_export(data)

    def test_json_is_strict_and_never_executes_lua(self):
        for raw in ('{"key":1,"key":2}', '{"n":NaN}', 'SyndicatRougeDB = {}'):
            with self.assertRaises(BridgeError): strict_json(raw)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "large.json"; path.write_bytes(b" " * 1_048_577)
            with self.assertRaisesRegex(BridgeError, "file_limit"): read_export(path)


class QueueTests(unittest.TestCase):
    def setUp(self):
        self.queue = Queue(clock=lambda: 1000)

    def tearDown(self):
        self.queue.db.close()

    def jobs(self, category=None, status=None):
        return [row for row in self.queue.status(True) if (category is None or row["category"] == category)
                and (status is None or row["status"] == status)]

    def test_duplicate_import_and_send_do_not_duplicate_announcements(self):
        self.queue.enqueue(export()); self.queue.enqueue(export())
        self.assertEqual(len(self.jobs()), 1)
        self.queue.dispatch(confirmed, enabled=True)
        self.queue.enqueue(export()); self.assertEqual(self.queue.dispatch(confirmed, enabled=True), [])
        self.assertEqual(len(self.jobs(status="sent")), 1)

    def test_preview_does_not_create_state_or_send(self):
        data = read_export(FIXTURE)
        result = preview(data)
        self.assertFalse(result["delivery_enabled"])
        self.assertTrue(result["messages"])
        for row in result["messages"]:
            self.assertIn("DÉMONSTRATION", row["payload"]["content"])
            self.assertEqual(row["payload"]["allowed_mentions"], {"parse": []})

    def test_disabled_relay_and_demo_mode_block_dispatch(self):
        self.queue.enqueue(export(mode="demo"))
        with self.assertRaisesRegex(BridgeError, "relay_disabled"): self.queue.dispatch(confirmed)
        with self.assertRaisesRegex(BridgeError, "demo_sending_forbidden"): self.queue.dispatch(confirmed, enabled=True)
        self.assertEqual(self.jobs()[0]["attempts"], 0)

    def test_disabled_category_is_not_backfilled_when_enabled_later(self):
        self.queue.enqueue(export(), selected=[])
        self.queue.enqueue(export(), selected=CATEGORIES)
        self.assertEqual(self.jobs()[0]["status"], "skipped")
        self.assertEqual(self.queue.dispatch(confirmed, enabled=True), [])

    def test_pending_new_target_is_refreshed_without_a_second_job(self):
        self.queue.enqueue(export())
        self.queue.enqueue(export([incident("j")]))
        self.assertEqual(len(self.jobs()), 1)
        self.assertIn("prime de recherche : 2", self.jobs()[0]["payload"]["content"])
        self.assertIn("+2 réputation", self.jobs()[0]["payload"]["content"])

    def test_pending_bounty_increases_are_coalesced(self):
        self.queue.enqueue(export()); self.queue.dispatch(confirmed, enabled=True)
        self.queue.enqueue(export([incident("j")]))
        self.queue.enqueue(export([incident("k")]))
        self.assertEqual(len(self.jobs("bounty_increased", "pending")), 1)
        self.assertEqual(len(self.jobs("bounty_increased", "cancelled")), 1)
        self.assertIn("prime de recherche : 3", self.jobs("bounty_increased", "pending")[0]["payload"]["content"])

    def test_changed_fact_rejects_the_entire_import(self):
        self.queue.enqueue(export())
        changed = incident(); changed["location"]["zone"] = "changed"
        before = copy.deepcopy(self.queue.status(True))
        with self.assertRaisesRegex(BridgeError, "fact_id_conflict"):
            self.queue.enqueue(export([incident("a-new"), changed]))
        self.assertEqual(len(self.queue.facts("incident")), 1)
        self.assertEqual(self.queue.status(True), before)

    def test_queue_is_bound_to_one_guild_and_mode(self):
        self.queue.enqueue(export())
        data = export(mode="demo")
        with self.assertRaisesRegex(BridgeError, "queue_identity_mismatch"): self.queue.enqueue(data)
        data = export(); data["guildId"] = "other"; data["incidents"][0]["guildId"] = "other"
        with self.assertRaisesRegex(BridgeError, "queue_identity_mismatch"): self.queue.enqueue(data)

    def test_pending_vengeance_is_cancelled_when_disputed(self):
        self.queue.enqueue(export(claims=[claim()]))
        self.queue.enqueue(export(claims=[claim("other", "thorin")]))
        self.assertEqual(len(self.jobs("vengeance", "pending")), 0)
        self.assertEqual(len(self.jobs("correction")), 0)
        self.assertEqual(len(self.jobs("vengeance", "cancelled")), 1)

    def test_sent_vengeance_gets_a_correction_even_if_categories_are_disabled(self):
        self.queue.enqueue(export(claims=[claim()]))
        self.queue.dispatch(confirmed, enabled=True)
        self.queue.enqueue(export(claims=[claim("other", "thorin")]), selected=[])
        self.assertEqual(len(self.jobs("correction", "pending")), 1)
        self.queue.dispatch(confirmed, enabled=True, selected=[])
        self.assertEqual(len(self.jobs("correction", "sent")), 1)
        self.queue.enqueue(export(claims=[claim()]))
        self.assertEqual(len(self.jobs("vengeance", "sent")), 1)
        self.assertEqual(len(self.jobs("vengeance", "pending")), 0)

    def test_disjoint_claims_keep_their_rewards(self):
        other = claim("v2", "thorin"); other["incidentIds"] = ["j"]
        self.queue.enqueue(export([incident(), incident("j")], [claim(), other]))
        self.assertEqual(len(self.jobs("vengeance", "pending")), 2)
        for row in self.jobs("vengeance"): self.assertIn("+1 réputation", row["payload"]["content"])

    def test_ambiguous_failure_does_not_retry(self):
        self.queue.enqueue(export())
        self.queue.dispatch(lambda _message: Result("uncertain", "network_uncertain"), enabled=True)
        self.assertEqual(len(self.jobs(status="uncertain")), 1)
        with self.assertRaisesRegex(BridgeError, "uncertain_jobs"): self.queue.dispatch(confirmed, enabled=True)
        self.queue.resolve(self.jobs()[0]["id"], "retry")
        self.queue.dispatch(confirmed, enabled=True)
        self.assertEqual(self.jobs()[0]["attempts"], 2)

    def test_uncertain_disputed_message_requires_a_deliberate_resolution(self):
        self.queue.enqueue(export(claims=[claim()]))
        self.queue.dispatch(lambda _message: Result("uncertain", "network_uncertain"), enabled=True)
        self.queue.enqueue(export(claims=[claim("other", "thorin")]))
        self.assertEqual(len(self.jobs("correction", "held")), 1)
        identity = self.jobs("vengeance")[0]["id"]
        with self.assertRaisesRegex(BridgeError, "obsolete_retry_forbidden"): self.queue.resolve(identity, "retry")
        self.queue.resolve(identity, "delivered", "123456789")
        self.assertEqual(len(self.jobs("correction", "pending")), 1)

    def test_uncertain_cancel_cancels_the_held_correction(self):
        self.queue.enqueue(export(claims=[claim()]))
        self.queue.dispatch(lambda _message: Result("uncertain", "network_uncertain"), enabled=True)
        self.queue.enqueue(export(claims=[claim("other", "thorin")]))
        self.queue.resolve(self.jobs("vengeance")[0]["id"], "cancel")
        self.assertEqual(len(self.jobs("correction", "cancelled")), 1)

    def test_429_and_cooldown_are_scheduled_without_sleeping(self):
        self.queue.enqueue(export())
        self.queue.dispatch(lambda _message: Result("retry", "rate_limited", delay=5.5), enabled=True)
        self.assertEqual(self.jobs()[0]["next_at"], 1005.5)
        self.assertEqual(self.queue.dispatch(confirmed, enabled=True), [])
        self.queue.clock = lambda: 1006
        self.queue.dispatch(confirmed, enabled=True)
        self.assertEqual(self.jobs()[0]["status"], "sent")

    def test_disabled_category_is_checked_again_before_dispatch(self):
        self.queue.enqueue(export())
        self.queue.dispatch(lambda _message: self.fail("must not send"), enabled=True, selected=[])
        self.assertEqual(self.jobs()[0]["status"], "skipped")

    def test_sender_lock_prevents_import_or_a_second_sender(self):
        self.queue.enqueue(export())
        def transport(_message):
            with self.assertRaisesRegex(BridgeError, "queue_busy"): self.queue.enqueue(export())
            with self.assertRaisesRegex(BridgeError, "queue_busy"): self.queue.dispatch(confirmed, enabled=True)
            return confirmed(_message)
        self.queue.dispatch(transport, enabled=True)
        self.assertEqual(self.queue.meta("active_sender"), "")

    def test_persistence_and_manual_crash_recovery(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "queue.sqlite3"
            with Queue(path) as queue:
                queue.enqueue(export()); queue.set_meta("active_sender", "interrupted")
                queue.db.execute("UPDATE jobs SET status='sending'")
            with Queue(path) as queue:
                with self.assertRaisesRegex(BridgeError, "queue_busy"): queue.enqueue(export())
                self.assertEqual(queue.recover(), 1)
                self.assertEqual(queue.status()[0]["status"], "uncertain")

    def test_transport_exception_is_sanitized(self):
        self.queue.enqueue(export())
        def fail(_message): raise RuntimeError(URL)
        self.queue.dispatch(fail, enabled=True)
        self.assertNotIn(URL, json.dumps(self.queue.status(True)))
        self.assertEqual(self.jobs()[0]["code"], "transport_uncertain")

    def test_mentions_and_markdown_in_names_are_inert(self):
        data = export(); data["incidents"][0]["enemy"]["name"] = "@everyone **enemy**"
        self.queue.enqueue(data)
        message = self.jobs()[0]["payload"]
        self.assertEqual(message["allowed_mentions"], {"parse": []})
        self.assertNotIn("@everyone", message["content"])
        self.assertIn("\\*\\*enemy\\*\\*", message["content"])

    def test_missing_reset_header_pauses_after_a_confirmed_send(self):
        second=incident("j"); second["enemy"]=actor("other-enemy")
        self.queue.enqueue(export([incident(),second]))
        self.queue.dispatch(lambda _message: Result("confirmed","rate_limit_unknown","123456789"),enabled=True)
        self.assertEqual(len(self.jobs(status="sent")),1)
        self.assertEqual(len(self.jobs(status="pending")),1)
        with self.assertRaisesRegex(BridgeError,"rate_limit_unknown"):self.queue.dispatch(confirmed,enabled=True)
        self.queue.recover(); self.queue.dispatch(confirmed,enabled=True)
        self.assertEqual(len(self.jobs(status="sent")),2)


class TransportTests(unittest.TestCase):
    def test_url_is_restricted_and_redirects_are_not_followed(self):
        self.assertEqual(validate_webhook(URL), URL)
        for url in (URL.replace("https:", "http:"), URL.replace("discord.com", "discord.com.evil.test"),
                    URL+"?wait=false", URL+"#secret", URL.replace("discord.com", "user@discord.com")):
            with self.assertRaisesRegex(BridgeError, "invalid_webhook_url"): validate_webhook(url)
        self.assertIsNone(NoRedirect().redirect_request(None, None, 302, "", {}, URL))

    def test_confirmed_message_requires_wait_and_a_message_id(self):
        opener = Opener(data={"id": "123456789"})
        result = WebhookTransport(URL, opener)({"content": "test", "allowed_mentions": {"parse": []}})
        self.assertEqual(result.kind, "confirmed")
        self.assertTrue(opener.requests[0].full_url.endswith("?wait=true"))
        self.assertEqual(WebhookTransport(URL, Opener(status=204))({}).kind, "uncertain")

    def test_rate_limits_use_response_values(self):
        result = WebhookTransport(URL, Opener(429, {"retry_after": 7.25}))({})
        self.assertEqual((result.kind, result.delay), ("retry", 7.25))
        result = WebhookTransport(URL, Opener(data={"id": "123"}, headers={"X-RateLimit-Remaining": "0", "X-RateLimit-Reset-After": "3.5"}))({})
        self.assertEqual(result.delay, 3.5)
        self.assertEqual(WebhookTransport(URL, Opener(429))({}).kind, "uncertain")
        unknown=WebhookTransport(URL,Opener(data={"id":"123"},headers={"X-RateLimit-Remaining":"0"}))({})
        self.assertEqual(unknown.code,"rate_limit_unknown")

    def test_errors_are_classified_without_exposing_url(self):
        self.assertEqual(WebhookTransport(URL, Opener(401))({}).kind, "failed")
        self.assertEqual(WebhookTransport(URL, Opener(503))({}).kind, "uncertain")
        result = WebhookTransport(URL, Opener(error=urllib.error.URLError(URL)))({})
        self.assertNotIn(URL, repr(result)); self.assertEqual(result.code, "network_uncertain")


class CliTests(unittest.TestCase):
    def test_browser_examples_use_the_current_relay_formatter(self):
        expected=preview(read_export(FIXTURE))
        generated=json.loads((ROOT/"demo/assets/discord-preview.json").read_text(encoding="utf-8"))
        self.assertEqual(generated["messages"][:len(expected["messages"])],expected["messages"])
        self.assertEqual(generated["messages"][-1]["category"],"bounty_increased")

    def test_preview_and_output_do_not_create_a_database(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "preview.json"
            self.assertEqual(main(["preview", str(FIXTURE), "--output", str(output)]), 0)
            self.assertFalse(json.loads(output.read_text(encoding="utf-8"))["delivery_enabled"])
            self.assertEqual([path.name for path in Path(directory).iterdir()], ["preview.json"])

    def test_example_configuration_is_disabled(self):
        config = configuration(ROOT / "bridge/config.example.json")
        self.assertFalse(config["enabled"])
        self.assertEqual(config["webhook_env"], "SYNDICAT_DISCORD_WEBHOOK")

    def test_errors_are_fixed_codes_not_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "config.json"
            config.write_text(json.dumps({"enabled":False,"categories":[{}],"webhook_env":URL,"guild_id":"guild"}))
            error = io.StringIO()
            with contextlib.redirect_stderr(error): result = main(["preview", str(FIXTURE), "--config", str(config)])
            self.assertEqual(result, 2); self.assertNotIn(URL,error.getvalue())


if __name__ == "__main__":
    unittest.main()
