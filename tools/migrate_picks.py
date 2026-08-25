# -*- coding: utf-8 -*-
"""Loest die handverlesene Quest-Auswahl aus Zeilennummern in stabile Ids auf.

Die Sichtung von 816 Zeilen steckte als Indizes in `build_matrix.py` und zeigte auf zwei
Hilfsdateien. Das ist die wertvollste Handarbeit im Projekt und haengt so an der
Reihenfolge zweier Dateien - aendert sich dort etwas, zeigt die Auswahl still woandershin.

Hier wird sie einmal aufgeloest und als `data/matrix_picks.json` festgeschrieben. Danach
haengt nichts mehr an Indizes.

**Einmalig, laeuft nicht mehr.** Das Skript liest `PICKS` und `NEW_PICKS` aus der Fassung
von `build_matrix.py` VOR der Zusammenfuehrung. Die gibt es nur noch in der Historie:

    git show 5fab9a4:tools/build_matrix.py

Es bleibt liegen, weil es belegt, wie `matrix_picks.json` entstanden ist - nicht, weil es
noch gebraucht wird.

    python tools/migrate_picks.py     -> data/matrix_picks.json
"""
import json
import os
import re

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    src = open(os.path.join(HERE, "tools", "build_matrix.py"), encoding="utf-8").read()
    ns = {}
    for name in ("PICKS", "NEW_PICKS"):
        exec(re.search(r"%s = \{.*?\n\}" % name, src, re.S).group(0), ns)

    cand = json.load(open(os.path.join(HERE, "data", "quest_lines_candidates.json"),
                          encoding="utf-8"))
    byidx = {i: r for i, r in enumerate(cand, 1)}
    newl = {}
    for line in open(os.path.join(HERE, "data", "new_lines.txt"), encoding="utf-8"):
        p = [x.strip() for x in line.split("|")]
        if len(p) >= 4:
            newl[int(p[0])] = {"text": p[3], "scene": p[2]}

    jall = json.load(open(os.path.join(HERE, "data", "judy_ALL_de.json"),
                          encoding="utf-8"))["files"]
    jud = {str(r["id"]): r for r in jall if r["prefix"].startswith("judy")}
    bytext = {}
    for k, r in jud.items():
        bytext.setdefault((r.get("text") or "").strip(), k)

    out, fail = {}, 0
    for cat, idx in ns["PICKS"].items():
        ids = []
        for i in idx:
            r = byidx.get(i)
            if not r or str(int(r["id"])) not in jud:
                print("!! Index %d nicht aufloesbar" % i); fail += 1; continue
            ids.append("%016x" % int(r["id"]))
        for i in ns["NEW_PICKS"].get(cat, []):
            r = newl.get(i)
            k = bytext.get(r["text"].strip()) if r else None
            if not k:
                print("!! new_lines %d nicht aufloesbar" % i); fail += 1; continue
            ids.append("%016x" % int(k))
        #  Reihenfolge erhalten, Doppelte fallen lassen.
        seen, uniq = set(), []
        for h in ids:
            if h not in seen:
                seen.add(h); uniq.append(h)
        out[cat] = uniq

    p = os.path.join(HERE, "data", "matrix_picks.json")
    json.dump(out, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("Kategorien %d | Zeilen %d | nicht aufloesbar %d"
          % (len(out), sum(len(v) for v in out.values()), fail))
    for c, v in out.items():
        print("   %-28s %3d" % (c, len(v)))


main()
