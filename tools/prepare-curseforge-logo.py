"""Original typographic project avatar, 400px, no game asset or portrait."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent.parent
out = root / 'dist' / 'curseforge'
out.mkdir(parents=True, exist_ok=True)
scale = 3
image = Image.new('RGB', (400*scale, 400*scale), '#211711')
draw = ImageDraw.Draw(image)
def box(coords): return tuple(int(v*scale) for v in coords)
draw.rounded_rectangle(box((18,18,382,382)), radius=22*scale, fill='#493020', outline='#a57848', width=3*scale)
draw.polygon([box(p) for p in [(88,55),(302,55),(315,320),(83,330),(94,285)]], fill='#e6bf7b')
draw.line([box((104,96)),box((281,96))], fill='#9e7141', width=2*scale)
draw.line([box((104,274)),box((281,274))], fill='#9e7141', width=2*scale)
font = ImageFont.truetype('C:/Windows/Fonts/georgiab.ttf', 103*scale)
draw.text((200*scale,182*scale), 'DN', font=font, anchor='mm', fill='#4b2119')
draw.polygon([box(p) for p in [(244,266),(281,274),(304,358),(267,341),(242,365)]], fill='#8d2525')
draw.ellipse(box((212,232,310,330)), fill='#a62d2c', outline='#e09b68', width=3*scale)
draw.ellipse(box((224,244,298,318)), outline='#681d20', width=2*scale)
draw.line([box((240,283)),box((252,294)),box((274,268))], fill='#efca84', width=5*scale)
image.resize((400,400), Image.Resampling.LANCZOS).save(out/'death-note-avatar.png')
print(out/'death-note-avatar.png')
