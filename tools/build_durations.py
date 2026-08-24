"""Baut den Dauern-Index: stringId -> Dauer in Millisekunden.

Die Dauern muessen nicht aus den Audiodateien gemessen werden - sie stehen exakt in den
Quest-Szenen. Jedes `scnDialogLineEvent` traegt `duration` in Millisekunden, und ueber
`screenplayLineId` haengt daran die Zeile mit ihrer `locstringId.ruid`.

Das sind dieselben Werte, die das Spiel benutzt. Eine Schaetzung aus der Zeichenzahl waere
daneben gewesen: fuer "Ich bin froh, dass du da bist." haette sie 2142 ms ergeben,
tatsaechlich sind es 2922 ms - und der Unterschied war im Spiel als halbe Sekunde Versatz
zwischen Ton und Mundbewegung hoerbar.

Zusaetzlich wird der Versatz `sectionDuration - duration` mitgeschrieben. In Judys Voiceset
ist er entweder +1 oder +4900; in den Quest-Szenen kann er anders liegen.

    python tools/build_durations.py     -> data/durations.json
"""
import glob
import json
import os
from collections import Counter

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(HERE, "build", "scenesjson")


def scan(path):
    """Alle Dialogzeilen-Ereignisse einer Szene: ruid -> (Dauer, Versatz, Lipsync)."""
    try:
        d = json.load(open(path, encoding="utf-8"))["Data"]["RootChunk"]
    except Exception as e:
        return {}, str(e)

    lines = {l["itemId"]["id"]: l
             for l in d.get("screenplayStore", {}).get("lines", [])}
    out = {}
    graph = d.get("sceneGraph", {}).get("Data", {}).get("graph", [])
    for n in graph:
        nd = n.get("Data", n)
        tail = None
        if nd.get("$type") == "scnSectionNode":
            sd = nd.get("sectionDuration", {}).get("stu")
            tail = sd
        for e in nd.get("events", []):
            ed = e.get("Data", e)
            if ed.get("$type") != "scnDialogLineEvent":
                continue
            line = lines.get(ed.get("screenplayLineId", {}).get("id"))
            if not line:
                continue
            ruid = int(line["locstringId"]["ruid"])
            dur = ed.get("duration")
            if dur is None:
                continue
            out[ruid] = {
                "dur": dur,
                "tail": (tail - dur) if tail is not None else None,
                "anim": line.get("femaleLipsyncAnimationName", {}).get("$value"),
                "scene": os.path.basename(path).replace(".scene.json", ""),
            }
    return out, None


def main():
    files = sorted(glob.glob(os.path.join(SRC, "*.json")))
    if not files:
        raise SystemExit("keine Szenen-JSONs in %s - erst konvertieren"
                         % os.path.relpath(SRC, HERE))

    index, errors = {}, []
    for f in files:
        got, err = scan(f)
        if err:
            errors.append((os.path.basename(f), err))
            continue
        for ruid, rec in got.items():
            #  Dieselbe Zeile kann in mehreren Szenen vorkommen. Der erste Treffer gewinnt;
            #  abweichende Dauern werden gezaehlt, damit das nicht unbemerkt bleibt.
            if ruid in index and index[ruid]["dur"] != rec["dur"]:
                index[ruid].setdefault("konflikt", []).append(rec["dur"])
            else:
                index.setdefault(ruid, rec)

    arc = json.load(open(os.path.join(HERE, "data", "judy_ALL_de.json"),
                         encoding="utf-8"))
    judy = {r["id"] for r in arc["files"] if r["prefix"].startswith("judy")}
    covered = judy & set(index)

    out = os.path.join(HERE, "data", "durations.json")
    json.dump({str(k): v for k, v in index.items()},
              open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print("Szenen gelesen      : %d" % len(files))
    print("Dauern gesamt       : %d" % len(index))
    print("Judy-Dateien        : %d" % len(judy))
    print("davon mit Dauer     : %d (%.0f%%)" % (len(covered),
                                                 100 * len(covered) / max(len(judy), 1)))
    konf = sum(1 for v in index.values() if "konflikt" in v)
    if konf:
        print("abweichende Dauern  : %d (erste gewinnt)" % konf)
    if errors:
        print("nicht lesbar        : %d" % len(errors))
        for n, e in errors[:3]:
            print("   %s: %s" % (n, e[:60]))
    tails = Counter(v["tail"] for v in index.values() if v["tail"] is not None)
    print()
    print("Haeufigste Versaetze (sectionDuration - duration):")
    for t, c in tails.most_common(6):
        print("   %+6d  %dx" % (t, c))
    print()
    print("geschrieben: %s" % os.path.relpath(out, HERE))


main()
