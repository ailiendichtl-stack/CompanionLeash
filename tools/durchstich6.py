"""Durchstich 6: kann ein FUNKTIONIERENDER Eintrag mit einer fremden Animation animieren?

Der vorherige Test war ein Fehlschluss. Das mq055-Set auf Index 0 zu legen sagte nichts
ueber seine Ladbarkeit aus: die Barks fragten weiter nach `f_18EEC...`, was in diesem Set
gar nicht liegt, und unsere Zeile lief ueber einen neu gebauten Pfad mit einem halben
Dutzend weiterer Variablen. Beide Ergebnisse waren damit erwartbar, egal ob das Set geladen
wird oder nicht.

Dieser Bau stellt eine einzige binaere Frage:

    Kann ein bereits funktionierender Judy-Eintrag den Mund mit einer FREMDEN
    mq055-Animation bewegen?

Dafuer wird an `danger_var_1` **nur** der Lipsync-Name getauscht - Knoten, Ereignis,
Timing, Audio-ruid, Sprecher und der ganze Rest bleiben. Ton und Mundbild passen dann
absichtlich nicht zueinander; das ist hier egal.

Was der Test ausschliesst, weil nichts davon vorkommt: neue itemIds, neue Ereignis-Ids,
neue Knoten, neue Einstiegspunkte, Erreichbarkeit, Dauer-Abweichung.

    danger_var_1 bewegt den Mund  -> das Set laedt, die fremde Animation loest auf;
                                     das Problem sitzt allein im neuen Eintragspfad
    danger_var_1 bleibt stumm     -> das Set wird zur Laufzeit gar nicht herangezogen

    python tools/durchstich6.py
"""
import json
import os
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich6")
DEPOT = "base/quest/secondary_characters/vsets"

TARGET = "danger_var_1"
HEX = "39669188B9A4E000"          # liegt in mq055_01_megabuilding/judy.anims
BS = chr(92)
ANIMS = BS.join(["base", "quest", "minor_quests", "mq055", "scenes", "lipsync", "en",
                 "mq055_01_megabuilding", "judy.anims"])


def main():
    d = json.load(open(SRC, encoding="utf-8"))
    root = d["Data"]["RootChunk"]
    graph = root["sceneGraph"]["Data"]["graph"]
    lines = root["screenplayStore"]["lines"]

    ep = next(e for e in root["entryPoints"] if e["name"]["$value"] == TARGET)
    start = _node(graph, ep["nodeId"]["id"])
    sec = _node(graph, start["outputSockets"][0]["destinations"][0]["nodeId"]["id"])
    line_id = sec["events"][0]["Data"]["screenplayLineId"]["id"]
    line = next(l for l in lines if l["itemId"]["id"] == line_id)

    before_f = line["femaleLipsyncAnimationName"]["$value"]
    before_m = line["maleLipsyncAnimationName"]["$value"]
    line["femaleLipsyncAnimationName"]["$value"] = "f_" + HEX
    line["maleLipsyncAnimationName"]["$value"] = "m_" + HEX

    refs = root["resouresReferences"]["lipsyncAnimSets"]
    if not any(r["asyncRefLipsyncAnimSet"]["DepotPath"]["$value"] == ANIMS for r in refs):
        refs.append({
            "$type": "scnLipsyncAnimSetSRRef",
            "asyncRefLipsyncAnimSet": {
                "DepotPath": {"$type": "ResourcePath", "$storage": "string",
                              "$value": ANIMS},
                "Flags": "Soft"},
            "lipsyncAnimSet": {
                "DepotPath": {"$type": "ResourcePath", "$storage": "uint64",
                              "$value": "0"},
                "Flags": "Default"},
        })

    print("Geaendert: %s, Zeile itemId %d" % (TARGET, line_id))
    print("   Lipsync  %s -> %s" % (before_f, line["femaleLipsyncAnimationName"]["$value"]))
    print("            %s -> %s" % (before_m, line["maleLipsyncAnimationName"]["$value"]))
    print("   Audio-ruid unveraendert: %s" % line["locstringId"]["ruid"])
    print("   Ton und Mundbild passen absichtlich nicht zusammen.")
    print()
    print("Unveraendert: Knoten %d, Zeilen %d, Einstiege %d"
          % (len(graph), len(lines), len(root["entryPoints"])))
    print("Anim-Sets: %d" % len(refs))
    for i, r in enumerate(refs):
        print("   [%d] %s" % (i, BS.join(
            r["asyncRefLipsyncAnimSet"]["DepotPath"]["$value"].split(BS)[-2:])))
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
