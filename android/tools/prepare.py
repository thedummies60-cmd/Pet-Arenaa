"""Prepares the Android build inputs: web assets (games, logos, offline fonts) and launcher icons."""
import os
import re
import sys
import urllib.request

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ANDROID = os.path.join(ROOT, "android")
OUT = sys.argv[1]
ASSETS = os.path.join(OUT, "assets")
RES = os.path.join(OUT, "res")

# (asset name, game html, logo)
GAMES = [
    ("normaal", "Pet_Arena98.html", "Schattige Pet Arena-hondenmascotte.png"),
    ("halloween", "Pet_Arena_Hallowee4_.html", "Halloweense Pet Arena-logo.png"),
    ("thanksgiving", "Pet_Arena_Thanksgiving__1_.html", "Herfstige Kalkoen Pet Arena-logo.png"),
    ("kerst", "Pet_Arena_Kggrst_1__1_.html", "Sneeuwman in de Pet Arena.png"),
]
APP_ICON = "Schattige Pet Arena-hondenmascotte.png"
FONTS_RE = re.compile(r'<link href="(https://fonts\.googleapis\.com/css2\?[^"]+)" rel="stylesheet">')
UA = "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36"


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def bundle_fonts(css_url, name):
    """Downloads a Google Fonts stylesheet and its font files so the game works offline."""
    css = fetch(css_url.replace("&amp;", "&")).decode()
    os.makedirs(os.path.join(ASSETS, "fonts"), exist_ok=True)

    def local(m):
        url = m.group(1)
        fname = re.sub(r"[^A-Za-z0-9._-]", "_", url.split("/s/", 1)[1])
        path = os.path.join(ASSETS, "fonts", fname)
        if not os.path.exists(path):
            with open(path, "wb") as f:
                f.write(fetch(url))
        return "url(" + fname + ")"

    css = re.sub(r"url\((https://fonts\.gstatic\.com/[^)]+)\)", local, css)
    with open(os.path.join(ASSETS, "fonts", name + ".css"), "w") as f:
        f.write(css)
    return "fonts/" + name + ".css"


def write_assets():
    os.makedirs(os.path.join(ASSETS, "img"), exist_ok=True)
    with open(os.path.join(ANDROID, "web", "index.html")) as f:
        menu = f.read()
    with open(os.path.join(ASSETS, "index.html"), "w") as f:
        f.write(menu)
    bundle_fonts("https://fonts.googleapis.com/css2?family=Lilita+One&display=swap", "menu")

    for name, html, logo in GAMES:
        with open(os.path.join(ROOT, html), encoding="utf-8") as f:
            src = f.read()
        m = FONTS_RE.search(src)
        if m:
            src = src.replace(m.group(1), bundle_fonts(m.group(1), name))
        with open(os.path.join(ASSETS, name + ".html"), "w", encoding="utf-8") as f:
            f.write(src)
        Image.open(os.path.join(ROOT, logo)).convert("RGB").resize((512, 512), Image.LANCZOS).save(
            os.path.join(ASSETS, "img", name + ".webp"), quality=88)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def circle(img):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, img.size[0] - 1, img.size[1] - 1), fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def write_icons():
    logo = Image.open(os.path.join(ROOT, APP_ICON)).convert("RGB")
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for d, k in densities.items():
        folder = os.path.join(RES, "mipmap-" + d)
        os.makedirs(folder, exist_ok=True)
        # Legacy icons (Android < 8): the full logo, rounded square / circle.
        px = round(48 * k)
        small = logo.resize((px, px), Image.LANCZOS)
        rounded(small, px // 6).save(os.path.join(folder, "ic_launcher.png"))
        circle(small).save(os.path.join(folder, "ic_launcher_round.png"))
        # Adaptive foreground (108dp, of which the launcher shows the middle 72dp): draw the logo
        # at 80dp so almost all of it is visible, and stretch its edge pixels over the margin.
        full = round(108 * k)
        inner = round(80 * k)
        pad = (full - inner) // 2
        fg = Image.new("RGB", (full, full))
        fg.paste(logo.resize((inner, inner), Image.LANCZOS), (pad, pad))
        src = fg.load()
        for y in range(full):
            for x in range(full):
                cx = min(max(x, pad), pad + inner - 1)
                cy = min(max(y, pad), pad + inner - 1)
                if (cx, cy) != (x, y):
                    src[x, y] = src[cx, cy]
        fg.save(os.path.join(folder, "ic_launcher_foreground.png"))

    v26 = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(v26, exist_ok=True)
    xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
           '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
           '    <background android:drawable="@color/ic_launcher_background" />\n'
           '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
           '</adaptive-icon>\n')
    for n in ("ic_launcher", "ic_launcher_round"):
        with open(os.path.join(v26, n + ".xml"), "w") as f:
            f.write(xml)


if __name__ == "__main__":
    write_assets()
    write_icons()
