"""Durchstich 3: zwei Eintraege, mit und ohne voInfo.

Die Testmatrix hat den Suchraum entscheidend verkleinert:

* VVFs neue Eintraege spielen (vfv_better_run, vfv_talk_later auf V)  -> neue Eintraege
  tragen grundsaetzlich
* ein Unsinnsname erzeugt STILLE                                     -> es gibt keinen
  Rueckfall, also loest unser Eintrag auf und landet nur falsch
* beide Negativkontrollen schweigen                                  -> der Dispatcher
  waehlt das Voiceset sauber am Puppet

Der Vergleich mit VVF zeigt dann den einzigen strukturellen Unterschied zu meinem Bau:

    VVF   entryPoints 13012 | startNodes 13012 | voInfo 205

`startNodes` ist parallel zu `entryPoints` - das war richtig. `voInfo` ist es NICHT, und
`vfv_better_run` kommt dort ueberhaupt nicht vor. Mein voInfo-Eintrag war also der einzige
Punkt, an dem ich von einer belegt funktionierenden Erweiterung abgewichen bin.

Dieser Bau legt beide Varianten nebeneinander, damit ein Neustart beide beantwortet:

    cl_mit_voinfo    wie bisher, mit voInfo-Eintrag
    cl_ohne_voinfo   wie VVF, ohne voInfo-Eintrag

    python tools/durchstich3.py
"""
import json
import os
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich3")
DEPOT = "base/quest/secondary_characters/vsets"

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

    state = {
        "node": max(n.get("Data", n)["nodeId"]["id"] for n in graph),
        "item": max(l["itemId"]["id"] for l in lines),
        "handle": max(int(x) for x in _all_handles(d)),
        "event": 2248180971940790000,
    }

    for name, with_voinfo in (("cl_mit_voinfo", True), ("cl_ohne_voinfo", False)):
        _add(root, graph, lines, starts, ds, state, name, with_voinfo)

    #  Trennt neuen EINSTIEGSPUNKT von neuen KNOTEN: dieser Eintrag legt keinen Knoten an,
    #  sondern zeigt auf den vorhandenen Start-Knoten von `danger`. Spielt er "Achtung!",
    #  funktionieren neue Einstiegspunkte und der Fehler liegt an unseren neuen Knoten.
    #  Bleibt er still oder bringt follow_me, tragen neue Einstiegspunkte selbst nicht.
    di = [k for k, e in enumerate(root["entryPoints"])
          if e["name"]["$value"] == "danger"][0]
    danger_node = root["entryPoints"][di]["nodeId"]["id"]
    root["entryPoints"].append({"$type": "scnEntryPoint", "name": _cname("cl_zeigt_auf_danger"),
                                "nodeId": {"$type": "scnNodeId", "id": danger_node}})
    starts.append({"$type": "scnNodeId", "id": danger_node})
    print("%-16s zeigt auf vorhandenen Knoten %d (danger), keine neuen Knoten"
          % ("cl_zeigt_auf_danger", danger_node))

    print("Einstiege %d | startNodes %d | voInfo %d | Knoten %d | Zeilen %d"
          % (len(root["entryPoints"]), len(starts), len(root["voInfo"]),
             len(graph), len(lines)))
    print("  startNodes parallel zu entryPoints:",
          len(starts) == len(root["entryPoints"]))
    print("  voInfo bewusst kuerzer, wie bei VVF:",
          len(root["voInfo"]) < len(root["entryPoints"]))
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


def _add(root, graph, lines, starts, ds, st, name, with_voinfo):
    st["node"] += 1
    sec_id = st["node"]
    st["node"] += 1
    start_id = st["node"]
    st["item"] += 1
    item_id = st["item"]
    st["event"] += 1
    event_id = str(st["event"])
    h_sec = st["handle"] + 1
    h_evt = st["handle"] + 2
    h_start = st["handle"] + 3
    st["handle"] += 3

    lines.append({
        "$type": "scnscreenplayDialogLine",
        "addressee": {"$type": "scnActorId", "id": 0},
        "femaleLipsyncAnimationName": _cname("f_" + HEX.upper()),
        "itemId": {"$type": "scnscreenplayItemId", "id": item_id},
        "locstringId": {"$type": "scnlocLocstringId", "ruid": str(int(HEX, 16))},
        "maleLipsyncAnimationName": _cname("m_" + HEX.upper()),
        "speaker": {"$type": "scnActorId", "id": 0},
        "usage": {"$type": "scnscreenplayLineUsage",
                  "playerGenderMask": {"$type": "scnGenderMask", "mask": 3}},
    })

    graph.append({"HandleId": str(h_sec), "Data": {
        "$type": "scnSectionNode",
        "actorBehaviors": [{"$type": "scnSectionInternalsActorBehavior",
                            "actorId": {"$type": "scnActorId", "id": 0},
                            "behaviorMode": "OnlyIfAlive"}],
        "events": [{"HandleId": str(h_evt), "Data": {
            "$type": "scnDialogLineEvent",
            "additionalSpeakers": {"$type": "scnAdditionalSpeakers", "executionTag": 0,
                                   "role": "Full", "speakers": []},
            "duration": DURATION_MS,
            "executionTagFlags": 0,
            "id": {"$type": "scnSceneEventId", "id": event_id},
            "scalingData": None,
            "screenplayLineId": {"$type": "scnscreenplayItemId", "id": item_id},
            "startTime": 0, "type": "0", "visualStyle": "overHead",
            "voParams": {"$type": "scnDialogLineVoParams", "alwaysUseBrainGender": 0,
                         "customVoEvent": _cname("None"), "disableHeadMovement": 0,
                         "ignoreSpeakerIncapacitation": 0, "isHolocallSpeaker": 0,
                         "voContext": "Vo_Context_Quest",
                         "voExpression": "Vo_Expression_Spoken"}}}],
        "ffStrategy": "automatic", "isFocusClue": 0,
        "nodeId": {"$type": "scnNodeId", "id": sec_id},
        "outputSockets": [_socket(0), _socket(1)],
        "sectionDuration": {"$type": "scnSceneTime", "stu": DURATION_MS + 1},
    }})

    graph.append({"HandleId": str(h_start), "Data": {
        "$type": "scnStartNode", "ffStrategy": "automatic",
        "nodeId": {"$type": "scnNodeId", "id": start_id},
        "outputSockets": [{"$type": "scnOutputSocket", "destinations": [{
            "$type": "scnInputSocketId",
            "isockStamp": {"$type": "scnInputSocketStamp", "name": 0, "ordinal": 0},
            "nodeId": {"$type": "scnNodeId", "id": sec_id}}],
            "stamp": {"$type": "scnOutputSocketStamp", "name": 0, "ordinal": 0}}],
    }})

    ds["sceneNodesDebugSymbols"].append(_node_symbol(sec_id))
    ds["sceneNodesDebugSymbols"].append(_node_symbol(start_id))
    ds["sceneEventsDebugSymbols"].append({
        "$type": "scnSceneEventSymbol",
        "editorEventId": str(268435483 + st["item"]),
        "originNodeId": {"$type": "scnNodeId", "id": sec_id},
        "sceneEventIds": [{"$type": "scnSceneEventId", "id": event_id}],
    })

    root["entryPoints"].append({"$type": "scnEntryPoint", "name": _cname(name),
                                "nodeId": {"$type": "scnNodeId", "id": start_id}})
    starts.append({"$type": "scnNodeId", "id": start_id})

    if with_voinfo:
        root["voInfo"].append({
            "$type": "scnSceneVOInfo",
            "duration": (DURATION_MS + 1) / 1000.0,
            "id": len(root["voInfo"]),
            "inVoTrigger": _cname(name),
            "outVoTrigger": _cname(name),
        })

    print("%-16s nodeIds %d/%d  itemId %d  voInfo %s"
          % (name, sec_id, start_id, item_id, "ja" if with_voinfo else "nein"))


def _node_symbol(i):
    return {"$type": "scnNodeSymbol", "editorEventId": "9223372036854775807",
            "editorNodeId": {"$type": "scnNodeId", "id": i},
            "nodeId": {"$type": "scnNodeId", "id": i}}


def _cname(v):
    return {"$type": "CName", "$storage": "string", "$value": v}


def _socket(name):
    return {"$type": "scnOutputSocket", "destinations": [],
            "stamp": {"$type": "scnOutputSocketStamp", "name": name, "ordinal": 0}}


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
