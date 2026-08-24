"""Vollstaendiger Dump von weiblicher Vs Sprachdateien.

13464 weibliche Sprachdateien in rund 240 Gruppen - das Achtfache von Judy. Bewusst NICHT
auf Judys Szenen beschraenkt: eine Zeile aus einer ganz anderen Quest kann im
Begleiter-Kontext sitzen, und das sieht man ihr nicht am Herkunftsort an.

Was NICHT geht: der Gesprächsverlauf laesst sich nicht rekonstruieren. Sortiert man eine
Szene nach stringId, liegen Vs Zeilen als Block beieinander - die Ids folgen der
Aufnahme-Charge, nicht der Dialogfolge. Rede und Antwort automatisch zu paaren ist damit
ausgeschlossen; die Zuordnung bleibt Handarbeit.

Ein Vorbehalt zu mq055: das ist die Hangout-Quest fuer ALLE Romanzen, die Untertiteldatei
enthaelt also auch Vs Zeilen an Kerry, River und Panam. Der Sprecher steht nicht in den
Daten, nur im Dateinamen - und Vs Dateiname verraet nicht, mit wem sie spricht.

    python tools/dump_v.py     -> data/v_ALL_de.md + data/v_ALL_de.json
"""
import json
import os
import re
from collections import defaultdict

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEM = re.compile(r"\b([a-z0-9_]+)_([fm])_([0-9a-f]{16})\.wem", re.I)

#  Szenen mit Judy - nur zur Markierung, nicht als Filter.
JUDY_SCENES = ("q105", "sq026", "sq030", "q203", "q004", "q201", "q202",
               "q115", "mq055", "scene_judy", "finalboards")

FRAG = re.compile(
    r"^(und |aber |oder |dann |also |weil |dass |denn |der |die |das |den |dem |"
    r"ihn |ihm |ihr |sie |er |es |ja[,. ]|nein[,. ]|hm|äh|\.\.\.|…)", re.I)


def standalone(t):
    return 14 <= len(t) <= 150 and not FRAG.match(t) and t.count("...") <= 1


def subtitles():
    inv = json.load(open(os.path.join(HERE, "data", "voicelines_de.json"),
                         encoding="utf-8"))
    out = {}
    for p, entries in inv["data"].items():
        scene = p.split(chr(92))[-1].replace(".json", "")
        for e in entries:
            t = e["text"]
            if not isinstance(t, str):
                t = " | ".join(str(x) for x in t)
            out[int(e["id"])] = (t, scene)
    return out


def main():
    subs = subtitles()
    rows, seen = [], set()
    for line in open(os.path.join(HERE, "data", "voice_files_de.txt"),
                     encoding="utf-8", errors="replace"):
        line = line.strip()
        m = WEM.search(line)
        if not m:
            continue
        prefix = m.group(1).lower()
        if not prefix.startswith("v_"):
            continue
        if m.group(2).lower() != "f":          # nur weibliche V
            continue
        sid = int(m.group(3), 16)
        text, scene = subs.get(sid, (None, None))
        if not text or text in seen:
            continue
        seen.add(text)
        rows.append({"prefix": prefix, "id": sid, "hex": m.group(3).lower(),
                     "text": text, "scene": scene or prefix,
                     "solo": standalone(text),
                     "judy": any(j in prefix for j in JUDY_SCENES)})

    groups = defaultdict(list)
    for r in rows:
        groups[r["scene"]].append(r)
    solo = [r for r in rows if r["solo"]]

    out = [
        "# V (weiblich) - vollstaendiger Zeilenbestand",
        "",
        "**%d verschiedene Zeilen** aus %d Szenen." % (len(rows), len(groups)),
        "",
        "Bewusst nicht auf Judys Szenen beschraenkt: eine Zeile aus einer ganz anderen Quest",
        "kann im Begleiter-Kontext sitzen, und das sieht man ihr am Herkunftsort nicht an.",
        "Szenen mit Judy sind mit `[J]` markiert.",
        "",
        "`*` markiert Zeilen, die ohne Vorgeschichte funktionieren (%d von %d)." % (len(solo), len(rows)),
        "",
        "## Zwei Vorbehalte",
        "",
        "**Der Gespraechsverlauf laesst sich nicht rekonstruieren.** Sortiert man eine Szene",
        "nach stringId, liegen Vs Zeilen als Block beieinander - die Ids folgen der",
        "Aufnahme-Charge, nicht der Dialogfolge. Rede und Antwort automatisch zu paaren ist",
        "damit ausgeschlossen; die Zuordnung bleibt Handarbeit.",
        "",
        "**mq055 ist die Hangout-Quest fuer alle Romanzen.** Die Untertiteldatei enthaelt",
        "auch Vs Zeilen an Kerry, River und Panam. Der Sprecher steht nicht in den Daten, und",
        "Vs Dateiname verraet nicht, mit wem sie spricht - diese Szene braucht also Augenmass.",
        "",
    ]
    for sc in sorted(groups, key=lambda k: -len(groups[k])):
        out += ["## %s  <sub>%d Zeilen</sub>" % (sc, len(groups[sc])), ""]
        for r in sorted(groups[sc], key=lambda x: -len(x["text"])):
            out.append("- %s%s %s" % ("*" if r["solo"] else " ",
                                      " [J]" if r["judy"] else "", r["text"]))
        out.append("")

    md = os.path.join(HERE, "data", "v_ALL_de.md")
    open(md, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    json.dump({"count": len(rows), "solo": len(solo), "lines": rows},
              open(os.path.join(HERE, "data", "v_ALL_de.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)

    #  Sichtungsdatei, gleiche Form wie bei Judy
    keep = sorted(solo, key=lambda r: (r["scene"], -len(r["text"])))
    with open(os.path.join(HERE, "data", "v_lines_numbered.txt"), "w",
              encoding="utf-8", newline="\n") as f:
        for i, r in enumerate(keep, 1):
            f.write("%4d | %4.1fs | %-30s | %s\n"
                    % (i, max(0.6, len(r["text"]) / 14.0), r["scene"][:30], r["text"]))

    print("verschiedene Zeilen : %d" % len(rows))
    print("eigenstaendig       : %d" % len(solo))
    print("Szenen              : %d" % len(groups))
    print("geschrieben         : %s (%.0f KB)"
          % (os.path.relpath(md, HERE), os.path.getsize(md) / 1024))


main()
