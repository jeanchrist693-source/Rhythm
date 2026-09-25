# tool/extraire_fcen.py
#
# Le Fichier canadien sur les éléments nutritifs (FCÉN 2026, Santé Canada,
# Licence du gouvernement ouvert – Canada) → `assets/donnees/fcen.txt`, la
# base d'aliments de Rhythm, HORS LIGNE.
#
# Source (fichiers CSV, portail du gouvernement ouvert) :
#   https://open.canada.ca/data/dataset/1b6139bd-ed7e-4043-bc28-ff00e10f3109
#   (« All Resource Data », cnf_fcen_all-files-data_2026.zip)
#
# Usage : python tool/extraire_fcen.py <dossier des CSV décompressés>
#
# Format produit (UTF-8, séparateur tabulation), lu par
# `lib/modele/alimentation/base_aliments.dart` :
#   # commentaire
#   M  <code mesure>  <libellé français>
#   A  <code>  <groupe>  <nom français>  <kcal>  <protéines g>  <glucides g>
#      <lipides g>  <fibres g>  <sucres g>  <sodium mg>  <saturés g>
#      <mesures : code:grammes,code:grammes>
# Valeurs pour 100 g, vides si inconnues. On ne garde que le nom FRANÇAIS
# (le contenu de Rhythm est en français), les huit nutriments affichés, et
# les portions « définies par l'utilisateur » du FCÉN (type 6 : « 1 moyen »,
# « 250 ml »…). Les aliments pour bébés (groupe 3) sont écartés.

import csv
import os
import sys

NUTRIMENTS = {
    '208': 'kcal',
    '203': 'proteines',
    '205': 'glucides',
    '204': 'lipides',
    '291': 'fibres',
    '269': 'sucres',
    '307': 'sodium',
    '606': 'satures',
}
ORDRE = ['kcal', 'proteines', 'glucides', 'lipides', 'fibres', 'sucres',
         'sodium', 'satures']
GROUPES_EXCLUS = {'3'}


def lire(dossier, nom):
    with open(os.path.join(dossier, nom), encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def propre(texte):
    return ' '.join((texte or '').replace('\t', ' ').split())


def nombre(x, decimales):
    if x is None:
        return ''
    v = round(float(x), decimales)
    if decimales == 0:
        return str(int(v))
    s = f'{v:.{decimales}f}'.rstrip('0').rstrip('.')
    return s if s not in ('', '-0') else '0'


def main():
    if len(sys.argv) < 2:
        sys.exit('Usage : python tool/extraire_fcen.py <dossier des CSV>')
    dossier = sys.argv[1]
    aliments = lire(dossier, 'Food_Name.csv')
    montants = {}
    for r in lire(dossier, 'Nutrient_Amount.csv'):
        cle = NUTRIMENTS.get(r['Nutrient_Code'])
        if cle:
            montants.setdefault(r['Food_Code'], {})[cle] = r['Nutrient_Amount']
    noms_mesures = {
        r['Measure_Code']: propre(r['Measure_Description_and_Unit_FR'])
        for r in lire(dossier, 'Measure_Name.csv')
    }
    mesures = {}
    for r in lire(dossier, 'Measure_Weight_Conversion.csv'):
        if r['Measure_Type_Code'] != '6':
            continue
        try:
            g = float(r['Measure_Weight_Conversion'])
        except ValueError:
            continue
        if g <= 0 or not noms_mesures.get(r['Measure_Code']):
            continue
        mesures.setdefault(r['Food_Code'], []).append((r['Measure_Code'], g))

    lignes = []
    utilisees = set()
    for a in aliments:
        code = a['Food_Code']
        if a['CNF_Food_Group_Code'] in GROUPES_EXCLUS:
            continue
        nom = propre(a['Food_Description_FR'])
        n = montants.get(code, {})
        if not nom or not n:
            continue
        # L'énergie manquante se déduit des macronutriments (4 / 4 / 9).
        if 'kcal' not in n and all(k in n for k in ('proteines', 'glucides', 'lipides')):
            n['kcal'] = (float(n['proteines']) * 4 + float(n['glucides']) * 4
                         + float(n['lipides']) * 9)
        if 'kcal' not in n:
            continue
        valeurs = []
        for k in ORDRE:
            dec = 0 if k in ('kcal', 'sodium') else 1
            valeurs.append(nombre(n.get(k), dec))
        portions = []
        vues = set()
        for m, g in mesures.get(code, []):
            if m in vues:
                continue
            vues.add(m)
            utilisees.add(m)
            portions.append(f'{m}:{nombre(g, 1)}')
        lignes.append('\t'.join(['A', code, a['CNF_Food_Group_Code'], nom,
                                 *valeurs, ','.join(portions)]))

    sortie = os.path.join(os.path.dirname(__file__), '..', 'assets', 'donnees',
                          'fcen.txt')
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    with open(sortie, 'w', encoding='utf-8', newline='\n') as f:
        f.write('# Fichier canadien sur les éléments nutritifs (FCÉN) 2026 — '
                'Santé Canada. Licence du gouvernement ouvert – Canada.\n')
        f.write('# Valeurs pour 100 g : kcal, protéines, glucides, lipides, '
                'fibres, sucres (g), sodium (mg), gras saturés (g).\n')
        for m in sorted(utilisees, key=int):
            f.write(f'M\t{m}\t{noms_mesures[m]}\n')
        for l in lignes:
            f.write(l + '\n')
    print(f'{len(lignes)} aliments, {len(utilisees)} portions → {os.path.normpath(sortie)}')


if __name__ == '__main__':
    main()
