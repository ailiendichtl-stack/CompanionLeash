"""Baut Voiceset-Eintraege fuer beliebig viele Judy-Zeilen, samt Lipsync.

Das ist die Verallgemeinerung der Durchstiche. Pro Zeile entstehen:

* eine `scnscreenplayDialogLine` mit ruid und Lipsync-Namen
* ein `scnSectionNode` mit `scnDialogLineEvent` und der ECHTEN Dauer aus der Herkunftsszene
* ein `scnStartNode`
* Eintraege in `entryPoints` UND `sceneGraph.Data.startNodes` (parallel!)
* Debug-Symbole je Knoten und Ereignis

Alles per Tiefkopie einer vorhandenen, direkten Bark - von Hand nachbauen scheitert an
Feldern, die man nicht sieht.

Zwei Id-Muster sind zwingend, sonst loest der Eintrag auf und spielt eine FREMDE Zeile:

    itemId        (n << 8) | 1
    Ereignis-Id   Vielfaches von 4

Dazu wird ein `judy.anims` erzeugt, das die 55 Bark-Animationen und die Animationen aller
gewuenschten Zeilen enthaelt. Die Laufzeit laedt es nicht ueber die Szenenreferenz, sondern
ueber einen aus dem Szenenpfad abgeleiteten Konventionspfad.

    python tools/build_lines.py            # baut die Testauswahl unten
"""
import copy
import glob
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
BUILD = os.path.join(HERE, "build", "lines")
SCENE_DEPOT = "base/quest/secondary_characters/vsets"
ANIM_DEPOT = ("base/localization/de-de/lipsync/base/quest/secondary_characters/"
              "vsets/vset_judy")
TEMPLATE = "danger_var_1"     # direkt, kein Randomizer, Nachlauf +1

#  (Eintragsname, stringId als Hex) - bewusst drei Laengen aus drei Szenen, um das
#  beobachtete Delay einzugrenzen: es blieb auch mit korrekter Dauer bestehen.
WANTED = [
    ("cl_froh",   "39669188b9a4e000"),   # 2922 ms, mq055_01_megabuilding
    ("cl_kurz",   "1812474b462b6000"),   # 2502 ms, q105_06c_finding_studio
    ("cl_lang",   "18795a0a822fc000"),   # 5005 ms, sq030_11_morning
]


def main():
    durations = json.load(open(os.path.join(HERE, "data", "durations.json"),
                               encoding="utf-8"))
    scene_paths = _scene_paths()

    dst = json.load(open(os.path.join(HERE, "data", "scene_json",
                                      "vset_judy.scene.json"), encoding="utf-8"))
    root = dst["Data"]["RootChunk"]

    #  Zustand ueber alle Eintraege hinweg, damit Ids eindeutig bleiben.
    st = {
        "node": max(n.get("Data", n)["nodeId"]["id"]
                    for n in root["sceneGraph"]["Data"]["graph"]),
        "item": max(l["itemId"]["id"] for l in root["screenplayStore"]["lines"]),
        "handle": _max_handle(dst),
    }

    anims_needed = {}   # Szene -> Menge der Animationsnamen
    for name, hexid in WANTED:
        rec = durations.get(str(int(hexid, 16)))
        if not rec:
            print("!! keine Dauer bekannt: %s" % name)
            continue
        _add_entry(root, st, name, hexid, rec["dur"])
        anims_needed.setdefault(rec["scene"], set()).add("f_" + hexid.upper())
        print("  %-10s %-18s %5d ms  aus %s" % (name, hexid, rec["dur"], rec["scene"]))

    print()
    print("Einstiege %d = startNodes %d | Knoten %d = Symbole %d | Zeilen %d"
          % (len(root["entryPoints"]),
             len(root["sceneGraph"]["Data"]["startNodes"]),
             len(root["sceneGraph"]["Data"]["graph"]),
             len(root["debugSymbols"]["sceneNodesDebugSymbols"]),
             len(root["screenplayStore"]["lines"])))

    os.makedirs(os.path.join(BUILD, *SCENE_DEPOT.split("/")), exist_ok=True)
    out = os.path.join(BUILD, *SCENE_DEPOT.split("/"), "vset_judy.scene.json")
    json.dump(dst, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    _run([CLI, "convert", "deserialize", out])
    if not os.path.exists(out[:-5]):
        raise SystemExit("!! Szene nicht erzeugt")
    os.remove(out)
    print("Szene gebaut.")

    _build_anims(anims_needed, scene_paths)

    print()
    for r, _, fs in os.walk(BUILD):
        for f in fs:
            p = os.path.join(r, f)
            print("   %-92s %6d KB" % (os.path.relpath(p, BUILD),
                                       os.path.getsize(p) // 1024))


def _add_entry(root, st, name, hexid, duration):
    graph = root["sceneGraph"]["Data"]["graph"]
    lines = root["screenplayStore"]["lines"]
    starts = root["sceneGraph"]["Data"]["startNodes"]
    ds = root["debugSymbols"]

    ep = next(e for e in root["entryPoints"] if e["name"]["$value"] == TEMPLATE)
    w_start = _wrap(graph, ep["nodeId"]["id"])
    sec_src = w_start["Data"]["outputSockets"][0]["destinations"][0]["nodeId"]["id"]
    w_sec = _wrap(graph, sec_src)
    line_src = next(l for l in lines
                    if l["itemId"]["id"] == w_sec["Data"]["events"][0]["Data"]
                    ["screenplayLineId"]["id"])

    st["node"] += 1
    sec_id = st["node"]
    st["node"] += 1
    start_id = st["node"]
    #  (n << 8) | 1 - jede Vanilla- und jede VVF-Id hat diese Form.
    st["item"] = ((st["item"] >> 8) + 1 << 8) | 1
    item_id = st["item"]

    line = copy.deepcopy(line_src)
    line["itemId"]["id"] = item_id
    line["locstringId"]["ruid"] = str(int(hexid, 16))
    line["femaleLipsyncAnimationName"]["$value"] = "f_" + hexid.upper()
    line["maleLipsyncAnimationName"]["$value"] = "m_" + hexid.upper()
    lines.append(line)

    sec = copy.deepcopy(w_sec)
    st["handle"] += 1
    sec["HandleId"] = str(st["handle"])
    sec["Data"]["nodeId"]["id"] = sec_id
    ev = sec["Data"]["events"][0]
    st["handle"] += 1
    ev["HandleId"] = str(st["handle"])
    #  Ereignis-Ids sind auf 4 ausgerichtet.
    event_id = str(int(ev["Data"]["id"]["id"]) + 0x1000 * (item_id >> 8))
    ev["Data"]["id"]["id"] = event_id
    ev["Data"]["screenplayLineId"]["id"] = item_id
    tail = sec["Data"]["sectionDuration"]["stu"] - ev["Data"]["duration"]
    ev["Data"]["duration"] = duration
    sec["Data"]["sectionDuration"]["stu"] = duration + tail
    graph.append(sec)

    start = copy.deepcopy(w_start)
    st["handle"] += 1
    start["HandleId"] = str(st["handle"])
    start["Data"]["nodeId"]["id"] = start_id
    start["Data"]["outputSockets"][0]["destinations"][0]["nodeId"]["id"] = sec_id
    graph.append(start)

    for nid in (sec_id, start_id):
        ds["sceneNodesDebugSymbols"].append({
            "$type": "scnNodeSymbol", "editorEventId": "9223372036854775807",
            "editorNodeId": {"$type": "scnNodeId", "id": nid},
            "nodeId": {"$type": "scnNodeId", "id": nid}})
    src_sym = next((s for s in ds["sceneEventsDebugSymbols"]
                    if s["originNodeId"]["id"] == sec_src), None)
    if src_sym:
        sym = copy.deepcopy(src_sym)
        sym["originNodeId"]["id"] = sec_id
        sym["sceneEventIds"][0]["id"] = event_id
        ds["sceneEventsDebugSymbols"].append(sym)

    root["entryPoints"].append({
        "$type": "scnEntryPoint",
        "name": {"$type": "CName", "$storage": "string", "$value": name},
        "nodeId": {"$type": "scnNodeId", "id": start_id}})
    starts.append({"$type": "scnNodeId", "id": start_id})


def _build_anims(needed, scene_paths):
    van = _find_anims("vset_judy")
    work = os.path.join(HERE, "build", "lines_anim")
    if os.path.exists(work):
        import shutil
        shutil.rmtree(work)
    os.makedirs(work)
    _run([CLI, "convert", "serialize", van, "-o", work])
    target = os.path.join(work, "judy.anims.json")

    for scene, names in needed.items():
        src = _find_anims(scene)
        if not src:
            print("!! kein Anim-Set fuer %s" % scene)
            continue
        sub = os.path.join(work, scene)
        os.makedirs(sub, exist_ok=True)
        _run([CLI, "convert", "serialize", src, "-o", sub])
        _run([sys.executable, os.path.join(HERE, "tools", "merge_anims.py"),
              target, os.path.join(sub, "judy.anims.json")] + sorted(names))
        merged = target.replace(".json", ".merged.json")
        if os.path.exists(merged):
            os.replace(merged, target)

    _run([CLI, "convert", "deserialize", target])
    built = target[:-5]
    if not os.path.exists(built):
        raise SystemExit("!! judy.anims nicht erzeugt")
    dst_dir = os.path.join(BUILD, *ANIM_DEPOT.split("/"))
    os.makedirs(dst_dir, exist_ok=True)
    import shutil
    shutil.copyfile(built, os.path.join(dst_dir, "judy.anims"))
    print("judy.anims gebaut.")


def _find_anims(scene):
    hits = glob.glob(os.path.join(HERE, "data", "lipsync", "**", scene, "judy.anims"),
                     recursive=True)
    return hits[0] if hits else None


def _scene_paths():
    out = {}
    for p in glob.glob(os.path.join(HERE, "data", "scenes", "**", "*.scene"),
                       recursive=True):
        if os.sep + "versions" + os.sep in p:
            continue
        out[os.path.basename(p).replace(".scene", "")] = p
    return out


def _wrap(graph, nid):
    for n in graph:
        if n.get("Data", n)["nodeId"]["id"] == nid:
            return n
    raise SystemExit("Knoten %d fehlt" % nid)


def _max_handle(o, cur=0):
    if isinstance(o, dict):
        h = o.get("HandleId")
        if isinstance(h, str) and h.isdigit():
            cur = max(cur, int(h))
        for v in o.values():
            cur = _max_handle(v, cur)
    elif isinstance(o, list):
        for v in o:
            cur = _max_handle(v, cur)
    return cur


def _run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    for line in (r.stdout or "").splitlines():
        if "+" in line or "Animationen:" in line or "Error" in line:
            print("   " + line.strip())
    return r


main()
