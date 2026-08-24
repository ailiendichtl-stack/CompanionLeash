"""Durchstich 8: das Anim-Set am KONVENTIONSPFAD ueberschreiben.

Slot 0 zu ersetzen aenderte nichts - und das ist die aufschlussreichste Beobachtung
bisher: die Barks bewegten den Mund weiter, obwohl ihr Set nicht mehr referenziert war.

Die Laufzeit liest `resouresReferences.lipsyncAnimSets` also gar nicht. Sie leitet den
Pfad offenbar aus dem Szenennamen ab:

    Szene    base/quest/secondary_characters/vsets/vset_judy.scene
    Lipsync  base/localization/<lang>/lipsync/base/quest/secondary_characters/vsets/
             vset_judy/<figur>.anims

Das passt zu allem: mq055s Szene liegt unter .../mq055/scenes/mq055_01_megabuilding.scene,
ihre Animationen unter .../lipsync/base/quest/minor_quests/mq055/scenes/
mq055_01_megabuilding/judy.anims. Und es erklaert, warum die Referenz in der Szene das
Wort `en` traegt, obwohl die Dateien unter `de-de` liegen: sie ist Metadaten fuer den
Editor, kein Ladepfad.

Test: das mq055-Set an Judys Konventionspfad legen. Die Szene selbst bleibt dabei
unveraendert bis auf den Lipsync-Namen an `danger_var_1`.

    danger_var_1 bewegt sich, Barks nicht mehr  -> Konvention bestaetigt. Dann ist die
        Loesung, ein zusammengefuehrtes judy.anims an genau diesen Pfad zu legen.
    nichts aendert sich                          -> auch die Datei wird nicht von dort
        geladen, und der Ladepfad liegt woanders.

    python tools/durchstich8.py
"""
import json
import os
import shutil
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich8")

SCENE_DEPOT = "base/quest/secondary_characters/vsets"
#  Konventionspfad, abgeleitet aus dem Szenenpfad - genau so liegt die Vanilla-Datei.
ANIM_DEPOT = ("base/localization/de-de/lipsync/base/quest/secondary_characters/"
              "vsets/vset_judy")

TARGET = "danger_var_1"
HEX = "39669188B9A4E000"


def main():
    src_anims = _find("mq055_01_megabuilding/judy.anims")
    van_anims = _find("vset_judy/judy.anims")
    print("Quelle : %s (%d KB)" % (os.path.basename(src_anims),
                                   os.path.getsize(src_anims) // 1024))
    print("Vanilla: %s (%d KB)" % (os.path.basename(van_anims),
                                   os.path.getsize(van_anims) // 1024))

    #  Szene: nur der Lipsync-Name an danger_var_1, sonst nichts.
    d = json.load(open(SRC, encoding="utf-8"))
    root = d["Data"]["RootChunk"]
    graph = root["sceneGraph"]["Data"]["graph"]
    lines = root["screenplayStore"]["lines"]
    ep = next(e for e in root["entryPoints"] if e["name"]["$value"] == TARGET)
    start = _node(graph, ep["nodeId"]["id"])
    sec = _node(graph, start["outputSockets"][0]["destinations"][0]["nodeId"]["id"])
    line_id = sec["events"][0]["Data"]["screenplayLineId"]["id"]
    line = next(l for l in lines if l["itemId"]["id"] == line_id)
    before = line["femaleLipsyncAnimationName"]["$value"]
    line["femaleLipsyncAnimationName"]["$value"] = "f_" + HEX
    line["maleLipsyncAnimationName"]["$value"] = "m_" + HEX

    refs = root["resouresReferences"]["lipsyncAnimSets"]
    print("Szene: %d Anim-Set-Referenz(en), unveraendert gelassen" % len(refs))
    print("%s: Lipsync %s -> f_%s" % (TARGET, before, HEX))
    print()

    os.makedirs(os.path.join(BUILD, SCENE_DEPOT), exist_ok=True)
    out = os.path.join(BUILD, SCENE_DEPOT, "vset_judy.scene.json")
    json.dump(d, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    subprocess.run([CLI, "convert", "deserialize", out],
                   capture_output=True, text=True, errors="replace")
    if not os.path.exists(out[:-5]):
        raise SystemExit("!! .scene wurde nicht erzeugt")
    os.remove(out)

    #  Das fremde Set an Judys Konventionspfad legen.
    dst_dir = os.path.join(BUILD, *ANIM_DEPOT.split("/"))
    os.makedirs(dst_dir, exist_ok=True)
    shutil.copyfile(src_anims, os.path.join(dst_dir, "judy.anims"))
    print("Ueberschrieben: %s/judy.anims" % ANIM_DEPOT)
    print("   mit dem Inhalt von mq055_01_megabuilding")
    print()
    for root_dir, _, files in os.walk(BUILD):
        for f in files:
            p = os.path.join(root_dir, f)
            print("   %-84s %6d KB" % (os.path.relpath(p, BUILD), os.path.getsize(p) // 1024))


def _find(tail):
    import glob
    hits = glob.glob(os.path.join(HERE, "data", "lipsync", "**", *tail.split("/")),
                     recursive=True)
    if not hits:
        raise SystemExit("nicht gefunden: %s" % tail)
    return hits[0]


def _node(graph, nid):
    for n in graph:
        nd = n.get("Data", n)
        if nd["nodeId"]["id"] == nid:
            return nd
    raise SystemExit("Knoten %d fehlt" % nid)


main()
