"""Fuehrt Lipsync-Animationen aus einer Quell-.anims in Judys Voiceset-Set zusammen.

Im Spiel bestaetigt: die Laufzeit laedt das Set NICHT ueber
`resouresReferences.lipsyncAnimSets`, sondern ueber einen aus dem Szenenpfad abgeleiteten
Konventionspfad:

    Szene    base/quest/secondary_characters/vsets/vset_judy.scene
    Lipsync  base/localization/<lang>/lipsync/base/quest/secondary_characters/vsets/
             vset_judy/<figur>.anims

Legt man dort eine eigene Datei ab, wird sie benutzt - geprueft, indem mq055s Set an diesen
Pfad kopiert wurde: die fremde Animation lief, die Bark-Animationen fehlten.

Echtes Lipsync heisst also: EIN Set an diesen Pfad legen, das die 55 Bark-Animationen UND
die gewuenschten Quest-Animationen enthaelt.

Aufbau einer .anims:

    animations[]            je ein animAnimSetEntry mit Namen wie f_<hex>
    animationDataChunks[]   die eigentlichen Daten, mehrere Animationen pro Chunk
    animBuffer.dataAddress  unkIndex -> Chunk, fsetInBytes/zeInBytes -> Lage darin

Der Merge kopiert die gewuenschten Eintraege, haengt die von ihnen benutzten Chunks an und
schreibt `unkIndex` auf die neue Position um. HandleIds werden neu vergeben, damit sie
eindeutig bleiben.

    python tools/merge_anims.py <ziel.anims.json> <quelle.anims.json> <name> [<name> ...]
"""
import copy
import json
import os
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(path):
    return json.load(open(path, encoding="utf-8"))


def anim_name(entry):
    return entry["Data"]["animation"]["Data"]["name"]["$value"]


def max_handle(obj, cur=0):
    if isinstance(obj, dict):
        h = obj.get("HandleId")
        if isinstance(h, str) and h.isdigit():
            cur = max(cur, int(h))
        for v in obj.values():
            cur = max_handle(v, cur)
    elif isinstance(obj, list):
        for v in obj:
            cur = max_handle(v, cur)
    return cur


def max_buffer(obj, cur=-1):
    if isinstance(obj, dict):
        b = obj.get("BufferId")
        if isinstance(b, str) and b.isdigit():
            cur = max(cur, int(b))
        for v in obj.values():
            cur = max_buffer(v, cur)
    elif isinstance(obj, list):
        for v in obj:
            cur = max_buffer(v, cur)
    return cur


def renumber(obj, counter, buffers):
    """HandleIds UND BufferIds neu vergeben.

    BufferIds nicht mitzuzaehlen war der erste Fehlversuch: WolvenKit fuehrt beim Einlesen
    eine Referenztabelle darueber und bricht bei einer doppelten Id ab.
    """
    if isinstance(obj, dict):
        if isinstance(obj.get("HandleId"), str):
            counter[0] += 1
            obj["HandleId"] = str(counter[0])
        if isinstance(obj.get("BufferId"), str):
            buffers[0] += 1
            obj["BufferId"] = str(buffers[0])
        for v in obj.values():
            renumber(v, counter, buffers)
    elif isinstance(obj, list):
        for v in obj:
            renumber(v, counter, buffers)


def main():
    if len(sys.argv) < 4:
        raise SystemExit(__doc__)
    dst_path, src_path = sys.argv[1], sys.argv[2]
    wanted = sys.argv[3:]

    dst = load(dst_path)
    src = load(src_path)
    d = dst["Data"]["RootChunk"]
    s = src["Data"]["RootChunk"]

    have = {anim_name(e) for e in d["animations"]}
    by_name = {anim_name(e): e for e in s["animations"]}

    missing = [w for w in wanted if w not in by_name]
    if missing:
        raise SystemExit("nicht in der Quelle: %s" % ", ".join(missing))
    already = [w for w in wanted if w in have]
    if already:
        print("schon vorhanden, uebersprungen: %s" % ", ".join(already))
    todo = [w for w in wanted if w not in have]
    if not todo:
        print("nichts zu tun")
        return

    counter = [max_handle(d)]
    buffers = [max_buffer(d)]
    chunk_map = {}          # Quell-Chunk-Index -> Ziel-Chunk-Index
    added_chunks = 0

    for name in todo:
        entry = copy.deepcopy(by_name[name])
        buf = entry["Data"]["animation"]["Data"]["animBuffer"]
        bd = buf.get("Data", buf)
        da = bd["dataAddress"]
        src_idx = da["unkIndex"]

        if src_idx not in chunk_map:
            #  Nur die tatsaechlich benutzten Chunks uebernehmen. Sie enthalten oft mehrere
            #  Animationen; die ungenutzten Bereiche kosten Platz, aber die Offsets bleiben
            #  dadurch gueltig, ohne die Daten neu zu schneiden.
            chunk = copy.deepcopy(s["animationDataChunks"][src_idx])
            renumber(chunk, counter, buffers)
            chunk_map[src_idx] = len(d["animationDataChunks"])
            d["animationDataChunks"].append(chunk)
            added_chunks += 1

        da["unkIndex"] = chunk_map[src_idx]
        renumber(entry, counter, buffers)
        d["animations"].append(entry)
        print("  + %-22s Chunk %d -> %d, Offset %d, %d Bytes"
              % (name, src_idx, da["unkIndex"], da["fsetInBytes"], da["zeInBytes"]))

    out = dst_path.replace(".json", ".merged.json")
    json.dump(dst, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print()
    print("Animationen: %d (+%d) | Chunks: %d (+%d)"
          % (len(d["animations"]), len(todo),
             len(d["animationDataChunks"]), added_chunks))
    print("geschrieben: %s (%.1f MB)" % (os.path.relpath(out, HERE),
                                         os.path.getsize(out) / 1024 / 1024))


main()
