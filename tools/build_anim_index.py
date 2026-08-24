"""Baut den Animationsindex: Lipsync-Name -> Laenge in Millisekunden.

Hintergrund: eine gebaute Zeile klang verzoegert, obwohl ihre Dauer exakt aus der
Herkunftsszene stammte. Der Vergleich zeigte, woran es lag - ihre Lipsync-Animation ist
4267 ms lang, die Zeile aber nur 2922 ms. Die Animation traegt kein Versatzfeld, also
laeuft sie ab Ereignisbeginn; ist sie deutlich laenger als die Zeile, passt der Mund nicht
zum Ton.

Bei intakten Zeilen liegt die Animation im Bereich der Zeilenlaenge, meist etwas darunter
oder wenige hundert Millisekunden darueber. Dieser Index macht die Ausreisser sichtbar,
damit der Generator sie meiden kann, statt sie im Spiel zu entdecken.

    python tools/build_anim_index.py     -> data/anim_durations.json
"""
import glob
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
WORK = os.path.join(HERE, "build", "animscan")


def main():
    files = sorted(glob.glob(os.path.join(HERE, "data", "lipsync", "**", "judy.anims"),
                             recursive=True))
    print("Anim-Sets: %d" % len(files))
    os.makedirs(WORK, exist_ok=True)

    index = {}
    for i, src in enumerate(files, 1):
        scene = os.path.basename(os.path.dirname(src))
        out = os.path.join(WORK, scene)
        js = os.path.join(out, "judy.anims.json")
        if not os.path.exists(js):
            os.makedirs(out, exist_ok=True)
            subprocess.run([CLI, "convert", "serialize", src, "-o", out],
                           capture_output=True, text=True, errors="replace")
        if not os.path.exists(js):
            print("   !! %s nicht lesbar" % scene)
            continue
        try:
            d = json.load(open(js, encoding="utf-8"))["Data"]["RootChunk"]
        except Exception as e:
            print("   !! %s: %s" % (scene, str(e)[:50]))
            continue
        for e in d.get("animations", []):
            a = e["Data"]["animation"]["Data"]
            #  Dieselbe Animation kann in mehreren Szenen liegen; sie ist dieselbe Datei,
            #  der erste Treffer genuegt.
            index.setdefault(a["name"]["$value"],
                             {"ms": int(round(a["duration"] * 1000)), "scene": scene})
        sys.stdout.write("\r   %d/%d  %-46s" % (i, len(files), scene[:46]))
        sys.stdout.flush()
    print()

    out = os.path.join(HERE, "data", "anim_durations.json")
    json.dump(index, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("Animationen: %d" % len(index))
    print("geschrieben: %s" % os.path.relpath(out, HERE))


main()
