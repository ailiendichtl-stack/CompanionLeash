"""Durchstich 5: eine GEWOEHNLICHE Bark als Klonvorlage.

Der Klon aus `player_fallback_var_2` blieb mehrdeutig - der Name deutet auf einen
Fallback-Pfad, und das Symptom war selbst eine Fallback-artige Begleiter-Zeile. Die
Vorlage taugt also nicht als Beweis.

`danger_var_1` ist besser: gewoehnliche Bark, direkt vom Start-Knoten auf die Section
(kein Randomizer dazwischen), und Nachlauf +1 statt +4900. Und beide Haelften sind bereits
einzeln belegt:

    neuer Name  -> danger-Knoten  -> spielt          (cl_zeigt_auf_danger)
    danger-Zeile -> fremde ruid   -> spielt          (danger umgebogen)

Dieser Bau kombiniert genau diese beiden bekannten Wege.

**Zeitsteuerung bleibt unveraendert.** Sonst aendern sich drei Dinge gleichzeitig -
Vorlage, ruid und Timing - und ein Fehlschlag waere wieder nicht zuzuordnen. Erst wenn es
spricht, wird die Dauer in einem eigenen Schritt angepasst.

    python tools/durchstich5.py
"""
import copy
import json
import os
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich5")
DEPOT = "base/quest/secondary_characters/vsets"

TEMPLATE = "danger_var_1"
#  Die Datei liegt unter base/localization/de-de/lipsync/<szenenpfad>/<figur>.anims -
#  referenziert wird sie aber NICHT so. Szenen benutzen eine logische Form, in der die
#  Engine Sprache und Lokalisierungspfad selbst einsetzt. Aus der mq055-Szene abgelesen:
#
#      base\quest\minor_quests\mq055\scenes\lipsync\en\mq055_01_megabuilding\judy.anims
#
#  also <szenenordner>\lipsync\en\<szenenname>\<figur>.anims - genau wie Judys Voiceset
#  sein eigenes Set als vsets\lipsync\enset_judy\judy.anims referenziert.
#  Der physische Pfad funktioniert nicht: damit blieb der Mund still.
BS = chr(92)
ANIMS = BS.join(["base", "quest", "minor_quests", "mq055", "scenes", "lipsync", "en",
                 "mq055_01_megabuilding", "judy.anims"])
NAME = "cl_klon_danger"
HEX = "39669188b9a4e000"


def main():
    d = json.load(open(SRC, encoding="utf-8"))
    root = d["Data"]["RootChunk"]
    graph = root["sceneGraph"]["Data"]["graph"]
    lines = root["screenplayStore"]["lines"]
    starts = root["sceneGraph"]["Data"]["startNodes"]
    ds = root["debugSymbols"]

    ep_i = next(i for i, e in enumerate(root["entryPoints"])
                if e["name"]["$value"] == TEMPLATE)
    start_src = root["entryPoints"][ep_i]["nodeId"]["id"]
    w_start = _wrap(graph, start_src)
    sec_src = w_start["Data"]["outputSockets"][0]["destinations"][0]["nodeId"]["id"]
    w_sec = _wrap(graph, sec_src)
    if w_sec["Data"]["$type"] != "scnSectionNode":
        raise SystemExit("Vorlage fuehrt nicht direkt auf eine Section")

    line_src_id = w_sec["Data"]["events"][0]["Data"]["screenplayLineId"]["id"]
    line_src = next(l for l in lines if l["itemId"]["id"] == line_src_id)

    node_max = max(n.get("Data", n)["nodeId"]["id"] for n in graph)
    #  itemId ist KEINE fortlaufende Zahl, sondern strukturiert: alle 55 Vanilla-Ids und
    #  alle 12978 VVF-Ids haben die Form (n << 8) | 1. Meine "naechste freie Zahl" ergab
    #  0x3602 statt 0x3701 und brach damit das Muster - genau deshalb scheiterten neue
    #  ZEILEN, waehrend umgebogene vorhandene funktionierten.
    item_id = ((max(l["itemId"]["id"] for l in lines) >> 8) + 1 << 8) | 1
    h = max(int(x) for x in _all_handles(d))
    sec_id, start_id = node_max + 1, node_max + 2

    line = copy.deepcopy(line_src)
    line["itemId"]["id"] = item_id
    line["locstringId"]["ruid"] = str(int(HEX, 16))
    line["femaleLipsyncAnimationName"]["$value"] = "f_" + HEX.upper()
    line["maleLipsyncAnimationName"]["$value"] = "m_" + HEX.upper()
    lines.append(line)

    sec = copy.deepcopy(w_sec)
    sec["HandleId"] = str(h + 1)
    sec["Data"]["nodeId"]["id"] = sec_id
    ev = sec["Data"]["events"][0]
    ev["HandleId"] = str(h + 2)
    #  Ereignis-Ids sind auf 4 ausgerichtet - in Vanilla wie bei VVF. +7777 ergab 97 in
    #  den unteren Bits und war damit ebenfalls ungueltig.
    new_event_id = str(int(ev["Data"]["id"]["id"]) + 0x1000)
    ev["Data"]["id"]["id"] = new_event_id
    ev["Data"]["screenplayLineId"]["id"] = item_id
    #  duration und sectionDuration bleiben, wie sie in der Vorlage stehen.
    graph.append(sec)

    st = copy.deepcopy(w_start)
    st["HandleId"] = str(h + 3)
    st["Data"]["nodeId"]["id"] = start_id
    st["Data"]["outputSockets"][0]["destinations"][0]["nodeId"]["id"] = sec_id
    graph.append(st)

    ds["sceneNodesDebugSymbols"].append(_sym(sec_id))
    ds["sceneNodesDebugSymbols"].append(_sym(start_id))
    src_sym = next((s for s in ds["sceneEventsDebugSymbols"]
                    if s["originNodeId"]["id"] == sec_src), None)
    if src_sym:
        sym = copy.deepcopy(src_sym)
        sym["originNodeId"]["id"] = sec_id
        sym["sceneEventIds"][0]["id"] = new_event_id
        ds["sceneEventsDebugSymbols"].append(sym)

    root["entryPoints"].append({"$type": "scnEntryPoint", "name": _cn(NAME),
                                "nodeId": {"$type": "scnNodeId", "id": start_id}})
    starts.append({"$type": "scnNodeId", "id": start_id})

    #  Ohne dieses Set spielt die Zeile, aber der Mund bewegt sich nicht - im Spiel
    #  beobachtet: Vorlage mit Lippenbewegung, Klon ohne.
    #  Widerlegt: die Zuordnung ist NICHT positionsgebunden. Mit dem mq055-Set auf Index 0
    #  behielten die Barks ihre Lippenbewegung und der Klon bekam keine. Also wieder
    #  anhaengen - die Referenz schadet nicht, reicht aber allein auch nicht.
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
    print("Anim-Sets: %d, Reihenfolge:" % len(refs))
    for i, r in enumerate(refs):
        print("   [%d] %s" % (i, r["asyncRefLipsyncAnimSet"]["DepotPath"]["$value"].split(BS)[-2:]))

    dur = ev["Data"]["duration"]
    stu = sec["Data"]["sectionDuration"]["stu"]
    print("Vorlage : %s  Start %d -> Section %d  Zeile %d"
          % (TEMPLATE, start_src, sec_src, line_src_id))
    print("Klon    : %s  Start %d -> Section %d  Zeile %d"
          % (NAME, start_id, sec_id, item_id))
    print("Timing  : unveraendert aus der Vorlage - dur %d, section %d (+%d)"
          % (dur, stu, stu - dur))
    print("ruid    : %s" % line["locstringId"]["ruid"])
    print("itemId  : %d = %s  (Muster (n<<8)|1: %s)"
          % (item_id, hex(item_id), "ja" if item_id & 0xFF == 1 else "NEIN"))
    print("EreignId: %s  (auf 4 ausgerichtet: %s)"
          % (hex(int(new_event_id)), "ja" if int(new_event_id) % 4 == 0 else "NEIN"))
    print("Einstiege %d = startNodes %d | Knoten %d = Symbole %d"
          % (len(root["entryPoints"]), len(starts), len(graph),
             len(ds["sceneNodesDebugSymbols"])))
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


def _wrap(graph, nid):
    for n in graph:
        if n.get("Data", n)["nodeId"]["id"] == nid:
            return n
    raise SystemExit("Knoten %d fehlt" % nid)


def _sym(i):
    return {"$type": "scnNodeSymbol", "editorEventId": "9223372036854775807",
            "editorNodeId": {"$type": "scnNodeId", "id": i},
            "nodeId": {"$type": "scnNodeId", "id": i}}


def _cn(v):
    return {"$type": "CName", "$storage": "string", "$value": v}


def _all_handles(o, acc=None):
    if acc is None:
        acc = []
    if isinstance(o, dict):
        if isinstance(o.get("HandleId"), str):
            acc.append(o["HandleId"])
        for v in o.values():
            _all_handles(v, acc)
    elif isinstance(o, list):
        for v in o:
            _all_handles(v, acc)
    return acc


main()
