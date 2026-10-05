#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["numpy", "pillow"]
# ///
"""Generates one flashcard per IAU constellation into flashcards/astronomy/constellations/.

Each card gets two images rendered from real star positions:
  stars.jpg   the star field (front)
  figure.jpg  the same field with the stick figure and the Stellarium illustration (back)

Usage, from the repo root:
  uv run tools/constellations/generate.py [Ori And ...]

Pass IAU abbreviations to render only those. Source data is downloaded into
tools/constellations/.cache/ on first run. See CREDITS.md for data licenses.
"""

import json
import math
import sys
import unicodedata
import urllib.request
from datetime import date, timedelta
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

from facts import FACTS

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CACHE = HERE / ".cache"
OUT = ROOT / "flashcards" / "astronomy" / "constellations"

STELLARIUM = "https://raw.githubusercontent.com/Stellarium/stellarium/master/skycultures/modern/"
D3_CELESTIAL = "https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/"

# Stars used by Stellarium's figures but fainter than d3-celestial's magnitude-6
# catalog. From Hipparcos (VizieR I/239): ra, dec (deg), Vmag, B-V.
EXTRA_STARS = {
    10826: (34.83661103, -2.97706055, 6.47, 0.966),   # Mira, a variable (mag 2-10)
    17999: (57.71840155, 23.96158078, 6.95, 0.078),
    30665: (96.66333841, 13.10142119, 6.60, 0.556),
    33165: (103.55436047, -23.92834798, 6.65, -0.056),
    91589: (280.18287968, -47.02727395, 6.80, 0.079),
    102805: (312.40723273, 12.54489131, 6.01, 0.420),
}

# Constellations without their own illustration borrow a neighbor's: Puppis and
# Vela were part of Argo Navis (drawn with Carina); Serpens is held by Ophiuchus.
ART_FROM = {"Pup": "Car", "Vel": "Car", "Ser": "Oph"}

SIZE = 1080
SUPERSAMPLE = 2

BACKGROUND_TOP = np.array([0x1A, 0x17, 0x38], float)
BACKGROUND_BOTTOM = np.array([0x0C, 0x0B, 0x1E], float)
MAGENTA = np.array([240, 62, 200], float)
VIOLET = np.array([123, 77, 255], float)
LINE = (60, 214, 255)
LABEL = (255, 177, 153)
TEXT_DIM = (169, 155, 201)

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
FONT_REGULAR = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"


# MARK: Data

def fetch(url: str, name: str) -> Path:
    path = CACHE / name
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        print(f"downloading {name}")
        urllib.request.urlretrieve(url, path)
    return path


def load_data():
    index = json.loads(fetch(STELLARIUM + "index.json", "index.json").read_text())
    stars = {}
    for feature in json.loads(fetch(D3_CELESTIAL + "stars.6.json", "stars.6.json").read_text())["features"]:
        ra, dec = feature["geometry"]["coordinates"]
        bv = feature["properties"].get("bv") or "0.6"
        stars[feature["id"]] = (ra % 360, dec, feature["properties"]["mag"], float(bv))
    stars.update(EXTRA_STARS)
    names = json.loads(fetch(D3_CELESTIAL + "starnames.json", "starnames.json").read_text())
    # Proper names from Stellarium's curated list; d3-celestial's are used only
    # for Bayer designations and constellation membership.
    proper = {}
    for key, entries in index["common_names"].items():
        if key.startswith("HIP ") and entries:
            proper[key.split()[1]] = entries[0]["english"]
    for hip, info in names.items():
        info["name"] = proper.get(hip, "")
    return index, stars, names


def art_for(constellation, by_abbr):
    abbr = constellation["id"].split()[-1]
    source = constellation if "image" in constellation else by_abbr.get(ART_FROM.get(abbr, ""))
    if not source or "image" not in source:
        return None
    image = source["image"]
    path = fetch(STELLARIUM + image["file"], image["file"])
    return Image.open(path).convert("L"), image


# MARK: Geometry

class Projection:
    """Stereographic projection centered on (ra0, dec0). +X points west (sky as
    seen from Earth, east on the left), +Y north."""

    def __init__(self, ra0, dec0):
        self.ra0 = math.radians(ra0)
        self.dec0 = math.radians(dec0)

    def __call__(self, ra, dec):
        ra = np.radians(ra)
        dec = np.radians(dec)
        cos_c = np.sin(self.dec0) * np.sin(dec) + np.cos(self.dec0) * np.cos(dec) * np.cos(ra - self.ra0)
        k = 2 / (1 + cos_c)
        x = k * np.cos(dec) * np.sin(ra - self.ra0)
        y = k * (np.cos(self.dec0) * np.sin(dec) - np.sin(self.dec0) * np.cos(dec) * np.cos(ra - self.ra0))
        return -x, y, cos_c


def center_of(ras, decs):
    ras, decs = np.radians(ras), np.radians(decs)
    v = np.array([np.cos(decs) * np.cos(ras), np.cos(decs) * np.sin(ras), np.sin(decs)]).mean(axis=1)
    v /= np.linalg.norm(v)
    return math.degrees(math.atan2(v[1], v[0])) % 360, math.degrees(math.asin(v[2]))


class Frame:
    """Maps projected coordinates to output pixels."""

    def __init__(self, xs, ys, size, art_xs=(), art_ys=()):
        """Frames the figure's stars, widened to show more of the illustration
        but never more than `max_zoom_out` times the figure, so small patterns
        with big artwork stay legible."""
        pad, max_zoom_out = 1.3, 2.2
        figure_side = max(max(xs) - min(xs), max(ys) - min(ys), 0.05) * pad
        all_xs, all_ys = list(xs) + list(art_xs), list(ys) + list(art_ys)
        cx, cy = (min(all_xs) + max(all_xs)) / 2, (min(all_ys) + max(all_ys)) / 2
        side = max(max(all_xs) - min(all_xs), max(all_ys) - min(all_ys)) * pad
        if side > figure_side * max_zoom_out:
            side = figure_side * max_zoom_out
            cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        side = max(side, figure_side)
        # Nudge the content down to leave room for the title in the top-left.
        cy += side * 0.04
        self.cx, self.cy, self.size = cx, cy, size
        self.scale = size / side

    def pixel(self, x, y):
        return (x - self.cx) * self.scale + self.size / 2, self.size / 2 - (y - self.cy) * self.scale

    def to_world(self):
        """3x3 matrix taking output pixel (u, v, 1) to projected (x, y, 1)."""
        s = 1 / self.scale
        return np.array([
            [s, 0, self.cx - self.size / 2 * s],
            [0, -s, self.cy + self.size / 2 * s],
            [0, 0, 1],
        ])


def art_affine(image_info, stars, project):
    """3x3 matrix taking illustration pixel (px, py, 1) to projected (x, y, 1),
    fitted through the illustration's three anchor stars."""
    src, dst = [], []
    for anchor in image_info["anchors"]:
        ra, dec, _, _ = stars[anchor["hip"]]
        x, y, _ = project(ra, dec)
        src.append([anchor["pos"][0], anchor["pos"][1], 1])
        dst.append([float(x), float(y)])
    coefficients = np.linalg.solve(np.array(src, float), np.array(dst, float))
    return np.vstack([coefficients.T, [0, 0, 1]])


# MARK: Rendering

def background(size):
    t = np.linspace(0, 1, size)[:, None, None]
    image = BACKGROUND_TOP * (1 - t) + BACKGROUND_BOTTOM * t
    image = np.repeat(image, size, axis=1)
    yy, xx = np.mgrid[0:size, 0:size] / size - 0.5
    vignette = 1 - 0.45 * np.clip(np.sqrt(xx**2 + yy**2) / 0.7, 0, 1) ** 2
    return image * vignette[..., None]


def star_color(bv):
    stops = [(-0.3, (160, 185, 255)), (0.0, (205, 220, 255)), (0.4, (250, 248, 255)),
             (0.8, (255, 236, 205)), (1.4, (255, 200, 150))]
    bv = min(max(bv, stops[0][0]), stops[-1][0])
    for (b0, c0), (b1, c1) in zip(stops, stops[1:]):
        if bv <= b1:
            t = (bv - b0) / (b1 - b0)
            return tuple(c0[i] + (c1[i] - c0[i]) * t for i in range(3))
    return stops[-1][1]


def star_radius(mag):
    return min(max(1.0, 1.0 + 1.25 * (5.6 - mag)), 9.5)


def render_stars(field, frame, highlight):
    """Returns (core, glow) float RGB layers. `highlight` stars get a minimum size
    so faint figure stars still read as part of the pattern."""
    ss = SUPERSAMPLE
    layer = Image.new("RGB", (frame.size * ss, frame.size * ss))
    draw = ImageDraw.Draw(layer)
    for hip, (u, v, mag, bv) in sorted(field.items(), key=lambda item: -item[1][2]):
        if hip in highlight:
            mag = min(mag, 4.3)
        r = star_radius(mag) * ss
        brightness = min(max(0.45 + 0.13 * (6 - mag), 0.45), 1.0)
        color = tuple(int(c * brightness) for c in star_color(bv))
        draw.ellipse([u * ss - r, v * ss - r, u * ss + r, v * ss + r], fill=color)
    core = layer.resize((frame.size, frame.size), Image.LANCZOS)
    glow = np.asarray(core.filter(ImageFilter.GaussianBlur(7)), float) * 2.2
    halo = np.asarray(core.filter(ImageFilter.GaussianBlur(22)), float) * 1.4
    return np.asarray(core, float), glow + halo


def render_lines(lines, pixels, radii, size):
    ss = SUPERSAMPLE
    layer = Image.new("RGB", (size * ss, size * ss))
    draw = ImageDraw.Draw(layer)
    for polyline in lines:
        for a, b in zip(polyline, polyline[1:]):
            if a not in pixels or b not in pixels:
                continue
            (ua, va), (ub, vb) = pixels[a], pixels[b]
            length = math.hypot(ub - ua, vb - va)
            gap_a, gap_b = radii[a] + 7, radii[b] + 7
            if length <= gap_a + gap_b:
                continue
            dx, dy = (ub - ua) / length, (vb - va) / length
            start = ((ua + dx * gap_a) * ss, (va + dy * gap_a) * ss)
            end = ((ub - dx * gap_b) * ss, (vb - dy * gap_b) * ss)
            draw.line([start, end], fill=LINE, width=3 * ss)
    core = layer.resize((size, size), Image.LANCZOS)
    glow = np.asarray(core.filter(ImageFilter.GaussianBlur(5)), float) * 1.6
    return np.asarray(core, float) * 0.85 + glow


def render_art(art, image_info, frame, stars, project, strength):
    image, _ = art
    affine = art_affine(image_info, stars, project)
    # PIL wants output pixel → input pixel.
    m = np.linalg.inv(affine) @ frame.to_world()
    warped = image.transform((frame.size, frame.size), Image.AFFINE,
                             data=tuple(m[:2].flatten()), resample=Image.BICUBIC, fillcolor=0)
    alpha = np.asarray(warped, float)[..., None] / 255
    t = np.linspace(0, 1, frame.size)[None, :, None]
    tint = MAGENTA * (1 - t) + VIOLET * t
    return alpha * tint * strength


def label(image, title, subtitle):
    draw = ImageDraw.Draw(image)
    subtitle_font = ImageFont.truetype(FONT_REGULAR, 26)
    spaced = " ".join(title.upper())
    size = 46
    while size > 24 and draw.textlength(spaced, font=ImageFont.truetype(FONT_BOLD, size)) > image.width - 88:
        size -= 2
    title_font = ImageFont.truetype(FONT_BOLD, size)
    draw.text((44, 36), spaced, font=title_font, fill=LABEL)
    draw.text((46, 96), subtitle.upper(), font=subtitle_font, fill=TEXT_DIM)


def star_labels(image, named):
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(FONT_REGULAR, 22)
    for name, u, v, r in named:
        x, y = u + r + 10, v - 13
        if x + draw.textlength(name, font=font) > image.width - 16:
            x = u - r - 10 - draw.textlength(name, font=font)
        draw.text((x, y), name, font=font, fill=(235, 225, 255))


def compose(*layers):
    return Image.fromarray(np.clip(sum(layers), 0, 255).astype(np.uint8))


# MARK: Facts

def brightest_star(abbr, stars, names):
    members = [(stars[int(hip)][2], info) for hip, info in names.items()
               if info.get("c") == abbr and int(hip) in stars]
    mag, info = min(members, key=lambda m: m[0])
    return info, mag


def star_display_name(info, genitive):
    designation = info.get("bayer") or info.get("flam") or info.get("var")
    proper = info.get("name")
    full = f"{designation} {genitive}" if designation else None
    if proper and full:
        return f"{proper} ({full})"
    return proper or full or "unnamed"


def magnitude(value):
    text = f"{value:.1f}"
    return "0.0" if text == "-0.0" else text.replace("-", "−")


def best_month(ra_deg):
    """Month when the constellation is highest at about 9 PM local time."""
    hours = ra_deg / 15
    days = ((hours - 9) % 24) / 24 * 365.25
    return (date(2001, 3, 21) + timedelta(days=days)).strftime("%B")


def latitude(value):
    value = int(round(value / 5) * 5)
    return "0°" if value == 0 else f"{abs(value)}°{'N' if value > 0 else 'S'}"


# MARK: Cards

def folder_name(name):
    ascii_name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    return ascii_name.lower().replace(" ", "_")


def build(constellation, by_abbr, stars, names):
    abbr = constellation["id"].split()[-1]
    facts = FACTS[abbr]
    lines = constellation["lines"]
    figure_hips = {hip for line in lines for hip in line}

    ras = [stars[h][0] for h in figure_hips]
    decs = [stars[h][1] for h in figure_hips]
    project = Projection(*center_of(ras, decs))

    xs, ys, _ = project(np.array(ras), np.array(decs))
    xs, ys = list(xs), list(ys)
    art_xs, art_ys = [], []
    art = art_for(constellation, by_abbr)
    if art and abbr not in ART_FROM:
        # Fit the frame around the illustration's visible extent too.
        image, info = art
        affine = art_affine(info, stars, project)
        box = image.point(lambda p: 255 if p > 24 else 0).getbbox()
        if box:
            for px, py in [(box[0], box[1]), (box[2], box[1]), (box[0], box[3]), (box[2], box[3])]:
                x, y, _ = affine @ [px, py, 1]
                art_xs.append(x)
                art_ys.append(y)
    frame = Frame(xs, ys, SIZE, art_xs, art_ys)

    all_hips = np.array(list(stars))
    data = np.array([stars[h] for h in all_hips])
    fx, fy, cos_c = project(data[:, 0], data[:, 1])
    u, v = frame.pixel(fx, fy)
    visible = (cos_c > 0.2) & (u > -20) & (u < SIZE + 20) & (v > -20) & (v < SIZE + 20)
    field = {int(h): (u[i], v[i], data[i, 2], data[i, 3]) for i, h in enumerate(all_hips) if visible[i]}

    star_core, star_glow = render_stars(field, frame, figure_hips)
    base = background(SIZE)

    front = compose(base, star_glow, star_core)

    pixels = {h: field[h][:2] for h in figure_hips if h in field}
    radii = {h: star_radius(min(field[h][2], 4.3)) for h in pixels}
    strength = 0.45 if abbr in ART_FROM else 0.75
    art_layer = render_art(art, art[1], frame, stars, project, strength) if art else 0
    back = compose(base, art_layer, render_lines(lines, pixels, radii, SIZE), star_glow, star_core)

    named = []
    for hip, (su, sv, mag, _) in sorted(field.items(), key=lambda item: item[1][2]):
        info = names.get(str(hip), {})
        if info.get("c") == abbr and info.get("name") and mag < 3.0 and len(named) < 3:
            named.append((info["name"], su, sv, star_radius(mag)))
    star_labels(back, named)
    label(back, facts["name"], facts["meaning"])

    folder = OUT / folder_name(facts["name"])
    folder.mkdir(parents=True, exist_ok=True)
    front.save(folder / "stars.jpg", quality=86, optimize=True, progressive=True)
    back.save(folder / "figure.jpg", quality=86, optimize=True, progressive=True)

    star_info, star_mag = brightest_star(abbr, stars, names)
    member_decs = [stars[int(h)][1] for h, i in names.items() if i.get("c") == abbr and int(h) in stars]
    north = min(90, 90 + min(member_decs))
    south = max(-90, max(member_decs) - 90)
    ra0 = center_of(ras, decs)[0]

    (folder / "flashcard.md").write_text(f"""---
title: {facts["name"]}
tags: [astronomy, constellations]
---
## Front
![Star field](stars.jpg)

Which constellation is this?

## Back
# {facts["name"]}
*{facts["meaning"]}* · {abbr} · genitive *{facts["genitive"]}*

![{facts["name"]} with its figure](figure.jpg)

{facts["description"]}

- **Brightest star:** {star_display_name(star_info, facts["genitive"])}, magnitude {magnitude(star_mag)}
- **Best seen:** {best_month(ra0)} evenings
- **Fully visible:** between {latitude(north)} and {latitude(south)}

> **Fun fact:** {facts["fun_fact"]}
""")
    print(f"{abbr:4} {facts['name']}")


def main():
    index, stars, names = load_data()
    constellations = index["constellations"]
    by_abbr = {c["id"].split()[-1]: c for c in constellations}
    missing = set(by_abbr) - set(FACTS)
    if missing:
        sys.exit(f"facts.py is missing: {sorted(missing)}")
    only = set(sys.argv[1:])
    for constellation in constellations:
        if not only or constellation["id"].split()[-1] in only:
            build(constellation, by_abbr, stars, names)


if __name__ == "__main__":
    main()
