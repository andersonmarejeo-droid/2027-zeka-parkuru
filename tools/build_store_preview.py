from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store_assets" / "play_store_preview_2026-10-13"
OUT.mkdir(parents=True, exist_ok=True)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = (
        Path("C:/Windows/Fonts/segoeuib.ttf"),
        Path("C:/Windows/Fonts/segoeui.ttf"),
    ) if bold else (
        Path("C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
    )
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


NAVY = (27, 43, 55)
TEAL = (43, 139, 128)
MINT = (242, 247, 244)
CORAL = (211, 102, 91)
AMBER = (220, 157, 56)
VIOLET = (101, 87, 164)


SCREENS = [
    (
        "01_ana_sayfa.png",
        "Ana sayfa",
        "Her kategoride yeni bir zihin rotası",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/65022505-ae59-4395-818b-86be2d54efe3/1-1000038292.jpg",
        TEAL,
    ),
    (
        "02_sehir_atlasi.png",
        "Şehir Atlası",
        "Haritayı keşfet, ipuçlarını birleştir",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/98f9c88b-85d2-4237-89fc-5a71063a10c2/1-1000038031.jpg",
        TEAL,
    ),
    (
        "03_kelime_carki.png",
        "Kelime Çarkı",
        "Harfleri birleştir, kelime hazineni büyüt",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/6513bab9-1719-4756-9d7a-cc8e7f49a706/1-1000038100.jpg",
        VIOLET,
    ),
    (
        "04_park_yeri.png",
        "Park Yeri",
        "Hamlelerini planla, trafiği çöz",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/90188da8-ba31-4193-90f4-86f907d3ab38/1-1000038080.jpg",
        CORAL,
    ),
    (
        "05_odak_filtresi.png",
        "Odak Filtresi",
        "Doğru şekli seç, dikkati koru",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/a634ab16-87b9-42c1-8509-cc6981c20b6b/1-1000038411.jpg",
        CORAL,
    ),
    (
        "06_kart_cifti.png",
        "Kart Çifti",
        "Kısa süreli hafızanı güçlendir",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/3570911e-8871-4a09-8206-19237f973792/1-1000037934.jpg",
        VIOLET,
    ),
    (
        "07_sayilar.png",
        "Sayılar",
        "Deseni gör, doğru işlemi bul",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/aa60c858-febc-40a3-b40f-89a212e572c5/1-1000038272.jpg",
        AMBER,
    ),
    (
        "08_mantik_ve_cozum.png",
        "Mantık ve çözüm",
        "Her hamlede yeni bir bağlantı kur",
        "C:/Users/GiresuN/StudioProjects/zeka_parkuru/.codex-remote-attachments/01a0d3de-20bd-7be2-aec7-99f4fe903a5f/13e083c3-3296-4014-8041-022a09ec85d9/1-1000038291.jpg",
        VIOLET,
    ),
]


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return mask


def paste_rounded(base: Image.Image, image: Image.Image, xy: tuple[int, int], radius: int) -> None:
    mask = rounded_mask(image.size, radius)
    base.paste(image, xy, mask)


def screenshot_frame(index: int, title: str, subtitle: str, source: str, accent: tuple[int, int, int]) -> Image.Image:
    canvas = Image.new("RGB", (1080, 1920), MINT)
    draw = ImageDraw.Draw(canvas)
    draw.text((70, 52), "ZEKA PARKURU", fill=NAVY, font=font(34, True))
    draw.text((70, 104), subtitle, fill=(82, 106, 110), font=font(24))
    draw.rounded_rectangle((865, 47, 1010, 120), 28, fill=accent)
    badge = f"{index:02d} / 08"
    bbox = draw.textbbox((0, 0), badge, font=font(24, True))
    draw.text((937 - (bbox[2] - bbox[0]) / 2, 67), badge, fill="white", font=font(24, True))

    raw = Image.open(source).convert("RGB")
    # Remove Android status/navigation bars while keeping the complete app surface.
    crop = raw.crop((0, 56, raw.width, max(57, raw.height - 84)))
    target = (790, 1555)
    screen = ImageOps.fit(crop, target, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
    shadow = Image.new("RGBA", (target[0] + 30, target[1] + 30), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((15, 15, target[0] + 15, target[1] + 15), 48, fill=(23, 37, 43, 55))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(shadow, (145, 195), shadow)
    paste_rounded(canvas, screen, (145, 195), 42)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((145, 195, 145 + target[0], 195 + target[1]), 42, outline=(255, 255, 255), width=4)
    footer = title.upper()
    bbox = draw.textbbox((0, 0), footer, font=font(28, True))
    draw.text(((1080 - (bbox[2] - bbox[0])) / 2, 1800), footer, fill=accent, font=font(28, True))
    return canvas


def build_feature() -> Image.Image:
    background = ROOT / "store_assets" / "zp_feature_background_preview.png"
    base = ImageOps.fit(Image.open(background).convert("RGB"), (1024, 500), method=Image.Resampling.LANCZOS, centering=(0.46, 0.5))
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for x in range(560, 1024, 12):
        alpha = min(215, 80 + int((x - 560) * 0.35))
        od.rectangle((x, 0, x + 12, 500), fill=(8, 35, 42, alpha))
    base = Image.alpha_composite(base.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(base)
    draw.text((625, 126), "ZEKA", fill=(244, 249, 246), font=font(65, True))
    draw.text((625, 194), "PARKURU", fill=(244, 249, 246), font=font(65, True))
    draw.text((630, 300), "Bul  •  Çöz  •  İlerle", fill=(246, 194, 96), font=font(29, True))
    draw.text((630, 366), "ZP GAMES", fill=(195, 224, 213), font=font(22, True))
    return base.convert("RGB")


def build_icon() -> Image.Image:
    foreground = Image.open(ROOT / "android/app/src/main/res/drawable-nodpi/zp_cube_foreground.png").convert("RGBA")
    canvas = Image.new("RGBA", (512, 512), (231, 242, 236, 255))
    foreground.thumbnail((430, 430), Image.Resampling.LANCZOS)
    x = (512 - foreground.width) // 2
    y = (512 - foreground.height) // 2 + 8
    canvas.alpha_composite(foreground, (x, y))
    return canvas.convert("RGB")


def build_storyboard(frames: Iterable[Image.Image]) -> Image.Image:
    thumbs = []
    for index, frame in enumerate(frames, 1):
        thumb = frame.copy()
        thumb.thumbnail((240, 426), Image.Resampling.LANCZOS)
        card = Image.new("RGB", (270, 490), (237, 244, 239))
        paste_rounded(card, thumb, ((270 - thumb.width) // 2, 16), 16)
        ImageDraw.Draw(card).text((18, 452), f"Kare {index}", fill=NAVY, font=font(18, True))
        thumbs.append(card)
    board = Image.new("RGB", (1080, 980), (222, 235, 228))
    for i, thumb in enumerate(thumbs):
        board.paste(thumb, ((i % 4) * 270, (i // 4) * 490))
    return board


def main() -> None:
    frames: list[Image.Image] = []
    for index, (filename, title, subtitle, source, accent) in enumerate(SCREENS, 1):
        frame = screenshot_frame(index, title, subtitle, source, accent)
        frame.save(OUT / filename, format="PNG", optimize=True)
        frames.append(frame)

    build_feature().save(OUT / "feature_graphic_preview_1024x500.png", format="PNG", optimize=True)
    build_icon().save(OUT / "app_icon_preview_512.png", format="PNG", optimize=True)
    build_storyboard(frames).save(OUT / "video_storyboard_preview.png", format="PNG", optimize=True)

    # A lightweight motion preview is intentionally GIF: final Play video is encoded after the visual direction is approved.
    gif_frames = [frame.resize((540, 960), Image.Resampling.LANCZOS) for frame in frames]
    gif_frames[0].save(OUT / "video_motion_preview.gif", save_all=True, append_images=gif_frames[1:], duration=1500, loop=0, optimize=True)

    (OUT / "VIDEO_PLAN.txt").write_text(
        "Zeka Parkuru mağaza videosu taslağı\n"
        "- Süre: yaklaşık 12 saniye\n"
        "- Dikey: 1080x1920, 1.5 saniye/kare\n"
        "- Akış: Ana sayfa > Şehir Atlası > Kelime Çarkı > Park Yeri > Odak > Kart Çifti > Sayılar > Mantık\n"
        "- Metin: ZEKA PARKURU / Bul • Çöz • İlerle / ZP GAMES\n"
        "- Stil: koyu yeşil-teal, mint arka plan, kontrollü coral/amber/violet vurgu; neon yok.\n"
        "- GIF dosyası burada yalnızca hareketli önizlemedir; son onaydan sonra YouTube/Play uyumlu MP4 kodlanacaktır.\n",
        encoding="utf-8",
    )
    print(f"Store preview files written to: {OUT}")


if __name__ == "__main__":
    main()
