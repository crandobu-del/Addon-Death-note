"""Package the optional diagnostic companion without replacing released archives."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root = Path(__file__).resolve().parent.parent
folder = root / 'dev' / 'SyndicatRougeDemo'
out = root / 'dist' / 'SyndicatRougeDemo-forever-kill-proof.zip'
out.parent.mkdir(exist_ok=True)
with ZipFile(out, 'w', ZIP_DEFLATED) as archive:
    for source in sorted(folder.iterdir()):
        if source.is_file() and source.suffix in {'.lua', '.toc'}:
            archive.write(source, str(Path(folder.name) / source.name))
print(out)
