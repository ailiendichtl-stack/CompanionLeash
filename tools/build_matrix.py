"""Baut MATRIX.md aus den vermessenen Barks und der HANDVERLESENEN Quest-Auswahl.

Die Stichwortsuche davor war untauglich: sie beruehrte 20% der Zeilen und zeigte davon
sechs pro Kategorie, also rund 10% des Materials - und traf dabei Unsinn wie "Zusammen mit
meinen Grosseltern" unter Zuneigung. Die Auswahl unten ist stattdessen durchgelesen.

Das Ergebnis der Sichtung, das die eigentliche Erkenntnis ist: von 816 eigenstaendigen
Zeilen sind nur rund 80 als Begleiter-Zeile brauchbar. Der Rest handelt VON der Quest -
Evelyn, Fingers, Maiko, das Clouds - und funktioniert ausserhalb nicht, egal wie gut er
klingt.

Die Dauer der Quest-Zeilen ist aus der Zeichenzahl geschaetzt und nur zum Sortieren
brauchbar; die Barks sind im Spiel gemessen.
"""
import json
import os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#  Zeilennummern aus data/quest_lines_numbered.txt, von Hand gesichtet.
PICKS = {
    "Ankunft / Wiedersehen": [17, 96, 269, 271, 433, 615, 140],
    "Spieler bleibt zurueck": [249, 251, 260, 261, 437, 474, 478, 621, 744, 750, 95, 132, 731],
    "Warten / Ungeduld": [212, 181, 735, 739],
    "Kampf": [264, 265, 266, 255, 542, 544, 733],
    "Kampf vorbei / Lob": [236, 243, 270, 741],
    "Stealth": [267, 273, 253],
    "Spieler verletzt / Sorge": [257, 509, 515, 520, 623, 776, 777, 780, 596, 351, 358, 813],
    "Idle / Smalltalk": [55, 63, 272, 550, 347, 405, 717, 730, 726, 749],
    "Zuneigung / Naehe": [51, 57, 59, 790, 815, 773, 805, 812],
    "Umgebung / Aussicht": [703, 668, 682, 684, 734],
    "Zustimmung": [182, 476, 471, 526, 784],
    "Wasser / Schwimmen": [712, 722, 742],
}

#  Bark-Familien je Kategorie. Kategorien ohne Eintrag haben keine Bark - genau die sind
#  die Kandidaten fuer Fake-Lipsync.
FAMS = {
    "Ankunft / Wiedersehen": ["return_answer", "greeting"],
    "Spieler bleibt zurueck": ["follow_me", "hurry_up", "urge"],
    "Warten / Ungeduld": ["interrupt", "phone_urge"],
    "Kampf": ["battlecry_morale", "combat_aggro_bark", "enemy_warning", "battlecry_curse",
              "danger", "elite_warning", "grenade_enemy", "grenade_throw", "reloading"],
    "Kampf vorbei / Lob": ["combat_ended"],
    "Stealth": ["stealth_restored", "stealth_warning_bark", "detection_warning",
                "camera_warning", "body_warning"],
    "Spieler verletzt / Sorge": ["player_fallback", "grapple"],
    "Idle / Smalltalk": ["bump"],
}


def load_lines():
    path = os.path.join(HERE, "data", "quest_lines_candidates.json")
    rows = json.load(open(path, encoding="utf-8"))
    return {i: r for i, r in enumerate(rows, 1)}


def load_barks():
    path = os.path.join(HERE, "data", "judy_lines_measured.json")
    meas = json.load(open(path, encoding="utf-8"))["unique"]
    fams = {}
    for u in meas:
        base = u["name"].split("_var_")[0]
        if base.startswith("follow_me"):
            base = "follow_me"
        fams.setdefault(base, []).append(u)
    for v in fams.values():
        v.sort(key=lambda u: -u["dur"])
    return fams, len(meas)


def main():
    lines = load_lines()
    fams, n_barks = load_barks()

    out = [
        "# Bark- und Zeilen-Matrix",
        "",
        "Bestandsaufnahme vor dem Verdrahten.",
        "",
        "**Barks** aus `vset_judy.scene` - benannt, im Spiel gemessen, ueber den",
        "Quest-Voiceset-Knoten sofort spielbar. %d Zeilen, vollstaendig." % n_barks,
        "",
        "**Quest-Zeilen** sind **noch nicht spielbar** - dafuer braucht es Fake-Lipsync",
        "ueber Audioware oder eine eigene Szene. Ihre Dauer ist aus der Zeichenzahl",
        "geschaetzt, nicht gemessen.",
        "",
        "## Was die Sichtung ergeben hat",
        "",
        "Alle 816 eigenstaendigen Szenen-Zeilen wurden durchgelesen. Brauchbar als",
        "Begleiter-Zeile sind davon rund **80**.",
        "",
        "Der Rest handelt **von der Quest** - Evelyn, Fingers, Maiko, das Clouds, der",
        "Braindance-Job - und funktioniert ausserhalb seines Zusammenhangs nicht, egal wie",
        "gut er klingt. Das ist die wichtigste Einschraenkung fuer die Planung: die 1104",
        "Quest-Zeilen sind kein Reservoir von 1104 einsetzbaren Zeilen.",
        "",
        "Die vorherige Stichwortsuche war untauglich - sie beruehrte 20% der Zeilen, zeigte",
        "davon sechs pro Kategorie und stellte dabei \"Zusammen mit meinen Grosseltern\"",
        "unter Zuneigung. Der vollstaendige Bestand steht in [LINES.md](LINES.md).",
        "",
        "---",
        "",
    ]

    used_barks = set()
    total_picks = 0
    for cat in PICKS:
        out += ["## " + cat, ""]
        bl = []
        for f in FAMS.get(cat, []):
            for u in fams.get(f, []):
                if u["name"] not in [b["name"] for b in bl]:
                    bl.append(u)
        if bl:
            out += ["| Bark | s | Zeile |", "|---|---|---|"]
            for u in bl:
                out.append("| `%s` | %.2f | %s |" % (u["name"], u["dur"], u["text"]))
                used_barks.add(u["name"])
        else:
            out.append("*Keine Bark deckt das ab - hier lohnt sich Fake-Lipsync am meisten.*")
        out.append("")

        picks = [lines[i] for i in PICKS[cat] if i in lines]
        if picks:
            out += ["Quest-Zeilen (gesichtet, %d):" % len(picks), ""]
            for r in sorted(picks, key=lambda r: -len(r["text"])):
                out.append("- ~%.1fs %s  <sub>`%s`</sub>"
                           % (max(0.6, len(r["text"]) / 14.0), r["text"], r["scene"]))
            total_picks += len(picks)
        out.append("")

    rest = sorted(set(u["name"] for v in fams.values() for u in v) - used_barks)
    if rest:
        flat = {u["name"]: u for v in fams.values() for u in v}
        out += ["---", "", "## Barks ohne Kategorie", ""]
        for n in rest:
            out.append("- `%s` (%.2fs) %s" % (n, flat[n]["dur"], flat[n]["text"]))
        out.append("")

    path = os.path.join(HERE, "MATRIX.md")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("MATRIX.md: %d Kategorien, %d Barks zugeordnet von %d, %d Quest-Zeilen gesichtet"
          % (len(PICKS), len(used_barks), n_barks, total_picks))
    if rest:
        print("Barks ohne Kategorie: %s" % ", ".join(rest))


main()
