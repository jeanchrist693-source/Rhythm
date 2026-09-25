# tool/gen_icone.py
#
# Icône PROVISOIRE de Rhythm : le logo — quatre capsules pastel (corail,
# pêche, menthe, lavande), dressées comme les barres d'un égaliseur — sur le
# noir OLED de l'app. La géométrie est CELLE de `lib/widgets/logo_rhythm.dart`
# (à garder alignées) : la scène d'ouverture recompose exactement ce dessin.
# Produit dans assets/icone/ :
#   - icone.png              1024², plein cadre (iOS, Android ancien)
#   - icone_avant_plan.png   1024², capsules sur transparent (adaptative,
#                            sans marge : le logo tient dans la zone sûre)
#   - icone_monochrome.png   1024², capsules blanches (Android 13+)
# Puis : dart run flutter_launcher_icons
#
#   python tool/gen_icone.py

from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parent.parent
SORTIE = RACINE / "assets" / "icone"
TAILLE = 1024
SUR = 4  # suréchantillonnage (bords lisses)

# ── lib/widgets/logo_rhythm.dart ─────────────────────────────────────────────
LARGEUR_BARRE = 0.13
ECART_BARRES = 0.085
HAUTEURS = [0.46, 0.78, 0.60, 0.34]
COULEURS = [(0xFF, 0x8A, 0x7A), (0xFF, 0xD3, 0xA8), (0xA6, 0xEF, 0xCB), (0xD9, 0xC8, 0xFF)]


def centre(i: int) -> float:
    total = 4 * LARGEUR_BARRE + 3 * ECART_BARRES
    return (1 - total) / 2 + i * (LARGEUR_BARRE + ECART_BARRES) + LARGEUR_BARRE / 2


def logo(cote_relatif: float, fond, monochrome: bool = False) -> Image.Image:
    """Le logo dans un carré de `cote_relatif` × le cadre, centré."""
    t = TAILLE * SUR
    image = Image.new("RGBA", (t, t), fond)
    d = ImageDraw.Draw(image)
    cote = t * cote_relatif
    origine = (t - cote) / 2
    for i, h in enumerate(HAUTEURS):
        largeur = LARGEUR_BARRE * cote
        hauteur = h * cote
        cx = origine + centre(i) * cote
        cy = t / 2
        d.rounded_rectangle(
            (cx - largeur / 2, cy - hauteur / 2, cx + largeur / 2, cy + hauteur / 2),
            radius=largeur / 2,
            fill=(255, 255, 255, 255) if monochrome else COULEURS[i] + (255,),
        )
    return image.resize((TAILLE, TAILLE), Image.LANCZOS)


def main() -> None:
    SORTIE.mkdir(parents=True, exist_ok=True)
    # Plein cadre : le logo occupe 64 % du côté.
    logo(0.64, (0, 0, 0, 255)).convert("RGB").save(SORTIE / "icone.png")
    # Adaptative : calque de 108 dp dont 72 visibles ; à 56 %, la capsule la
    # plus haute fait ~65 % de la zone visible et tout tient dans le cercle
    # sûr de 66 dp.
    logo(0.56, (0, 0, 0, 0)).save(SORTIE / "icone_avant_plan.png")
    logo(0.56, (0, 0, 0, 0), monochrome=True).save(SORTIE / "icone_monochrome.png")
    print("icônes écrites dans", SORTIE)


if __name__ == "__main__":
    main()
