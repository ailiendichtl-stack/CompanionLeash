"""Durchstich 7: den vorhandenen Anim-Set-Slot ERSETZEN statt einen zweiten anzuhaengen.

Der letzte Test hat gezeigt, dass ein **zusaetzlich** eingetragenes Set wirkungslos bleibt.
Daraus zu schliessen, Referenzen wirkten grundsaetzlich nicht, war voreilig: die Laufzeit
koennte an den urspruenglichen Slot gebunden sein und schlicht dessen Inhalt laden. Anhaengen
und Ersetzen sind dann zwei verschiedene Dinge, und Ersetzen habe ich nie geprueft.

Dieser Bau haelt genau **einen** Eintrag in `lipsyncAnimSets` und tauscht dessen Pfad:

    vorher:  base\\quest\\secondary_characters\\vsets\\lipsync\\en\\vset_judy\\judy.anims
    nachher: base\\quest\\minor_quests\\mq055\\scenes\\lipsync\\en\\
             mq055_01_megabuilding\\judy.anims

Dazu zeigt `danger_var_1` - ein funktionierender Eintrag, sonst voellig unveraendert - auf
die fremde Animation. Nichts sonst wird angefasst: Knoten, Ereignis-Id, itemId, Timing,
Audio-ruid, Actor, Acquisition.

    danger_var_1 bewegt den Mund  -> die Laufzeit folgt dem Slot. Ein zusammengefuehrtes
                                     judy.anims ist die Loesung fuer echtes Lipsync.
    danger_var_1 bleibt stumm     -> die Bindung sitzt tiefer als die sichtbare Referenz.

Erwartete Nebenwirkung: die Barks verlieren ihre Lippenbewegung, weil ihr Set nicht mehr
eingetragen ist. Das ist ein Teil des Ergebnisses, kein Schaden - und macht zugleich
sichtbar, ob der Slot ueberhaupt gelesen wird.

    python tools/durchstich7.py
"""
import json
import os
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich7")
DEPOT = "base/quest/secondary_characters/vsets"

TARGET = "danger_var_1"
HEX = "39669188B9A4E000"
BS = chr(92)
ANIMS = BS.join(["base", "quest", "minor_quests", "mq055", "scenes", "lipsync", "en",
                 "mq055_01_megabuilding", "judy.anims"])


def main():
    d = json.load(open(SRC, encoding="utf-8"))
    root = d["Data"]["RootChunk"]
    graph = root["sceneGraph"]["Data"]["graph"]
    lines = root["screenplayStore"]["lines"]

    refs = root["resouresReferences"]["lipsyncAnimSets"]
    if len(refs) != 1:
        raise SystemExit("Erwartet genau einen Slot, gefunden: %d" % len(refs))
    before_path = refs[0]["asyncRefLipsyncAnimSet"]["DepotPath"]["$value"]
    refs[0]["asyncRefLipsyncAnimSet"]["DepotPath"]["$value"] = ANIMS

    ep = next(e for e in root["entryPoints"] if e["name"]["$value"] == TARGET)
    start = _node(graph, ep["nodeId"]["id"])
    sec = _node(graph, start["outputSockets"][0]["destinations"][0]["nodeId"]["id"])
    line_id = sec["events"][0]["Data"]["screenplayLineId"]["id"]
    line = next(l for l in lines if l["itemId"]["id"] == line_id)

    before_f = line["femaleLipsyncAnimationName"]["$value"]
    line["femaleLipsyncAnimationName"]["$value"] = "f_" + HEX
    line["maleLipsyncAnimationName"]["$value"] = "m_" + HEX

    print("Slot 0 ersetzt (weiterhin genau %d Eintrag):" % len(refs))
    print("   vorher : %s" % BS.join(before_path.split(BS)[-2:]))
    print("   nachher: %s" % BS.join(ANIMS.split(BS)[-2:]))
    print()
    print("%s, Zeile itemId %d:" % (TARGET, line_id))
    print("   Lipsync %s -> %s" % (before_f, line["femaleLipsyncAnimationName"]["$value"]))
    print("   Audio-ruid unveraendert: %s" % line["locstringId"]["ruid"])
    print()
    print("Sonst unveraendert: Knoten %d, Zeilen %d, Einstiege %d"
          % (len(graph), len(lines), len(root["entryPoints"])))
    print("Erwartet: die Barks verlieren ihre Lippenbewegung - Teil des Ergebnisses.")
    print()

    os.makedirs(os.path.join(BUILD, DEPOT), exist_ok=True)
    out = os.path.join(BUILD, DEPOT, "vset_judy.scene.json")
    json.dump(d, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    r = subprocess.run([CLI, "convert", "deserialize", out],
                       capture_output=True, text=True, errors="replace")
    scene = out[:-5]
    if os.path.exists(scene):
        os.remove(out)
        print("Szene gebaut: %s (%d KB)"
              % (os.path.relpath(scene, HERE), os.path.getsize(scene) // 1024))
    else:
        print(r.stdout.strip()[-400:] or r.stderr.strip()[-400:])
        raise SystemExit("!! .scene wurde nicht erzeugt")


def _node(graph, nid):
    for n in graph:
        nd = n.get("Data", n)
        if nd["nodeId"]["id"] == nid:
            return nd
    raise SystemExit("Knoten %d fehlt" % nid)


main()
