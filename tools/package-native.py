"""Build separate native development packages; never mix fixtures into production."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'dist'
OUT.mkdir(exist_ok=True)
addon = ROOT / 'addon' / 'SyndicatRouge'
toc = addon / 'SyndicatRouge.toc'
for line in toc.read_text(encoding='utf-8').splitlines():
    if line and not line.startswith('#'):
        assert (addon / line).is_file(), line

for demo in (False, True):
    name = 'SyndicatRouge-forever-0.5.6-dev' + ('-avec-demo' if demo else '')
    with ZipFile(OUT / (name + '.zip'), 'w', ZIP_DEFLATED) as z:
        for folder in ([addon, ROOT / 'dev' / 'SyndicatRougeDemo'] if demo else [addon]):
            for source in sorted(folder.rglob('*')):
                if source.is_file() and source.name not in {'.gitkeep', 'IllustrativeMap.tga', 'Portraits.tga'}:
                    assert source.suffix.lower() in {'.lua','.toc','.ttf','.tga','.txt'}
                    z.write(source, str(Path(folder.name) / source.relative_to(folder)))
        z.write(ROOT / 'LICENSE', 'SyndicatRouge/LICENSE.txt')
    with ZipFile(OUT / (name + '.zip')) as z:
        if not demo:
            assert not any('Demo' in item or 'scenario' in item for item in z.namelist())
    print(OUT / (name + '.zip'))
