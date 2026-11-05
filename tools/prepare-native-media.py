"""Convert approved artwork into uncompressed power-of-two TGA textures for WoW.
No painting or new artwork is performed here.
"""
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parent.parent
inputs = [
    ('art/native/register.png', 'Register.tga', (1024,1024)),
    ('docs/plans/death-note/assets/death-note-syndicat-rouge-v3.png', 'Portraits.tga', (1024,1024)),
    ('demo/assets/illustrative-map.png', 'IllustrativeMap.tga', (1024,512)),
]
for source, name, size in inputs:
    target = ROOT / 'addon/SyndicatRouge/Media/Textures' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(ROOT / source) as image:
        image.convert('RGB').resize(size, Image.Resampling.LANCZOS).save(target, compression=None)
    with Image.open(target) as check:
        assert check.size == size and check.mode == 'RGB'
    print(name, size)
