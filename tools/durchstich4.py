"""Durchstich 4: einen Vanilla-Eintrag vollstaendig klonen statt nachbauen.

4c hat die Frage entschieden: `cl_zeigt_auf_danger` - ein neuer Name auf `danger`s
vorhandenem Knoten - spielt "Achtung!". **Neue Einstiegspunkte funktionieren.** Der Fehler
liegt also in den Knoten, die ich selbst gebaut habe, nicht in der Registrierung.

Von Hand nachbauen war der falsche Ansatz. Ein Feldvergleich gegen VVF zeigte nur
`visualStyle` und `voContext` als Unterschied - aber das beweist nur, dass die Felder
gleich HEISSEN, nicht dass ich keines uebersehen habe, das gar nicht erst auftaucht.

Deshalb hier: `player_fallback_var_2` tief kopieren - Start-Knoten, Section-Knoten,
Ereignis, Zeile - und ausschliesslich ersetzen, was sich zwangslaeufig unterscheiden muss:

    nodeIds, HandleIds, Ereignis-Id, itemId, Name, ruid, Lipsync-Namen, Dauer

Als Vorlage bewusst eine **Judy**-Zeile und keine von VVF: das kontrolliert zusaetzlich
Actor-Aufbau und Szenen-Konventionen, die bei einem Begleiter anders sein koennen als beim
Spieler.

    python tools/durchstich4.py
"""
import copy
import json
import os
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich4")
DEPOT = "base/quest/secondary_characters/vsets"

TEMPLATE = "player_fallback_var_2"   # direkt, kein Randomizer dazwischen
NAME = "cl_klon"
HEX = "39669188b9a4e000"
TEXT = "Ich bin froh, dass du da bist."
DURATION_MS = int(len(TEXT) / 14.0 * 1000)


def main():
    d = json.load(open(SRC, encoding="utf-8"))
    root = d["Data"]["RootChunk"]
    graph = root["sceneGraph"]["Data"]["graph"]
    lines = root["screenplayStore"]["lines"]
    starts = root["sceneGraph"]["Data"]["startNodes"]
    ds = root["debugSymbols"]

    ep_i = next(i for i, e in enumerate(root["entryPoints"])
                if e["name"]["$value"] == TEMPLATE)
    start_src_id = root["entryPoints"][ep_i]["nodeId"]["id"]

    wrap_start = _wrapper(graph, start_src_id)
    sec_src_id = wrap_start["Data"]["outputSockets"][0]["destinations"][0]["nodeId"]["id"]
    wrap_sec = _wrapper(graph, sec_src_id)
    line_src_id = wrap_sec["Data"]["events"][0]["Data"]["screenplayLineId"]["id"]
    line_src = next(l for l in lines if l["itemId"]["id"] == line_src_id)

    new_node = max(n.get("Data", n)["nodeId"]["id"] for n in graph)
    new_item = max(l["itemId"]["id"] for l in lines) + 1
    new_handle = max(int(x) for x in _all_handles(d))
    sec_id, start_id = new_node + 1, new_node + 2

    #  Zeile: alles uebernehmen, nur Identitaet und Ziel-Audio austauschen.
    line = copy.deepcopy(line_src)
    line["itemId"]["id"] = new_item
    line["locstringId"]["ruid"] = str(int(HEX, 16))
    line["femaleLipsyncAnimationName"]["$value"] = "f_" + HEX.upper()
    line["maleLipsyncAnimationName"]["$value"] = "m_" + HEX.upper()
    lines.append(line)

    #  Section-Knoten samt Ereignis, voParams, Sockets, actorBehaviors, sectionDuration.
    sec = copy.deepcopy(wrap_sec)
    sec["HandleId"] = str(new_handle + 1)
    sec["Data"]["nodeId"]["id"] = sec_id
    ev = sec["Data"]["events"][0]
    ev["HandleId"] = str(new_handle + 2)
    old_event_id = ev["Data"]["id"]["id"]
    new_event_id = str(int(old_event_id) + 7777)
    ev["Data"]["id"]["id"] = new_event_id
    ev["Data"]["screenplayLineId"]["id"] = new_item
    ev["Data"]["duration"] = DURATION_MS
    #  Vorlage traegt sectionDuration = duration + 4900; das Verhaeltnis mituebernehmen,
    #  statt auf +1 zu wechseln - hier soll NUR das Noetige abweichen.
    offset = wrap_sec["Data"]["sectionDuration"]["stu"] - wrap_sec["Data"]["events"][0]["Data"]["duration"]
    sec["Data"]["sectionDuration"]["stu"] = DURATION_MS + offset
    graph.append(sec)

    #  Start-Knoten, umgehaengt auf die neue Section.
    st = copy.deepcopy(wrap_start)
    st["HandleId"] = str(new_handle + 3)
    st["Data"]["nodeId"]["id"] = start_id
    st["Data"]["outputSockets"][0]["destinations"][0]["nodeId"]["id"] = sec_id
    graph.append(st)

    ds["sceneNodesDebugSymbols"].append(_node_symbol(sec_id))
    ds["sceneNodesDebugSymbols"].append(_node_symbol(start_id))
    sym_src = next((s for s in ds["sceneEventsDebugSymbols"]
                    if s["originNodeId"]["id"] == sec_src_id), None)
    if sym_src:
        sym = copy.deepcopy(sym_src)
        sym["originNodeId"]["id"] = sec_id
        sym["sceneEventIds"][0]["id"] = new_event_id
        ds["sceneEventsDebugSymbols"].append(sym)

    root["entryPoints"].append({"$type": "scnEntryPoint", "name": _cname(NAME),
                                "nodeId": {"$type": "scnNodeId", "id": start_id}})
    starts.append({"$type": "scnNodeId", "id": start_id})

    print("Vorlage      : %s  (Start %d -> Section %d, Zeile %d)"
          % (TEMPLATE, start_src_id, sec_src_id, line_src_id))
    print("Klon         : %s  (Start %d -> Section %d, Zeile %d)"
          % (NAME, start_id, sec_id, new_item))
    print("sectionDuration-Versatz aus der Vorlage uebernommen: +%d" % offset)
    print("Einstiege %d = startNodes %d | Knoten %d = Symbole %d | Zeilen %d"
          % (len(root["entryPoints"]), len(starts), len(graph),
             len(ds["sceneNodesDebugSymbols"]), len(lines)))
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


def _wrapper(graph, node_id):
    for n in graph:
        if n.get("Data", n)["nodeId"]["id"] == node_id:
            return n
    raise SystemExit("Knoten %d nicht gefunden" % node_id)


def _node_symbol(i):
    return {"$type": "scnNodeSymbol", "editorEventId": "9223372036854775807",
            "editorNodeId": {"$type": "scnNodeId", "id": i},
            "nodeId": {"$type": "scnNodeId", "id": i}}


def _cname(v):
    return {"$type": "CName", "$storage": "string", "$value": v}


def _all_handles(obj, acc=None):
    if acc is None:
        acc = []
    if isinstance(obj, dict):
        if isinstance(obj.get("HandleId"), str):
            acc.append(obj["HandleId"])
        for v in obj.values():
            _all_handles(v, acc)
    elif isinstance(obj, list):
        for v in obj:
            _all_handles(v, acc)
    return acc


main()
