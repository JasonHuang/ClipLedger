from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "app-store-screenshots"
ICON_PATH = ROOT / "ClipLedger" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "icon_512x512.png"

W, H = 1440, 900


def font(size, weight="regular"):
    candidates = {
        "regular": [
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
        ],
        "bold": [
            "/System/Library/Fonts/SFNS.ttf",
            "/System/Library/Fonts/HelveticaNeue.ttc",
        ],
        "mono": [
            "/System/Library/Fonts/SFNSMono.ttf",
        ],
    }
    for path in candidates.get(weight, candidates["regular"]):
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default(size=size)


F = {
    "hero": font(52, "bold"),
    "subtitle": font(24),
    "title": font(22, "bold"),
    "body": font(17),
    "body_bold": font(17, "bold"),
    "small": font(13),
    "small_bold": font(13, "bold"),
    "caption": font(11),
    "mono": font(13, "mono"),
}


COLORS = {
    "bg": (245, 247, 250),
    "bg2": (235, 240, 247),
    "ink": (24, 30, 38),
    "muted": (99, 110, 123),
    "subtle": (146, 156, 168),
    "panel": (255, 255, 255),
    "panel2": (248, 250, 252),
    "line": (222, 228, 235),
    "blue": (45, 113, 225),
    "blue2": (226, 238, 255),
    "green": (35, 151, 91),
    "green2": (228, 247, 238),
    "orange": (218, 128, 41),
    "orange2": (255, 241, 224),
    "red": (211, 67, 80),
}


def rounded(draw, xy, r, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)


def text(draw, xy, value, fill=COLORS["ink"], font_obj=None, anchor=None):
    draw.text(xy, value, fill=fill, font=font_obj or F["body"], anchor=anchor)


def wrap(draw, value, max_width, font_obj):
    words = value.split()
    lines = []
    current = ""
    for word in words:
        probe = word if not current else current + " " + word
        if draw.textlength(probe, font=font_obj) <= max_width:
            current = probe
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def shadowed_panel(base, xy, radius=28, fill=COLORS["panel"]):
    x1, y1, x2, y2 = xy
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x1 + 8, y1 + 12, x2 + 8, y2 + 12), radius=radius, fill=(18, 31, 56, 38))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(shadow)
    draw = ImageDraw.Draw(base)
    rounded(draw, xy, radius, fill, (213, 220, 230), 1)


def gradient_bg():
    img = Image.new("RGBA", (W, H), COLORS["bg"] + (255,))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        r = int(COLORS["bg"][0] * (1 - t) + COLORS["bg2"][0] * t)
        g = int(COLORS["bg"][1] * (1 - t) + COLORS["bg2"][1] * t)
        b = int(COLORS["bg"][2] * (1 - t) + COLORS["bg2"][2] * t)
        for x in range(W):
            px[x, y] = (r, g, b, 255)
    return img


def draw_icon(draw, cx, cy, kind, color=COLORS["blue"], scale=1.0):
    def s(value):
        return value * scale

    if kind == "clipboard":
        rounded(draw, (cx - s(10), cy - s(12), cx + s(10), cy + s(14)), s(4), None, color, max(1, int(2 * scale)))
        rounded(draw, (cx - s(6), cy - s(18), cx + s(6), cy - s(8)), s(3), COLORS["panel"], color, max(1, int(2 * scale)))
        draw.line((cx - s(5), cy - s(1), cx + s(5), cy - s(1)), fill=color, width=max(1, int(2 * scale)))
        draw.line((cx - s(5), cy + s(6), cx + s(5), cy + s(6)), fill=color, width=max(1, int(2 * scale)))
    elif kind == "pin":
        draw.polygon([(cx - s(2), cy - s(14)), (cx + s(12), cy), (cx + s(4), cy + s(6)), (cx + s(9), cy + s(18)), (cx, cy + s(9)), (cx - s(7), cy + s(16)), (cx - s(3), cy + s(4)), (cx - s(12), cy - s(4))], fill=color)
    elif kind == "search":
        draw.ellipse((cx - s(12), cy - s(12), cx + s(8), cy + s(8)), outline=color, width=max(1, int(3 * scale)))
        draw.line((cx + s(6), cy + s(6), cx + s(17), cy + s(17)), fill=color, width=max(1, int(3 * scale)))
    elif kind == "tag":
        draw.polygon([(cx - s(14), cy - s(12)), (cx + s(3), cy - s(12)), (cx + s(15), cy), (cx, cy + s(15)), (cx - s(14), cy + s(1))], fill=color)
        draw.ellipse((cx - s(8), cy - s(6), cx - s(3), cy - s(1)), fill=COLORS["panel"])
    elif kind == "lock":
        rounded(draw, (cx - s(13), cy - s(1), cx + s(13), cy + s(16)), s(5), color)
        draw.arc((cx - s(10), cy - s(18), cx + s(10), cy + s(7)), 180, 360, fill=color, width=max(1, int(4 * scale)))
    elif kind == "gear":
        draw.ellipse((cx - s(14), cy - s(14), cx + s(14), cy + s(14)), outline=color, width=max(1, int(4 * scale)))
        draw.ellipse((cx - s(4), cy - s(4), cx + s(4), cy + s(4)), fill=color)


def draw_app_chrome(draw, x, y, w, title="ClipLedger"):
    rounded(draw, (x, y, x + w, y + 66), 0, (250, 250, 250))
    for i, color in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        draw.ellipse((x + 18 + i * 20, y + 18, x + 30 + i * 20, y + 30), fill=color)
    rounded(draw, (x + 72, y + 16, x + 106, y + 50), 8, COLORS["blue2"])
    draw_icon(draw, x + 89, y + 35, "clipboard", COLORS["blue"], 0.72)
    text(draw, (x + 116, y + 18), title, font_obj=F["title"])
    text(draw, (x + 116, y + 43), "Local clipboard history", fill=COLORS["muted"], font_obj=F["small"])
    rounded(draw, (x + w - 86, y + 18, x + w - 58, y + 46), 7, (242, 245, 248), (224, 229, 236))
    draw_icon(draw, x + w - 72, y + 32, "search", COLORS["muted"], 0.62)
    rounded(draw, (x + w - 48, y + 18, x + w - 20, y + 46), 7, (242, 245, 248), (224, 229, 236))
    draw_icon(draw, x + w - 34, y + 32, "gear", COLORS["muted"], 0.62)


def pill(draw, xy, label, icon_kind=None, active=False):
    x1, y1, x2, y2 = xy
    fill = COLORS["blue2"] if active else (244, 247, 250)
    outline = (170, 197, 241) if active else (222, 228, 235)
    rounded(draw, xy, 15, fill, outline)
    tx = x1 + 12
    if icon_kind:
        draw_icon(draw, x1 + 16, (y1 + y2) // 2, icon_kind, COLORS["blue"] if active else COLORS["muted"], 0.42)
        tx += 18
    text(draw, (tx, y1 + 7), label, COLORS["blue"] if active else COLORS["muted"], F["small_bold"])


def row(draw, x, y, w, content, meta, pinned=False, selected=False, tag=None):
    fill = (250, 252, 255) if selected else COLORS["panel"]
    rounded(draw, (x, y, x + w, y + 68), 10, fill, (222, 228, 235))
    text(draw, (x + 16, y + 13), content, font_obj=F["body_bold"] if pinned else F["body"])
    cx = x + 16
    if pinned and tag:
        pill(draw, (cx, y + 40, cx + 74, y + 60), tag, "tag", active=True)
        cx += 84
    pill(draw, (cx, y + 40, cx + 112, y + 60), meta, None, False)
    if pinned:
        draw_icon(draw, x + w - 102, y + 34, "pin", COLORS["blue"], 0.62)
    draw_icon(draw, x + w - 62, y + 34, "clipboard", COLORS["muted"], 0.58)
    draw.line((x + w - 34, y + 22, x + w - 22, y + 46), fill=COLORS["red"], width=2)
    draw.line((x + w - 22, y + 22, x + w - 34, y + 46), fill=COLORS["red"], width=2)


def draw_main_window(img, draw, x, y, search=False, tags=False, privacy=False):
    w, h = 514, 704 if search else 660
    shadowed_panel(img, (x, y, x + w, y + h), 24)
    draw_app_chrome(draw, x, y, w)
    y0 = y + 66
    if search:
        rounded(draw, (x + 18, y0 + 12, x + w - 18, y0 + 50), 9, (244, 247, 250), (200, 215, 238))
        draw_icon(draw, x + 36, y0 + 31, "search", COLORS["blue"], 0.54)
        text(draw, (x + 58, y0 + 20), "Search clipboard text", fill=COLORS["muted"], font_obj=F["small"])
        text(draw, (x + 212, y0 + 20), "deploy", fill=COLORS["ink"], font_obj=F["small_bold"])
        y0 += 58

    pill(draw, (x + 18, y0 + 14, x + 106, y0 + 44), "Pinned 3", "pin", True)
    pill(draw, (x + 116, y0 + 14, x + 210, y0 + 44), "History 8", None, False)
    y0 += 66

    text(draw, (x + 22, y0), "Pinned", font_obj=F["body_bold"])
    pill(draw, (x + w - 72, y0 - 4, x + w - 22, y0 + 24), "3", None, False)
    y0 += 32
    if tags:
        pill(draw, (x + 22, y0, x + 78, y0 + 30), "All", None, False)
        pill(draw, (x + 88, y0, x + 166, y0 + 30), "Work", "tag", True)
        pill(draw, (x + 176, y0, x + 252, y0 + 30), "Code", "tag", False)
        pill(draw, (x + 262, y0, x + 350, y0 + 30), "Email", "tag", False)
        y0 += 42

    row(draw, x + 18, y0, w - 36, "Quarterly report checklist", "4 uses", True, True, "Work" if tags else "Work")
    y0 += 80
    row(draw, x + 18, y0, w - 36, "git commit -m \"Update release notes\"", "3 uses", True, False, "Code")
    y0 += 94

    text(draw, (x + 22, y0), "History", font_obj=F["body_bold"])
    pill(draw, (x + w - 78, y0 - 4, x + w - 22, y0 + 24), "8", None, False)
    y0 += 32
    history = [
        ("https://developer.apple.com/app-store/", "2m ago - 38 chars"),
        ("Follow up with design review notes", "12m ago - 34 chars"),
        ("Launch checklist: screenshots, privacy, build", "28m ago - 45 chars"),
    ]
    if search:
        history = [
            ("deploy staging build after screenshots", "3m ago - 38 chars"),
            ("Deployment notes for TestFlight review", "18m ago - 39 chars"),
            ("Release build upload completed", "34m ago - 30 chars"),
        ]
    elif tags:
        history = history[:2]
    for title, meta in history:
        row(draw, x + 18, y0, w - 36, title, meta, False, False)
        y0 += 78

    footer_y = y + h - 48
    draw.line((x, footer_y, x + w, footer_y), fill=(222, 228, 235), width=1)
    draw_icon(draw, x + 36, footer_y + 24, "lock", COLORS["green"] if privacy else COLORS["muted"], 0.62)
    text(draw, (x + 58, footer_y + 15), "Stored locally", fill=COLORS["muted"], font_obj=F["small_bold"])
    pill(draw, (x + w - 204, footer_y + 10, x + w - 92, footer_y + 38), "Settings", None, False)
    pill(draw, (x + w - 82, footer_y + 10, x + w - 20, footer_y + 38), "Quit", None, False)


def draw_settings_window(img, draw, x, y):
    w, h = 540, 468
    shadowed_panel(img, (x, y, x + w, y + h), 24)
    rounded(draw, (x, y, x + w, y + 70), 0, (250, 250, 250))
    for i, color in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        draw.ellipse((x + 18 + i * 20, y + 20, x + 30 + i * 20, y + 32), fill=color)
    rounded(draw, (x + 74, y + 16, x + 110, y + 52), 8, COLORS["blue2"])
    draw_icon(draw, x + 92, y + 35, "gear", COLORS["blue"], 0.66)
    text(draw, (x + 124, y + 18), "Settings", font_obj=F["title"])
    text(draw, (x + 124, y + 44), "ClipLedger", fill=COLORS["muted"], font_obj=F["small"])
    y0 = y + 92
    groups = [
        ("General", "Launch at login", "On"),
        ("History", "Maximum record count", "100"),
        ("Behavior", "Auto pin threshold", "3 uses"),
        ("Privacy", "Clipboard history stays local on your Mac.", ""),
    ]
    for title, label, value in groups:
        text(draw, (x + 24, y0), title, font_obj=F["body_bold"])
        rounded(draw, (x + 24, y0 + 28, x + w - 24, y0 + 78), 10, COLORS["panel2"], COLORS["line"])
        text(draw, (x + 42, y0 + 44), label, font_obj=F["body"])
        if value == "On":
            rounded(draw, (x + w - 94, y0 + 43, x + w - 48, y0 + 63), 11, COLORS["green"])
            draw.ellipse((x + w - 69, y0 + 45, x + w - 51, y0 + 63), fill=COLORS["panel"])
        elif value:
            pill(draw, (x + w - 122, y0 + 38, x + w - 42, y0 + 66), value, None, True)
        y0 += 96


def draw_hero(draw, title, subtitle, accent=COLORS["blue"]):
    text(draw, (80, 110), title, font_obj=F["hero"])
    y = 180
    for line in wrap(draw, subtitle, 510, F["subtitle"]):
        text(draw, (82, y), line, fill=COLORS["muted"], font_obj=F["subtitle"])
        y += 34
    rounded(draw, (82, y + 26, 232, y + 68), 21, accent)
    text(draw, (157, y + 38), "Local only", fill=(255, 255, 255), font_obj=F["body_bold"], anchor="ma")


def add_app_icon(draw, img, x, y, size=78):
    if ICON_PATH.exists():
        icon = Image.open(ICON_PATH).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
        img.alpha_composite(icon, (x, y))
    else:
        rounded(draw, (x, y, x + size, y + size), 18, COLORS["blue2"])
        draw_icon(draw, x + size // 2, y + size // 2, "clipboard", COLORS["blue"])


def screenshot_history():
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    add_app_icon(draw, img, 82, 44, 72)
    draw_hero(draw, "Never lose copied text", "ClipLedger keeps a fast local history right from the menu bar.")
    draw_main_window(img, draw, 790, 104)
    return img


def screenshot_search():
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    add_app_icon(draw, img, 82, 44, 72)
    draw_hero(draw, "Find clips instantly", "Search clipboard text and restore the exact entry you need.", COLORS["green"])
    draw_main_window(img, draw, 790, 78, search=True)
    return img


def screenshot_tags():
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    add_app_icon(draw, img, 82, 44, 72)
    draw_hero(draw, "Pin and organize snippets", "Group your most-used pinned clips by simple, clickable tags.", COLORS["orange"])
    draw_main_window(img, draw, 790, 94, tags=True)
    return img


def screenshot_settings():
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    add_app_icon(draw, img, 82, 44, 72)
    draw_hero(draw, "Private by design", "No accounts, no sync, no analytics. Clipboard history stays on your Mac.", COLORS["green"])
    draw_settings_window(img, draw, 780, 208)
    return img


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    screenshots = [
        ("01-history.png", screenshot_history()),
        ("02-search.png", screenshot_search()),
        ("03-pinned-tags.png", screenshot_tags()),
        ("04-settings-privacy.png", screenshot_settings()),
    ]
    for name, img in screenshots:
        out = OUT_DIR / name
        img.convert("RGB").save(out, "PNG", optimize=True)
        print(out)


if __name__ == "__main__":
    main()
