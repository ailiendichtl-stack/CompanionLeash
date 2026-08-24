"""Bereitet Judys Szenen-Zeilen zum Sichten auf.

Die Stichwortsuche hat nur 20% der Zeilen ueberhaupt beruehrt und davon 6 pro Kategorie
gezeigt - also rund 10% des Materials. Statt die Auswahl einem Regex zu ueberlassen,
werden die Zeilen hier durchnummeriert ausgegeben und von Hand zugeordnet.

Gefiltert wird nur, was ohne Vorgeschichte nicht funktioniert: Fragmente, Fortsetzungen
und blosse Pronomen-Bezuege. Die Dauer ist aus der Zeichenzahl geschaetzt (~14 Zeichen pro
Sekunde) und taugt zum Sortieren, nicht zum Timing - anders als bei den Barks, die im
Spiel gemessen sind.

    python tools/prep_lines.py            # schreibt data/quest_lines_numbered.txt
"""
import json
import os
import re

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FRAG = re.compile(
    r"^(und |aber |oder |dann |also |weil |dass |denn |der |die |das |den |dem |"
    r"ihn |ihm |ihr |sie |er |es |ja[,. ]|nein[,. ]|hm|aeh|äh|\.\.\.|…)",
    re.I,
)


def estimate(text):
    """Sprechdauer aus der Zeichenzahl. Nur zum Sortieren."""
    return max(0.6, len(text) / 14.0)


def standalone(text):
    """Funktioniert die Zeile ohne die vorherige?"""
    if len(text) < 14 or len(text) > 150:
        return False
    if FRAG.match(text):
        return False
    if text.count("...") > 1:
        return False
    return True


def load():
    path = os.path.join(HERE, "data", "line_archive_judy_de.json")
    arc = json.load(open(path, encoding="utf-8"))
    rows, seen = [], set()
    for r in arc["lines"]:
        if "vset" in r["speaker"]:
            continue  # die 55 Barks stehen schon in MATRIX.md
        t = r["text"]
        if not isinstance(t, str):
            t = " | ".join(str(x) for x in t)
        t = t.strip()
        if len(t) < 4 or t in seen:
            continue
        seen.add(t)
        rows.append({"text": t, "scene": r["scene"], "id": r["id"]})
    return rows


def main():
    rows = load()
    keep = [r for r in rows if standalone(r["text"])]
    keep.sort(key=lambda r: (r["scene"], -estimate(r["text"])))

    out = os.path.join(HERE, "data", "quest_lines_numbered.txt")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        for i, r in enumerate(keep, 1):
            f.write("%4d | %4.1fs | %-34s | %s\n"
                    % (i, estimate(r["text"]), r["scene"][:34], r["text"]))

    json.dump(keep, open(os.path.join(HERE, "data", "quest_lines_candidates.json"),
                         "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print("Zeilen gesamt        : %d" % len(rows))
    print("eigenstaendig nutzbar: %d" % len(keep))
    print("aussortiert          : %d (Fragmente, Fortsetzungen, zu kurz/lang)"
          % (len(rows) - len(keep)))
    print("geschrieben          : %s" % os.path.relpath(out, HERE))


main()
