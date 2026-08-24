"""Durchstich, zweiter Anlauf: bestehende Zeile umbiegen statt neue anlegen.

Der erste Versuch spielte weiterhin eine fremde Zeile, auch nachdem die Debug-Symbole
stimmten. Damit stehen zwei ganz verschiedene Ursachen im Raum, und ich habe die
naheliegendere nie geprueft:

  A  Das Archiv wird gar nicht geladen. Dann existiert `cl_test_froh` nicht, der
     Dispatcher tut nichts, und was zu hoeren war, kam von NCA - `follow_me` ist genau
     das, was eine folgende Begleiterin von selbst sagt.
  B  Das Archiv laedt, aber neu angelegte Einstiegspunkte werden nicht registriert.

Dieser Bau trennt beides, indem er **keinen einzigen neuen Knoten** anlegt: er biegt die
vorhandene Zeile von `danger` auf unsere Testzeile um. Knotenzahl, Symbolzahl und
Zeilenzahl bleiben damit unveraendert - alle Buchfuehrung stimmt zwangslaeufig.

  `danger` sagt die Testzeile   -> Archiv laedt, Bindung stimmt, Ursache ist B
  `danger` sagt "Achtung!"      -> Archiv laedt nicht, Ursache ist A

    python tools/durchstich2.py
"""
import json
import os
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich2")
DEPOT = "base/quest/secondary_characters/vsets"

HEX = "39669188b9a4e000"
TEXT = "Ich bin froh, dass du da bist."
#  "Achtung!" - die kuerzeste, unverwechselbarste Vanilla-Zeile. Ihr Eintrag heisst
#  `danger` und laeuft NICHT ueber einen Randomizer, ist also eindeutig zuzuordnen.
TARGET_RUID = "1796592928331644932"


def main():
    d = json.load(open(SRC, encoding="utf-8"))
    root = d["Data"]["RootChunk"]
    lines = root["screenplayStore"]["lines"]

    hit = None
    for l in lines:
        if l["locstringId"]["ruid"] == TARGET_RUID:
            hit = l
            break
    if hit is None:
        raise SystemExit("Zielzeile nicht gefunden")

    before = hit["femaleLipsyncAnimationName"]["$value"]
    hit["locstringId"]["ruid"] = str(int(HEX, 16))
    hit["femaleLipsyncAnimationName"]["$value"] = "f_" + HEX.upper()
    hit["maleLipsyncAnimationName"]["$value"] = "m_" + HEX.upper()

    graph = root["sceneGraph"]["Data"]["graph"]
    ds = root["debugSymbols"]
    print("Zeile umgebogen (itemId %d)" % hit["itemId"]["id"])
    print("  vorher : ruid %s  lipsync %s" % (TARGET_RUID, before))
    print("  nachher: ruid %s  lipsync %s"
          % (hit["locstringId"]["ruid"], hit["femaleLipsyncAnimationName"]["$value"]))
    print()
    print("Knoten %d = Knotensymbole %d | Zeilen %d = Ereignissymbole %d"
          % (len(graph), len(ds["sceneNodesDebugSymbols"]),
             len(lines), len(ds["sceneEventsDebugSymbols"])))
    print("-> unveraendert gegenueber Vanilla, keine neue Buchfuehrung noetig")
    print()

    os.makedirs(os.path.join(BUILD, DEPOT), exist_ok=True)
    out_json = os.path.join(BUILD, DEPOT, "vset_judy.scene.json")
    json.dump(d, open(out_json, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    r = subprocess.run([CLI, "convert", "deserialize", out_json],
                       capture_output=True, text=True, errors="replace")
    scene = out_json[:-5]
    if os.path.exists(scene):
        os.remove(out_json)
        print("Szene gebaut: %s (%d KB)"
              % (os.path.relpath(scene, HERE), os.path.getsize(scene) // 1024))
    else:
        print(r.stdout.strip()[-400:] or r.stderr.strip()[-400:])
        raise SystemExit("!! .scene wurde nicht erzeugt")


main()
