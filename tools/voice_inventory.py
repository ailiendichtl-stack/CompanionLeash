"""Extract Cyberpunk 2077 subtitle text straight out of the game archives.

No speech-to-text needed: the shipped localisation archives contain the full
subtitle text as data. lang_de_text.archive holds the German lines.

    python tools/voice_inventory.py            # Judy, German
    python tools/voice_inventory.py --lang en  # same, English
    python tools/voice_inventory.py --filter panam

Writes data/voicelines_<lang>.json and prints a summary.

Two things to keep apart when reading the output:
  * SUBTITLE TEXT  - what exists as recorded dialogue. Rich, but it belongs to
                     scenes and is not directly callable from script.
  * VO EVENTS      - names like 'greeting' usable with PlayVoiceOver(). A far
                     smaller surface, and per-character coverage is unverified.
This tool inventories the first. It tells us what Judy CAN say, which is the
prerequisite for deciding what is worth wiring up.
"""
import ctypes as C
import json, os, re, struct, sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def game_root():
    cfg = os.path.join(HERE, "game-root.txt")
    if len(sys.argv) > 1 and os.path.isdir(sys.argv[-1]):
        return sys.argv[-1]
    if os.path.exists(cfg):
        return open(cfg, encoding="utf-8").read().strip()
    raise SystemExit("No game-root.txt - run apply.py once, or pass the game root")


def fnv1a64(s):
    h = 0xCBF29CE484222325
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return h


class Archive:
    """Minimal reader for the RDAR archive format."""

    def __init__(self, path, oodle):
        self.d = open(path, "rb").read()
        self.fn = oodle
        idx = struct.unpack_from("<Q", self.d, 8)[0]
        ft = struct.unpack_from("<I", self.d, idx)[0]
        self.n, _, _ = struct.unpack_from("<III", self.d, idx + 16)
        self.entries = idx + ft + 20
        self.segs = self.entries + self.n * 56
        self.by_hash = {}
        for i in range(self.n):
            h = struct.unpack_from("<Q", self.d, self.entries + i * 56)[0]
            self.by_hash[h] = i

    def _unseg(self, blob):
        if blob[:4] != b"KARK":
            return blob
        size = struct.unpack_from("<I", blob, 4)[0]
        dst = C.create_string_buffer(size + 64)
        self.fn(blob[8:], len(blob) - 8, dst, size, 1, 0, 0,
                None, 0, None, None, None, 0, 3)
        return dst.raw[:size]

    def read(self, path):
        i = self.by_hash.get(fnv1a64(path.replace("/", chr(92)).lower()))
        if i is None:
            return None
        a, b = struct.unpack_from("<II", self.d, self.entries + i * 56 + 20)
        out = b""
        for s in range(a, b):
            off, zs, _ = struct.unpack_from("<QII", self.d, self.segs + s * 16)
            out += self._unseg(self.d[off:off + zs])
        return out


def cr2w_strings(d):
    """CR2W strings are varint length-prefixed: bit7 marks a string, bit6 a
    continuation byte, the low 6 bits are the length."""
    out, i = [], 0
    while i < len(d):
        b = d[i]
        if b & 0x80:
            if b & 0x40 and i + 1 < len(d):
                ln, hdr = (b & 0x3F) | (d[i + 1] << 6), 2
            else:
                ln, hdr = b & 0x3F, 1
            if 1 < ln < 4000 and i + hdr + ln <= len(d):
                try:
                    s = d[i + hdr:i + hdr + ln].decode("utf-8")
                except UnicodeDecodeError:
                    i += 1
                    continue
                if s.isprintable():
                    out.append(s)
                    i += hdr + ln
                    continue
        i += 1
    return out


SCHEMA = {"JsonResource", "cookingPlatform", "ECookingPlatform", "PLATFORM_PC",
          "handle:ISerializable", "localizationPersistenceSubtitleEntries", "entries",
          "array:localizationPersistenceSubtitleEntry", "stringId", "femaleVariant",
          "String", "maleVariant", "localizationPersistenceSubtitleMap",
          "array:localizationPersistenceSubtitleMapEntry", "subtitleGroup",
          "subtitleFile", "raRef:JsonResource"}


def main():
    lang = "de"
    if "--lang" in sys.argv:
        lang = sys.argv[sys.argv.index("--lang") + 1]
    #  Comma-separated substrings matched against the subtitle file PATH.
    #  Judy speaks in plenty of files not named after her - her questlines have to be
    #  listed explicitly. Note this pulls in every speaker in those scenes, not just
    #  hers: the subtitle data carries no speaker tag. femaleVariant/maleVariant is
    #  V's gender, not who is talking.
    filt = "judy,q105,sq026,sq029,sq030,q203,vset"
    if "--filter" in sys.argv:
        filt = sys.argv[sys.argv.index("--filter") + 1].lower()
    filters = [f.strip() for f in filt.split(",") if f.strip()]

    root = game_root()
    oodle = C.WinDLL(os.path.join(root, "bin", "x64", "oo2ext_7_win64.dll"))
    fn = oodle.OodleLZ_Decompress
    fn.restype = C.c_ssize_t
    fn.argtypes = [C.c_void_p, C.c_ssize_t, C.c_void_p, C.c_ssize_t, C.c_int,
                   C.c_int, C.c_int, C.c_void_p, C.c_ssize_t, C.c_void_p,
                   C.c_void_p, C.c_void_p, C.c_ssize_t, C.c_int]

    arc = Archive(os.path.join(root, "archive", "pc", "content",
                               "lang_%s_text.archive" % lang), fn)
    tag = {"de": "de-de", "en": "en-us"}.get(lang, lang)

    index = arc.read("base/localization/%s/subtitles/subtitles.json" % tag)
    if index is None:
        raise SystemExit("subtitle index not found for " + tag)
    BS = chr(92)   # literal backslash, built at runtime so no source escaping
    pat = "base" + re.escape(BS) + "[ -~]{10,160}?" + re.escape(".json")
    paths = sorted(set(re.findall(pat, index.decode("latin-1"))))
    hits = [p for p in paths if any(f in p.lower() for f in filters)]

    result, total = {}, 0
    for p in hits:
        blob = arc.read(p)
        if not blob:
            continue
        lines = [s for s in cr2w_strings(blob) if s not in SCHEMA]
        seen, uniq = set(), []
        for s in lines:
            if s not in seen:
                seen.add(s)
                uniq.append(s)
        if uniq:
            result[p] = uniq
            total += len(uniq)

    os.makedirs(os.path.join(HERE, "data"), exist_ok=True)
    out = os.path.join(HERE, "data", "voicelines_%s.json" % lang)
    json.dump({"language": tag, "filter": filt, "files": len(result),
               "lines": total, "data": result},
              open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    print("language      : %s" % tag)
    print("filter        : %s" % filt)
    print("subtitle files: %d of %d referenced" % (len(result), len(paths)))
    print("distinct lines: %d" % total)
    print("written       : data/voicelines_%s.json" % lang)
    print()
    for p in sorted(result, key=lambda k: -len(result[k]))[:15]:
        print("  %-72s %4d" % (p.split(chr(92), 4)[-1], len(result[p])))


main()
