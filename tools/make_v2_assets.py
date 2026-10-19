#!/usr/bin/env python3
"""Build the V2 56x40 transparent pet frames from the supplied four-cell source.

The source is a white-background 1536x1024 sheet:
  top-left: front idle (no computer)
  top-right: side view with gray line laptop (typing master)
  bottom-left/right: hand variants (not used as separate frames)

The three typing frames are composited from ONE side master.  Only the hand
moves; all frames share the same canvas, feet baseline and laptop.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "v2-assets" / "source" / "claude-pose-source.png"
OUT = ROOT / "v2-assets"
FRAMES = OUT / "frames"

ORANGE = (217, 119, 87, 255)
ORANGE_LIGHT = (232, 143, 109, 255)
ORANGE_DARK = (197, 104, 77, 255)
INK = (24, 24, 24, 255)
GRAY = (122, 122, 122, 255)
TRANS = (0, 0, 0, 0)
CANVAS = (56, 40)


def classify(r, g, b):
    if r > 242 and g > 242 and b > 242:
        return TRANS
    if max(r, g, b) - min(r, g, b) <= 22 and 55 <= (r + g + b) / 3 <= 235:
        return GRAY
    if r < 80 and g < 80 and b < 80:
        return INK
    if r > 110 and r > g + 10 and g >= b - 8:
        return ORANGE_DARK if (r < 195 or g < 95) else ORANGE
    if (r + g + b) / 3 > 235:
        return TRANS
    return TRANS


def mapped_cell(box):
    im = Image.open(SRC).convert("RGB").crop(box)
    out = Image.new("RGBA", im.size, TRANS)
    src, dst = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            dst[x, y] = classify(*src[x, y])
    return out


def bbox_of(im):
    xs, ys = [], []
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = im.getpixel((x, y))
            if a and r > 150 and r > g + 10:
                xs.append(x)
                ys.append(y)
    return None if not xs else (min(xs), min(ys), max(xs) + 1, max(ys) + 1)


def normalize(cell, target_width, body_cx, bottom):
    ob = bbox_of(cell)
    scale = target_width / (ob[2] - ob[0])
    whole = cell.getbbox()
    crop = cell.crop(whole)
    nw = max(1, round(crop.width * scale))
    nh = max(1, round(crop.height * scale))
    small = crop.resize((nw, nh), Image.Resampling.NEAREST)
    sox = round((ob[0] - whole[0]) * scale)
    sow = max(1, round((ob[2] - ob[0]) * scale))
    sob = round((ob[3] - whole[1]) * scale)
    left = round(body_cx - sox - sow / 2)
    top = round(bottom - sob)
    out = Image.new("RGBA", CANVAS, TRANS)
    out.alpha_composite(small, (left, top))
    return out


def px(im, x, y, color):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), color)


def rect(im, x, y, w, h, color):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px(im, xx, yy, color)


def clear(im, x, y, w, h):
    rect(im, x, y, w, h, TRANS)


def side_master():
    im = normalize(mapped_cell((768, 0, 1536, 512)), 34, 36, 38)
    # Remove the source's noisy laptop/hand/feet zone; keep its face/body.
    clear(im, 0, 0, 23, 40)
    clear(im, 0, 33, 56, 7)
    rect(im, 18, 25, 5, 8, ORANGE)
    rect(im, 20, 29, 4, 4, ORANGE)
    px(im, 18, 27, ORANGE_DARK)
    px(im, 18, 28, ORANGE_DARK)
    for x in (23, 30, 37, 44):
        rect(im, x, 33, 4, 5, ORANGE)
        rect(im, x, 36, 4, 2, ORANGE_DARK)
    # Thin gray line laptop: diagonal screen + short base.
    for i in range(8):
        px(im, 8 + i, 26 + i, GRAY)
    rect(im, 15, 34, 8, 2, GRAY)
    px(im, 15, 33, GRAY)
    return im


def typing_frame(hand_y):
    im = side_master()
    clear(im, 16, 29, 6, 5)
    rect(im, 20, 28, 5, 5, ORANGE)
    rect(im, 17, hand_y, 4, 2, ORANGE_LIGHT)
    px(im, 17, hand_y + 1, ORANGE)
    px(im, 20, hand_y, ORANGE)
    out = Image.new("RGBA", CANVAS, TRANS)
    out.alpha_composite(im, (-1, 0))
    return out


def idle_frame():
    im = normalize(mapped_cell((0, 0, 768, 512)), 42, 30, 38)
    out = Image.new("RGBA", CANVAS, TRANS)
    out.alpha_composite(im, (4, 0))
    return out


def preview(im):
    bg = Image.new("RGB", im.size, (235, 235, 235))
    bg.paste(im, (0, 0), im)
    return bg.resize((im.width * 8, im.height * 8), Image.Resampling.NEAREST)


def main():
    FRAMES.mkdir(parents=True, exist_ok=True)
    idle = idle_frame()
    idle.save(FRAMES / "idle.png")
    frames = {
        "rest": typing_frame(31),
        "left": typing_frame(30),
        "right": typing_frame(32),
    }
    for name, im in frames.items():
        im.save(FRAMES / ("typing-" + name + ".png"))

    meta = {
        "canvas": list(CANVAS),
        "anchor": {"x": 34, "y": 37, "note": "character foot center / foot baseline in CSS px"},
        "idle": "frames/idle.png",
        "typing": {name: "frames/typing-" + name + ".png" for name in frames},
        "typingCycle": ["rest", "left", "rest", "right"],
        "frameMs": 140,
        "note": "Idle is front-facing without a computer. Thinking uses one side master; only the hand moves. All frames share a 56x40 canvas and feet baseline.",
    }
    (OUT / "frames.json").write_text(__import__("json").dumps(meta, indent=2), encoding="utf-8")

    for label, bg in (("light", (246, 246, 246)), ("dark", (30, 30, 30))):
        strip = Image.new("RGB", (4 * 72, 88), bg)
        icons = [idle, frames["rest"], frames["left"], frames["right"]]
        for i, icon in enumerate(icons):
            base = strip.convert("RGBA")
            base.alpha_composite(icon, (i * 72 + 8, 24))
            strip = base.convert("RGB")
        strip.resize((strip.width * 2, strip.height * 2), Image.Resampling.NEAREST).save(
            OUT / ("preview-" + label + ".png")
        )

    seq = [idle] * 7 + [frames["rest"], frames["left"], frames["rest"], frames["right"]] * 3 + [idle] * 7
    gif = []
    for im in seq:
        bg = Image.new("RGB", im.size, (246, 246, 246))
        bg.paste(im, (0, 0), im)
        gif.append(bg)
    gif[0].save(OUT / "preview-thinking.gif", save_all=True, append_images=gif[1:], duration=140, loop=0, disposal=2)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
