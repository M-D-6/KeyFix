import sys
from pathlib import Path
from PIL import Image

source = Path(sys.argv[1])
target = Path(sys.argv[2])
target.mkdir(parents=True, exist_ok=True)

image = Image.open(source).convert('RGBA')
for size in (16, 32, 64, 128, 256, 512, 1024):
    image.resize((size, size), Image.LANCZOS).save(target / f'app_icon_{size}.png')
