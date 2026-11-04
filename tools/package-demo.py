"""Package only the browser preview, never as a WoW addon."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
build = root / "demo" / "build"
required = ["index.html", "app.js", "app.css", "assets/register.png", "assets/avengers.png", "assets/map.png"]
missing = [name for name in required if not (build / name).is_file()]
if missing:
    raise SystemExit("Build the preview first. Missing: " + ", ".join(missing))
destination = root / "dist" / "SyndicatRouge-demo-hors-jeu-0.1.0.zip"
destination.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(destination, "w", ZIP_DEFLATED) as archive:
    for name in required:
        archive.write(build / name, "SyndicatRouge-demo/" + name)
    archive.writestr("SyndicatRouge-demo/LIRE-MOI.txt", "Le Syndicat Rouge - Death Note\nDemonstration hors jeu uniquement.\nExtraire ce dossier puis ouvrir index.html dans un navigateur.\nLes donnees et actions sont fictives. Aucun message Discord ou de guilde n'est envoye.\nCeci n'est pas un addon installable dans WoW.\n")
print(destination)
