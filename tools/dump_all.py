"""Vollstaendiger Dump aller Judy-Sprachdateien, mit Text wo vorhanden.

Das bisherige Zeilenarchiv war unvollstaendig: es enthielt 1473 Eintraege aus 8 Praefixen,
das Sprachdatei-Listing kennt aber 1669 Dateien aus 14. Es fehlten ganze Questreihen
(q201, q202, q115, mq055) und bei q004 rund zwei Drittel.

Der Grund ist der Join: die Untertitel kommen aus den lang_de_text-Ressourcen und werden
ueber die stringId mit dem Dateinamen verbunden. Fehlt eine stringId im Untertitel-Satz,
faellt die Datei bisher raus - statt sie ohne Text zu zeigen.

Hier faellt nichts mehr raus. Dateien ohne Untertitel werden ausgewiesen, damit die Luecke
sichtbar ist statt unsichtbar.

    python tools/dump_all.py     -> data/judy_ALL_de.md + data/judy_ALL_de.json
"""
import json
import os
import re
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEM = re.compile(r"([a-z0-9_]*judy[a-z0-9_]*)_([fm])_([0-9a-f]{16})\.wem", re.I)


def voice_files():
    """Jede Judy-Sprachdatei aus dem Archiv-Listing."""
    path = os.path.join(HERE, "data", "voice_files_de.txt")
    rows, seen = [], set()
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.strip()
        m = WEM.search(line)
        if not m or line in seen:
            continue
        seen.add(line)
        rows.append({
            "prefix": m.group(1).lower(),
            "gender": m.group(2).lower(),   # Vs Geschlecht, nicht Judys
            "id": int(m.group(3), 16),
            "hex": m.group(3).lower(),
            "path": line,
        })
    return rows


def subtitles():
    """stringId -> (Text, Szene) aus dem Untertitel-Bestand."""
    path = os.path.join(HERE, "data", "voicelines_de.json")
    inv = json.load(open(path, encoding="utf-8"))
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
    files = voice_files()
    subs = subtitles()

    for r in files:
        t, sc = subs.get(r["id"], (None, None))
        r["text"] = t
        r["scene"] = sc or r["prefix"]

    with_text = [r for r in files if r["text"]]
    without = [r for r in files if not r["text"]]

    #  Das Dateimuster faengt auch v_scene_judy_default ein - das ist V, die in einer
    #  Judy-Szene spricht, nicht Judy. Getrennt ausweisen statt mitzaehlen: die Zeilen sind
    #  interessant (Vs Haelfte der Gespraeche), gehoeren aber nicht in Judys Bestand.
    judy = [r for r in files if r["prefix"].startswith("judy")]
    other = [r for r in files if not r["prefix"].startswith("judy")]

    groups = defaultdict(list)
    for r in judy:
        groups[r["prefix"]].append(r)

    lines = [
        "# Judy - alle Sprachdateien",
        "",
        "Vollstaendiger Bestand: **%d Sprachdateien von Judy** in %d Gruppen." % (len(judy), len(groups)),
        "",
        "| | |",
        "|---|---|",
        "| mit Untertitel | %d |" % sum(1 for r in judy if r["text"]),
        "| **ohne Untertitel** | **%d** |" % sum(1 for r in judy if not r["text"]),
        "| dazu von **V** in Judy-Szenen | %d (unten separat) |" % len(other),
        "",
        "Ohne Untertitel heisst: die Audiodatei existiert, aber ihre stringId taucht im",
        "deutschen Untertitel-Bestand nicht auf. Der Text ist damit unbekannt - die Datei",
        "aber vorhanden und grundsaetzlich abspielbar. Diese Zeilen wurden bisher stumm",
        "aussortiert; hier stehen sie mit.",
        "",
        "Die Dauer ist nicht enthalten: sie liesse sich nur aus den Audiodateien messen.",
        "Gemessen sind bisher ausschliesslich die 55 Barks, siehe [MATRIX.md](MATRIX.md).",
        "",
        "`f`/`m` bezeichnet das Geschlecht von **V**, nicht von Judy - dieselbe Zeile",
        "existiert oft in beiden Fassungen.",
        "",
    ]

    for pref in sorted(groups, key=lambda k: -len(groups[k])):
        rows = groups[pref]
        n_txt = sum(1 for r in rows if r["text"])
        lines += [
            "## %s  <sub>%d Dateien, %d mit Text</sub>" % (pref, len(rows), n_txt),
            "",
        ]
        #  nach stringId, damit gleiche Zeile in beiden V-Fassungen beieinander steht
        for r in sorted(rows, key=lambda x: (x["id"], x["gender"])):
            if r["text"]:
                lines.append("- `%s` %s  %s" % (r["hex"], r["gender"], r["text"]))
            else:
                lines.append("- `%s` %s  *(kein Untertitel)*" % (r["hex"], r["gender"]))
        lines.append("")

    if other:
        lines += ["---", "",
                  "## V in Judy-Szenen  <sub>%d Dateien</sub>" % len(other), "",
                  "Nicht Judy. Das Dateimuster faengt diese mit ein, weil der Szenenname",
                  "ihren Namen traegt. Als Gegenstueck der Gespraeche trotzdem nuetzlich.",
                  ""]
        for r in sorted(other, key=lambda x: (x["id"], x["gender"])):
            t = r["text"] or "*(kein Untertitel)*"
            lines.append("- `%s` %s  %s" % (r["hex"], r["gender"], t))
        lines.append("")

    out_md = os.path.join(HERE, "data", "judy_ALL_de.md")
    open(out_md, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")

    out_js = os.path.join(HERE, "data", "judy_ALL_de.json")
    json.dump({"count": len(files), "with_text": len(with_text),
               "without_text": len(without), "files": files},
              open(out_js, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print("Judy-Dateien     : %d" % len(judy))
    print("mit Untertitel   : %d" % sum(1 for r in judy if r["text"]))
    print("ohne Untertitel  : %d" % sum(1 for r in judy if not r["text"]))
    print("V in Judy-Szenen : %d (separat)" % len(other))
    print("verschiedene Texte: %d" % len({r["text"] for r in with_text}))
    print()
    print("Gruppen ohne Text:")
    miss = Counter(r["prefix"] for r in without)
    for k, v in miss.most_common():
        print("   %-30s %4d von %d" % (k, v, len(groups[k])))
    print()
    print("geschrieben: %s (%.0f KB)"
          % (os.path.relpath(out_md, HERE), os.path.getsize(out_md) / 1024))


main()
