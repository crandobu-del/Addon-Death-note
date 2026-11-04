"""Generate browser examples with the relay's real formatter; never sends."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from bridge.syndicat_rouge.__main__ import preview
from bridge.syndicat_rouge.delivery import Queue
from bridge.syndicat_rouge.export_reader import read_export

data = read_export(ROOT / "tests/fixtures/discord-export-demo.json")
result = preview(data)
# Add a real queued increase example from a second import, rather than
# reimplementing the formatting or manufacturing a network confirmation.
enemy_id = next(row["enemy"]["id"] for row in data["incidents"] if row["enemy"]["name"] == "Mornecroc")
incidents = sorted((row for row in data["incidents"] if row["enemy"]["id"] == enemy_id), key=lambda row: (row["occurredAt"], row["id"]))
claims = [row for row in data["claims"] if row["enemyId"] == enemy_id]
first = dict(data, incidents=incidents[:1], claims=[])
later = dict(data, incidents=incidents, claims=claims)
with Queue() as queue:
    queue.enqueue(first, selected=[])
    queue.enqueue(later, selected=["bounty_increased"])
    for row in queue.status(True):
        if row["status"] == "pending":
            row["example"] = "Exemple de récidive"
            result["messages"].append(row)
destination = ROOT / "demo/assets/discord-preview.json"
destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("Discord preview examples generated without network access.")
