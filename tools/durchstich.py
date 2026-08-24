"""Durchstich: EINE zusaetzliche Zeile in Judys Voiceset.

Bevor 1104 Eintraege gebaut werden, muss eine einzige beweisen, dass der Dispatcher zur
Laufzeit auch wirklich aufloest. Ein verlustfreier JSON-Rundweg beweist das gerade NICHT -
die Struktur kann syntaktisch gueltig und trotzdem nicht abspielbar sein. Offene Fragen,
die nur das Spiel beantwortet:

* loest der neue Name ueber den Quest-Voiceset-Knoten ueberhaupt auf
* wird die zugehoerige .wem aus dem Sprach-Archiv geladen
* startet `lipsyncAnimSet` auch aus unserem Dispatcher, nicht nur im Szenenkontext
* braucht das Dialogline-Event Metadaten, die im JSON-Vergleich unauffaellig sind

Gebaut wird die Zeile "Ich bin froh, dass du da bist." aus mq055 - unverwechselbar, sicher
Judy, nicht im Voiceset.

    python tools/durchstich.py
"""
import json
import os
import shutil
import subprocess

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
SRC = os.path.join(HERE, "data", "scene_json", "vset_judy.scene.json")
BUILD = os.path.join(HERE, "build", "durchstich")
DEPOT = "base/quest/secondary_characters/vsets"

#  Die Testzeile. hex ist zugleich stringId und Dateiname-Suffix - genau das ist der
#  Zusammenhang, den der Durchstich pruefen soll.
NAME = "cl_test_froh"
HEX = "39669188b9a4e000"
TEXT = "Ich bin froh, dass du da bist."
#  Geschaetzt, nicht gemessen: rund 14 Zeichen je Sekunde. Fuer den Durchstich reicht das -
#  eine falsche Dauer aeussert sich als zu frueher Schnitt, nicht als Nicht-Auflösung, und
#  ist damit vom eigentlichen Testziel unterscheidbar.
DURATION_MS = int(len(TEXT) / 14.0 * 1000)


def main():
    d = json.load(open(SRC, encoding="utf-8"))
    root = d["Data"]["RootChunk"]
    graph = root["sceneGraph"]["Data"]["graph"]
    lines = root["screenplayStore"]["lines"]

    node_ids = [n.get("Data", n)["nodeId"]["id"] for n in graph]
    item_ids = [l["itemId"]["id"] for l in lines]
    handles = [int(x) for x in _all_handles(d)]

    sec_id = max(node_ids) + 1
    start_id = sec_id + 1
    item_id = max(item_ids) + 1
    h_sec = max(handles) + 1
    h_evt = h_sec + 1
    h_start = h_evt + 1

    ruid = str(int(HEX, 16))

    #  1. Die Zeile selbst. locstringId.ruid ist dezimal der Hex aus dem Dateinamen, die
    #     Lipsync-Namen sind f_<hex> / m_<hex> - an allen 55 Vanilla-Zeilen geprueft.
    lines.append({
        "$type": "scnscreenplayDialogLine",
        "addressee": {"$type": "scnActorId", "id": 0},
        "femaleLipsyncAnimationName": _cname("f_" + HEX.upper()),
        "itemId": {"$type": "scnscreenplayItemId", "id": item_id},
        "locstringId": {"$type": "scnlocLocstringId", "ruid": ruid},
        "maleLipsyncAnimationName": _cname("m_" + HEX.upper()),
        "speaker": {"$type": "scnActorId", "id": 0},
        "usage": {"$type": "scnscreenplayLineUsage",
                  "playerGenderMask": {"$type": "scnGenderMask", "mask": 3}},
    })

    #  2. Section-Knoten mit dem Dialogline-Event.
    #     sectionDuration ist in der Vanilla-Szene entweder duration+1 oder duration+4900;
    #     +1 ist die Variante ohne Nachlauf.
    graph.append({
        "HandleId": str(h_sec),
        "Data": {
            "$type": "scnSectionNode",
            "actorBehaviors": [{
                "$type": "scnSectionInternalsActorBehavior",
                "actorId": {"$type": "scnActorId", "id": 0},
                "behaviorMode": "OnlyIfAlive",
            }],
            "events": [{
                "HandleId": str(h_evt),
                "Data": {
                    "$type": "scnDialogLineEvent",
                    "additionalSpeakers": {"$type": "scnAdditionalSpeakers",
                                           "executionTag": 0, "role": "Full",
                                           "speakers": []},
                    "duration": DURATION_MS,
                    "executionTagFlags": 0,
                    "id": {"$type": "scnSceneEventId", "id": str(2248180971940790000 + 1)},
                    "scalingData": None,
                    "screenplayLineId": {"$type": "scnscreenplayItemId", "id": item_id},
                    "startTime": 0,
                    "type": "0",
                    "visualStyle": "overHead",
                    "voParams": {
                        "$type": "scnDialogLineVoParams",
                        "alwaysUseBrainGender": 0,
                        "customVoEvent": _cname("None"),
                        "disableHeadMovement": 0,
                        "ignoreSpeakerIncapacitation": 0,
                        "isHolocallSpeaker": 0,
                        "voContext": "Vo_Context_Quest",
                        "voExpression": "Vo_Expression_Spoken",
                    },
                },
            }],
            "ffStrategy": "automatic",
            "isFocusClue": 0,
            "nodeId": {"$type": "scnNodeId", "id": sec_id},
            "outputSockets": [
                _socket(0), _socket(1),
            ],
            "sectionDuration": {"$type": "scnSceneTime", "stu": DURATION_MS + 1},
        },
    })

    #  3. Start-Knoten, der auf die Section zeigt.
    graph.append({
        "HandleId": str(h_start),
        "Data": {
            "$type": "scnStartNode",
            "ffStrategy": "automatic",
            "nodeId": {"$type": "scnNodeId", "id": start_id},
            "outputSockets": [{
                "$type": "scnOutputSocket",
                "destinations": [{
                    "$type": "scnInputSocketId",
                    "isockStamp": {"$type": "scnInputSocketStamp", "name": 0, "ordinal": 0},
                    "nodeId": {"$type": "scnNodeId", "id": sec_id},
                }],
                "stamp": {"$type": "scnOutputSocketStamp", "name": 0, "ordinal": 0},
            }],
        },
    })

    #  4. Debug-Symbole. NICHT optional: sceneNodesDebugSymbols hat in jeder Szene genau
    #     so viele Eintraege wie der Graph Knoten, sceneEventsDebugSymbols genau so viele
    #     wie es Dialogzeilen-Ereignisse gibt. Beim ersten Versuch fehlten sie, und die
    #     Namensaufloesung landete daraufhin auf fremden Zeilen - die Engine scheint ueber
    #     diese Listen zu indizieren. VVF fuehrt sie ebenfalls mit: 26036 Knotensymbole bei
    #     26036 Knoten.
    ds = root["debugSymbols"]
    ds["sceneNodesDebugSymbols"].append(_node_symbol(sec_id))
    ds["sceneNodesDebugSymbols"].append(_node_symbol(start_id))
    ds["sceneEventsDebugSymbols"].append({
        "$type": "scnSceneEventSymbol",
        "editorEventId": str(268435483 + 9000),
        "originNodeId": {"$type": "scnNodeId", "id": sec_id},
        "sceneEventIds": [{"$type": "scnSceneEventId", "id": str(2248180971940790000 + 1)}],
    })

    #  5. Der Einstiegspunkt - das ist der Name, den voicesetName spaeter erwartet.
    root["entryPoints"].append({
        "$type": "scnEntryPoint",
        "name": _cname(NAME),
        "nodeId": {"$type": "scnNodeId", "id": start_id},
    })

    os.makedirs(os.path.join(BUILD, DEPOT), exist_ok=True)
    out_json = os.path.join(BUILD, DEPOT, "vset_judy.scene.json")
    json.dump(d, open(out_json, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print("Eintrag      : %s" % NAME)
    print("stringId     : %s  (0x%s)" % (ruid, HEX))
    print("Text         : %s" % TEXT)
    print("Dauer        : %d ms (geschaetzt)" % DURATION_MS)
    print("itemId       : %d   nodeIds: %d/%d   Handles: %d/%d/%d"
          % (item_id, sec_id, start_id, h_sec, h_evt, h_start))
    print("Knoten %d = Knotensymbole %d | Ereignissymbole %d = Zeilen %d"
          % (len(graph), len(ds["sceneNodesDebugSymbols"]),
             len(ds["sceneEventsDebugSymbols"]), len(lines)))
    print()

    r = subprocess.run([CLI, "convert", "deserialize", out_json], capture_output=True,
                       text=True, errors="replace")
    print(r.stdout.strip()[-400:] or r.stderr.strip()[-400:])
    scene = out_json[:-5]
    if os.path.exists(scene):
        print("Szene gebaut : %s (%d KB)" % (os.path.relpath(scene, HERE),
                                             os.path.getsize(scene) // 1024))
        os.remove(out_json)
    else:
        print("!! .scene wurde nicht erzeugt")


def _node_symbol(node_id):
    return {
        "$type": "scnNodeSymbol",
        "editorEventId": "9223372036854775807",
        "editorNodeId": {"$type": "scnNodeId", "id": node_id},
        "nodeId": {"$type": "scnNodeId", "id": node_id},
    }


def _cname(v):
    return {"$type": "CName", "$storage": "string", "$value": v}


def _socket(name):
    return {"$type": "scnOutputSocket", "destinations": [],
            "stamp": {"$type": "scnOutputSocketStamp", "name": name, "ordinal": 0}}


def _all_handles(obj, acc=None):
    if acc is None:
        acc = []
    if isinstance(obj, dict):
        if "HandleId" in obj and isinstance(obj["HandleId"], str):
            acc.append(obj["HandleId"])
        for v in obj.values():
            _all_handles(v, acc)
    elif isinstance(obj, list):
        for v in obj:
            _all_handles(v, acc)
    return acc


main()
