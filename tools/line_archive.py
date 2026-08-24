"""Join subtitle text with the actual voice files.

The voice archive names every file as

    <speaker>_<quest>_<gender>_<stringId-hex>.wem

so the hex suffix is the same stringId the subtitle records carry. That gives a direct
join between the German text and the audio, and - unexpectedly - solves speaker
attribution, which the subtitle data alone cannot provide.

    python tools/line_archive.py                 # Judy, German
    python tools/line_archive.py --speaker panam
    python tools/line_archive.py --refresh       # re-read the archive file list

Writes data/line_archive_<speaker>_<lang>.json and prints a summary.

Requires tools/wolvenkit (Console build) to list the archive contents once; the list is
cached afterwards.
"""
import json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLI = os.path.join(HERE, "tools", "wolvenkit", "console", "WolvenKit.CLI.exe")
CACHE = os.path.join(HERE, "data", "voice_files_%s.txt")


def game_root():
    cfg = os.path.join(HERE, "game-root.txt")
    if not os.path.exists(cfg):
        raise SystemExit("No game-root.txt - run apply.py once first")
    return open(cfg, encoding="utf-8").read().strip()


def voice_list(lang, refresh=False):
    """Filenames in the voice archive. Cached: listing 90k entries takes a while."""
    cache = CACHE % lang
    if os.path.exists(cache) and not refresh:
        return open(cache, encoding="utf-8", errors="replace").read().split("\n")

    if not os.path.exists(CLI):
        raise SystemExit("WolvenKit CLI not found at " + CLI)
    arc = os.path.join(game_root(), "archive", "pc", "content",
                       "lang_%s_voice.archive" % lang)
    if not os.path.exists(arc):
        raise SystemExit("voice archive not found: " + arc)

    print("listing %s (this takes a minute) ..." % os.path.basename(arc))
    out = subprocess.run([CLI, "archive", arc, "--list"],
                         capture_output=True, text=True, errors="replace")
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    open(cache, "w", encoding="utf-8").write(out.stdout)
    return out.stdout.split("\n")


def main():
    lang = "de"
    speaker = "judy"
    refresh = "--refresh" in sys.argv
    if "--lang" in sys.argv:
        lang = sys.argv[sys.argv.index("--lang") + 1]
    if "--speaker" in sys.argv:
        speaker = sys.argv[sys.argv.index("--speaker") + 1].lower()

    inv_path = os.path.join(HERE, "data", "voicelines_%s.json" % lang)
    if not os.path.exists(inv_path):
        raise SystemExit("run tools/voice_inventory.py first")
    inv = json.load(open(inv_path, encoding="utf-8"))

    text = {}
    for path, entries in inv["data"].items():
        scene = path.split(chr(92))[-1].replace(".json", "")
        for e in entries:
            text[int(e["id"])] = {"scene": scene, "text": e["text"]}

    #  <speaker>_<quest>_<gender>_<hex>.wem  - gender is V's, not the speaker's
    pat = re.compile(r"([a-z0-9_]+)_([fm])_([0-9a-f]{16})\.wem", re.I)
    files = {}
    for line in voice_list(lang, refresh):
        line = line.strip()
        m = pat.search(line)
        if not m:
            continue
        sid = int(m.group(3), 16)
        bucket = files.setdefault(sid, [])
        #  the same path can appear more than once in the listing
        if not any(b["path"] == line for b in bucket):
            bucket.append({"speaker": m.group(1), "gender": m.group(2), "path": line})

    rows, speakers = [], {}
    for sid, variants in files.items():
        for v in variants:
            speakers[v["speaker"].split("_")[0]] = speakers.get(v["speaker"].split("_")[0], 0) + 1
        if sid not in text:
            continue
        for v in variants:
            if speaker and not v["speaker"].startswith(speaker):
                continue
            rows.append({"id": str(sid), "speaker": v["speaker"], "gender": v["gender"],
                         "scene": text[sid]["scene"], "text": text[sid]["text"],
                         "wem": v["path"]})

    rows.sort(key=lambda r: (r["scene"], r["id"]))
    out = os.path.join(HERE, "data", "line_archive_%s_%s.json" % (speaker or "all", lang))
    json.dump({"language": lang, "speaker": speaker, "count": len(rows), "lines": rows},
              open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print()
    print("subtitle entries : %d" % len(text))
    print("voice files       : %d" % len(files))
    print("joined for '%s'   : %d" % (speaker, len(rows)))
    print("written           : %s" % os.path.relpath(out, HERE))
    print()
    byscene = {}
    for r in rows:
        byscene[r["scene"]] = byscene.get(r["scene"], 0) + 1
    for sc in sorted(byscene, key=lambda k: -byscene[k])[:12]:
        print("  %-52s %4d" % (sc, byscene[sc]))


main()
