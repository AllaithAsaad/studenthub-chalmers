"""Render the project's own geometric book mark. Python standard library only."""
import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GREEN = (23, 63, 53)
LIME = (228, 239, 175)

def inside(x, y, polygon):
    result = False
    j = len(polygon) - 1
    for i, (xi, yi) in enumerate(polygon):
        xj, yj = polygon[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            result = not result
        j = i
    return result

def icon(path, size):
    left = [(25, 28), (46, 34), (46, 73), (25, 67)]
    right = [(54, 34), (75, 28), (75, 67), (54, 73)]
    rows = bytearray()
    for py in range(size):
        rows.append(0)
        for px in range(size):
            # Four-sample anti-aliasing for the vector edges.
            color = [0, 0, 0]
            for dx, dy in [(.25,.25),(.75,.25),(.25,.75),(.75,.75)]:
                x, y = (px + dx) / size * 100, (py + dy) / size * 100
                c = LIME if inside(x,y,left) or inside(x,y,right) else GREEN
                for k in range(3): color[k] += c[k]
            rows.extend(v // 4 for v in color)
    def chunk(kind, data):
        return struct.pack('>I',len(data)) + kind + data + struct.pack('>I',zlib.crc32(kind+data) & 0xffffffff)
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,2,0,0,0)) + chunk(b'IDAT',zlib.compress(rows,9)) + chunk(b'IEND',b''))

for size in [192, 512]:
    for prefix in ['Icon-', 'Icon-maskable-']:
        icon(ROOT / f'web/icons/{prefix}{size}.png', size)
icon(ROOT / 'web/favicon.png', 32)
for platform in ['ios','macos']:
    folder = ROOT / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((folder / 'Contents.json').read_text())['images']:
        if 'filename' in entry:
            size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
            icon(folder / entry['filename'], size)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    icon(ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
print('Generated StudentHub icons for web, iOS, Android and macOS.')
