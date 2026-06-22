from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "app-store-screenshots"
SOURCE_DIR = OUT_DIR / "source"
ICON_PATH = ROOT / "ClipLedger" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "icon_512x512.png"

W, H = 1440, 900


def font(size, weight="regular"):
    candidates = {
        "regular": ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Helvetica.ttc"],
        "bold": ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/HelveticaNeue.ttc"],
    }
    for path in candidates[weight]:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default(size=size)


F = {
    "hero": font(52, "bold"),
    "subtitle": font(24),
    "body": font(17),
    "body_bold": font(17, "bold"),
}

COLORS = {
    "bg_top": (247, 249, 252),
    "bg_bottom": (229, 236, 246),
    "ink": (24, 30, 38),
    "muted": (92, 103, 118),
    "blue": (32, 120, 255),
    "green": (32, 151, 89),
    "orange": (223, 129, 34),
    "white": (255, 255, 255),
}


def gradient_bg():
    img = Image.new("RGBA", (W, H), COLORS["bg_top"] + (255,))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        r = int(COLORS["bg_top"][0] * (1 - t) + COLORS["bg_bottom"][0] * t)
        g = int(COLORS["bg_top"][1] * (1 - t) + COLORS["bg_bottom"][1] * t)
        b = int(COLORS["bg_top"][2] * (1 - t) + COLORS["bg_bottom"][2] * t)
        for x in range(W):
            px[x, y] = (r, g, b, 255)
    return img


def wrap(draw, value, max_width, font_obj):
    words = value.split()
    lines = []
    current = ""
    for word in words:
        probe = word if not current else f"{current} {word}"
        if draw.textlength(probe, font=font_obj) <= max_width:
            current = probe
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def add_text_block(img, title, subtitle, accent):
    draw = ImageDraw.Draw(img)
    if ICON_PATH.exists():
        icon = Image.open(ICON_PATH).convert("RGBA").resize((72, 72), Image.Resampling.LANCZOS)
        img.alpha_composite(icon, (82, 50))

    draw.text((82, 142), title, fill=COLORS["ink"], font=F["hero"])
    y = 214
    for line in wrap(draw, subtitle, 560, F["subtitle"]):
        draw.text((84, y), line, fill=COLORS["muted"], font=F["subtitle"])
        y += 34

    draw.rounded_rectangle((84, y + 28, 232, y + 70), radius=21, fill=accent)
    draw.text((158, y + 39), "Local only", fill=COLORS["white"], font=F["body_bold"], anchor="ma")


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def add_shadowed_screenshot(img, source_name, box, crop=None, radius=26):
    source = Image.open(SOURCE_DIR / source_name).convert("RGBA")
    if crop:
        source = source.crop(crop)

    x, y, w, h = box
    source = source.resize((w, h), Image.Resampling.LANCZOS)

    mask = rounded_mask(source.size, radius)

    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((x + 10, y + 18, x + w + 10, y + h + 18), radius=radius, fill=(28, 43, 70, 55))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    img.alpha_composite(shadow)
    img.paste(source, (x, y), mask)


def make_page(title, subtitle, accent, source_name, box, crop=None):
    img = gradient_bg()
    add_text_block(img, title, subtitle, accent)
    add_shadowed_screenshot(img, source_name, box, crop=crop)
    return img.convert("RGB")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    main_crop = (13, 14, 481, 653)
    search_crop = (13, 14, 481, 653)
    pinned_crop = (13, 14, 481, 653)

    screenshots = [
        (
            "01-history.png",
            make_page(
                "Clipboard history in one click",
                "Open ClipLedger from the menu bar and restore copied text whenever you need it.",
                COLORS["blue"],
                "history-window.png",
                (806, 86, 562, 768),
                crop=main_crop,
            ),
        ),
        (
            "02-search.png",
            make_page(
                "Search across clips",
                "Find the exact item fast, then copy it back to the system clipboard.",
                COLORS["green"],
                "search-tags-window.png",
                (806, 86, 562, 768),
                crop=search_crop,
            ),
        ),
        (
            "03-pinned-tags.png",
            make_page(
                "Pin and filter by tag",
                "Keep important snippets pinned, tagged, and ready above the rest of history.",
                COLORS["orange"],
                "pinned-tags-window.png",
                (806, 86, 562, 768),
                crop=pinned_crop,
            ),
        ),
        (
            "04-settings-privacy.png",
            make_page(
                "Private by design",
                "No accounts, no sync, no analytics. Clipboard history stays on your Mac.",
                COLORS["green"],
                "settings-window.png",
                (760, 172, 650, 590),
                crop=(0, 0, 520, 472),
            ),
        ),
    ]

    for name, screenshot in screenshots:
        output = OUT_DIR / name
        screenshot.save(output, "PNG", optimize=True)
        print(output)


if __name__ == "__main__":
    main()
