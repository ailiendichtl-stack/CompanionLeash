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

Vor dem Bau wird jede Zeile gegen `data/anim_durations.json` geprueft. Eine Animation
traegt kein Versatzfeld, laeuft also ab Ereignisbeginn; ist sie deutlich laenger als die
Zeile, hinkt der Mund dem Ton hinterher. Genau daran lag das beobachtete Delay - die
Animation war 4267 ms lang, die Zeile 2922. Betroffen sind 3 % der Zeilen (44 von 1375),
und die sollen nicht verloren gehen.

Woher der Vorlauf kommt, steht in der Herkunftsszene. Dort beginnt das Dialogereignis bei
4312 ms, und 2967 + 4267 = 7234 = 4312 + 2922: die Animation endet genau mit der Zeile und
faengt 1345 ms vor ihr an - exakt der Ueberhang. Sie enthaelt also Mimik VOR dem Sprechen.

Zwei Hebel dagegen sind durchgefallen: `frameClamping` auf das Startbild aendert nichts, es
schneidet nicht. Die Zeile auf die Animationslaenge zu dehnen auch nicht - die Laufzeit
streckt die Animation also nicht auf die Ereignisdauer. In beiden Faellen setzte der Mund
erst nach knapp der Haelfte des Satzes ein.

Der dritte auch: `startTime` verschiebt Ton UND Animation gemeinsam. Damit ist beantwortet,
woran die Animation haengt - am Ereignis, nicht am Abschnitt. Mit Feldern ist der Vorlauf
also nicht zu trennen, und das Ereignis in mq055 ist strukturell identisch mit unserem
Nachbau. Nur eine Fassung der Animation existiert im ganzen Spiel, es gibt also auch keine
kuerzere zum Ausweichen.

Was dabei mitgeht, war mir zuerst nicht klar: die Animation ist nicht Lipsync, sondern
die ganze Gesichtsperformance - 344 Joints, 414 Tracks, additiv auf die Ruhepose. Es gibt
im ganzen Szenenformat kein Ereignis fuer Mimik, sie steckt allein in dieser Datei. Wer die
Animation leiht, leiht also die Emotion mit. Deshalb wird der Spender zuerst in derselben
Questreihe gesucht: Judys Tonfall ist innerhalb einer Quest aehnlicher als quer durchs
Spiel, und "Ich bin froh, dass du da bist" mit dem Gesicht einer Terminabsprache liegt
daneben, auch wenn die Laenge stimmt.

Bleibt, die Frage zu umgehen: die Zeile behaelt ihren Ton, bekommt aber die
Lipsync-Animation einer ANDEREN Zeile aehnlicher Laenge ohne Vorlauf. Die Lippen formen dann
nicht diese Worte, sitzen aber zeitlich richtig - aus Companion-Abstand der bessere Tausch.
Im Spiel bestaetigt, also passiert es ab `WARN_MS` von selbst; `raw=True` schaltet es fuer
Vergleiche ab, `borrow="<hex>"` waehlt den Spender von Hand.

Das ist ein Umweg, keine Loesung - im Vorlauf steckt echte Mimik, die verloren geht. Der
Fall ist unter "Offen" in BUILD_VOICESET.md notiert.

Dazu wird ein `judy.anims` erzeugt, das die 55 Bark-Animationen und die Animationen aller
gewuenschten Zeilen enthaelt. Die Laufzeit laedt es nicht ueber die Szenenreferenz, sondern
ueber einen aus dem Szenenpfad abgeleiteten Konventionspfad.

    python tools/build_lines.py            # baut die Testauswahl unten
    python tools/build_lines.py --alle     # baut alles Gesichtete aus der Matrix

Im vollen Lauf heisst jeder Eintrag `cl_<id>`. Das ist unschoen zu lesen, aber eindeutig
und unveraenderlich - ein Name aus Situation und laufender Nummer haette sich verschoben,
sobald eine Zeile dazukommt, und damit die Verdrahtung gebrochen.
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
WARN_MS = 1000                # ab hier laeuft die Animation der Zeile sichtbar davon
PLATZHALTER_MS = 200          # darunter ist die Szenendauer kein Messwert
NAH_GENUG_MS = 400            # so weit darf ein Spender aus der eigenen Reihe danebenliegen

#  (Eintragsname, stringId als Hex). Die ersten beiden sagen fast dasselbe, unterscheiden
#  sich aber im Verhaeltnis Animation zu Zeile - nebeneinander machen sie hoerbar, dass es
#  daran liegt und nicht am Bauverfahren.
WANTED = [
    dict(name="cl_froh", hex="1b2f276faf2fc000"),   # 1917 ms, q105_07      Anim  +150
    dict(name="cl_kurz", hex="1812474b462b6000"),   # 2502 ms, q105_06c     Anim  -135
    dict(name="cl_lang", hex="18795a0a822fc000"),   # 5005 ms, sq030_11     Anim  -305
    #  Dreimal dieselbe Zeile aus mq055 - 2922 ms Ton gegen 4267 ms Animation.
    dict(name="cl_v_roh",  hex="39669188b9a4e000", raw=True),
    dict(name="cl_v_leih", hex="39669188b9a4e000"),
    #  Szenendauer ist ein 100-ms-Platzhalter - faellt auf die Animationslaenge zurueck
    #  und braucht dann gar keinen Spender.
    dict(name="cl_tauch",  hex="1be5242cf12b6000"),
]



def main():
    alle = "--alle" in sys.argv
    durations = json.load(open(os.path.join(HERE, "data", "durations.json"),
                               encoding="utf-8"))
    anims = json.load(open(os.path.join(HERE, "data", "anim_durations.json"),
                           encoding="utf-8"))

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

    donors = _donors(anims, durations)
    wanted = WANTED
    if alle:
        bau = json.load(open(os.path.join(HERE, "data", "matrix_lines.json"),
                             encoding="utf-8"))
        wanted = [dict(name="cl_" + b["hex"], hex=b["hex"], sit=b["situation"],
                       stufe=b.get("stufe", 0))
                  for b in bau]
        print("Bauliste aus der Matrix: %d Zeilen" % len(wanted))

    zaehl = {"gebaut": 0, "leih": 0, "platzhalter": 0, "ohne_anim": 0}
    anims_needed = {}   # Szene -> {Zielname: Spezifikation fuer merge_anims}
    for w in wanted:
        name, hexid = w["name"], w["hex"]
        rec = durations.get(str(int(hexid, 16)))
        if not rec:
            print("!! keine Dauer bekannt: %s" % name)
            continue
        if rec["dur"] <= PLATZHALTER_MS and not anims.get("f_" + hexid.upper()):
            #  Weder Szenendauer noch Animation - dann gibt es nichts, woran sich die
            #  Laenge festmachen liesse. Lieber auslassen als raten.
            print("!! keine belastbare Dauer, ausgelassen: %s" % name)
            continue
        src = "f_" + hexid.upper()
        anim = anims.get(src)
        delta = (anim["ms"] - rec["dur"]) if anim else None

        duration, lipsync, lip_scene = rec["dur"], src, rec["scene"]
        if delta is None:
            note = "kein Anim-Eintrag"
        elif rec["dur"] <= PLATZHALTER_MS:
            #  Die Szene traegt keine echte Dauer. Die eigene Animation ist dann das
            #  beste Mass, das es gibt - und sie passt per Definition zum Gesicht.
            duration = anim["ms"]
            note = "Szenendauer ist Platzhalter, Animationslaenge %d genommen" % anim["ms"]
        elif w.get("borrow") or (delta > WARN_MS and not w.get("raw")):
            b = w.get("borrow")
            if b:
                lipsync = "f_" + b.upper()
            else:
                lipsync = _donor(donors, rec["dur"], rec["scene"])
            lip_scene = durations[str(int(lipsync[2:], 16))]["scene"]
            note = "Lipsync geliehen aus %s, %d ms statt %d" % (
                _reihe(lip_scene), anims[lipsync]["ms"], anim["ms"])
        else:
            note = "Anim %+d ms" % delta
            if delta > WARN_MS:
                note += "  << Mund hinkt nach"

        _add_entry(root, st, name, hexid, duration, lipsync)
        anims_needed.setdefault(lip_scene, {})[lipsync] = lipsync
        zaehl["gebaut"] += 1

        if "geliehen" in note:
            zaehl["leih"] += 1
        if "Platzhalter" in note:
            zaehl["platzhalter"] += 1
        if "kein Anim" in note:
            zaehl["ohne_anim"] += 1
        if not alle:
            print("  %-12s %5d ms  %-24s %s"
                  % (name, duration, rec["scene"][:24], note))

    if alle:
        print("  gebaut %d | geliehenes Lipsync %d | Platzhalter-Dauer %d | ohne Anim %d"
              % (zaehl["gebaut"], zaehl["leih"], zaehl["platzhalter"],
                 zaehl["ohne_anim"]))


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

    _build_anims(anims_needed)

    print()
    for r, _, fs in os.walk(BUILD):
        for f in fs:
            p = os.path.join(r, f)
            print("   %-92s %6d KB" % (os.path.relpath(p, BUILD),
                                       os.path.getsize(p) // 1024))


def _donors(anims, durations):
    """Animationen, die zu ihrer eigenen Zeile passen - als Spender brauchbar."""
    out = []
    for name, a in anims.items():
        rec = durations.get(str(int(name[2:], 16)))
        if rec and rec["dur"] > PLATZHALTER_MS and abs(a["ms"] - rec["dur"]) <= 150:
            out.append((a["ms"], name, _reihe(rec["scene"])))
    out.sort()
    return out


def _reihe(scene):
    """Die Questreihe einer Szene: mq055_01_megabuilding -> mq055."""
    return scene.split("_")[0] if scene else ""


def _donor(donors, target, scene):
    """Der passendste Spender - erst nach Tonfall, dann nach Laenge.

    Mit der Animation kommt die ganze Mimik. Innerhalb einer Questreihe ist Judys Ton
    aehnlicher als quer durchs Spiel, also bekommt die eigene Reihe den Vorzug - solange
    ihr bester Spender nicht zu weit danebenliegt.
    """
    reihe = _reihe(scene)
    eigen = [d for d in donors if d[2] == reihe]
    if eigen:
        best = min(eigen, key=lambda d: abs(d[0] - target))
        if abs(best[0] - target) <= NAH_GENUG_MS:
            return best[1]
    return min(donors, key=lambda d: abs(d[0] - target))[1]


def _panel_liste(gebaut, durations):
    """Schreibt die gebauten Zeilen als Lua-Tabelle fuer das Testpanel.

    170 Knoepfe ohne Gruppierung waeren unbenutzbar, und die Namen sind absichtlich
    unleserlich. Das Panel braucht deshalb den Text dazu - und der kommt von hier, damit
    er nicht neben dem Bau von Hand gepflegt werden muss.
    """
    import json as _json
    jall = _json.load(open(os.path.join(HERE, "data", "judy_ALL_de.json"),
                           encoding="utf-8"))["files"]
    txt = {str(r["id"]): (r.get("text") or "") for r in jall}

    def esc(t):
        return t.replace("\\", "").replace('"', "'").replace("\n", " ").strip()

    out = ["--  Erzeugt von tools/build_lines.py --alle. Nicht von Hand aendern.",
           "--  %d Zeilen aus der gesichteten Matrix." % len(gebaut),
           "return {"]
    for name, sit, hexid, ms, stufe in sorted(gebaut, key=lambda g: (g[1], g[4], -g[3])):
        t = esc(txt.get(str(int(hexid, 16)), ""))[:78]
        st = ", st = %d" % stufe if stufe else ""
        out.append('  { n = "%s", s = "%s", d = %.1f%s, t = "%s" },'
                   % (name, sit, ms / 1000.0, st, t))
    out.append("}")
    p = os.path.join(HERE, "cet", "CompanionLeashVO", "lines.lua")
    open(p, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("  Panel-Liste: %s" % os.path.relpath(p, HERE))


def _add_entry(root, st, name, hexid, duration, lipsync):
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
    line["femaleLipsyncAnimationName"]["$value"] = lipsync
    line["maleLipsyncAnimationName"]["$value"] = "m" + lipsync[1:]
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


def _build_anims(needed):
    van = _find_anims("vset_judy")
    work = os.path.join(HERE, "build", "lines_anim")
    if os.path.exists(work):
        import shutil
        shutil.rmtree(work)
    os.makedirs(work)
    _run([CLI, "convert", "serialize", van, "-o", work])
    target = os.path.join(work, "judy.anims.json")

    for scene, specs in needed.items():
        src = _find_anims(scene)
        if not src:
            print("!! kein Anim-Set fuer %s" % scene)
            continue
        sub = os.path.join(work, scene)
        os.makedirs(sub, exist_ok=True)
        _run([CLI, "convert", "serialize", src, "-o", sub])
        _run([sys.executable, os.path.join(HERE, "tools", "merge_anims.py"),
              target, os.path.join(sub, "judy.anims.json")]
             + [specs[k] for k in sorted(specs)])
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
