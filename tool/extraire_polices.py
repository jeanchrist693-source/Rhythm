# tool/extraire_polices.py
#
# Les polices de Rhythm viennent de la MAQUETTE elle-même : `design/Rhythm.html`
# embarque, en WOFF2, les deux familles Google Fonts qu'elle emploie —
# Bricolage Grotesque (titres, chiffres) et DM Sans (texte). Flutter ne lit
# pas le WOFF2 : ce script les ressort en TTF dans `assets/polices/`, sans
# rien télécharger.
#
# Le WOFF2 est compressé en Brotli. Le module Python `brotli` n'étant pas
# installé ici, la décompression passe par Node (`zlib.brotliDecompressSync`,
# intégré) — fontTools fait le reste (reconstruction des tables glyf/loca).
#
#   python tool/extraire_polices.py

import base64
import gzip
import json
import re
import subprocess
import sys
import types
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
MAQUETTE = RACINE / "design" / "Rhythm.html"
SORTIE = RACINE / "assets" / "polices"


def _brotli_par_node(donnees: bytes) -> bytes:
    script = (
        "const z=require('zlib');const c=[];process.stdin.on('data',d=>c.push(d));"
        "process.stdin.on('end',()=>process.stdout.write(z.brotliDecompressSync(Buffer.concat(c))));"
    )
    return subprocess.run(
        ["node", "-e", script], input=donnees, capture_output=True, check=True
    ).stdout


def _installer_brotli() -> None:
    import fontTools.ttLib.woff2 as woff2

    if woff2.haveBrotli:
        return
    woff2.brotli = types.SimpleNamespace(decompress=_brotli_par_node)
    woff2.haveBrotli = True


def _bloc(html: str, type_: str) -> str:
    m = re.search(
        r'<script type="__bundler/%s">\s*(.*?)\s*</script>' % re.escape(type_),
        html,
        re.S,
    )
    if not m:
        sys.exit(f"bloc {type_} introuvable dans la maquette")
    return m.group(1)


def _deballer(entree: dict) -> bytes:
    donnees = base64.b64decode(entree["data"])
    return gzip.decompress(donnees) if entree.get("compressed") else donnees


def main() -> None:
    _installer_brotli()
    from fontTools.ttLib import TTFont

    racine = MAQUETTE.read_text(encoding="utf-8")
    manifeste = json.loads(_bloc(racine, "manifest"))
    # Première planche (Accueil) : ses @font-face déclarent les deux familles.
    premiere = json.loads(_bloc(racine, "page_order"))[0]
    page = _deballer(manifeste[premiere]).decode("utf-8")
    fichiers = json.loads(_bloc(page, "manifest"))
    gabarit = json.loads(_bloc(page, "template"))

    # famille + sous-ensemble (commentaire CSS) → uuid du fichier WOFF2
    faces = re.findall(
        r"/\* ([\w-]+) \*/\s*@font-face \{\s*font-family: '([^']+)';.*?src: url\(\"([0-9a-f-]+)\"\)",
        gabarit,
        re.S,
    )
    SORTIE.mkdir(parents=True, exist_ok=True)
    faits = set()
    for sous_ensemble, famille, uuid in faces:
        # Le sous-ensemble « latin » couvre le français (accents, « », œ,
        # espaces insécables, €) — les autres ne serviraient à rien ici.
        if sous_ensemble != "latin" or famille in faits:
            continue
        faits.add(famille)
        tmp = SORTIE / "_tmp.woff2"
        tmp.write_bytes(_deballer(fichiers[uuid]))
        police = TTFont(str(tmp))
        police.flavor = None
        nom = famille.replace(" ", "") + "-Variable.ttf"
        police.save(str(SORTIE / nom))
        tmp.unlink()
        axes = (
            ", ".join(
                f"{a.axisTag} {a.minValue:g}–{a.maxValue:g} ({a.defaultValue:g})"
                for a in police["fvar"].axes
            )
            if "fvar" in police
            else "statique"
        )
        print(f"{nom} : {axes}")


if __name__ == "__main__":
    main()
