"""Look up paths in a Cyberpunk archive without loading it into memory.

The voice archive is 4.7 GB. Only the header and the file-index need reading, so this
seeks to the index and hashes candidate paths against it.

    python tools/archive_lookup.py <archive> <path> [path ...]
"""
import os, struct, sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def fnv1a64(s):
    h = 0xCBF29CE484222325
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return h


def load_hashes(path):
    """Return {nameHash: (segStart, segEnd)} plus the segment table offset."""
    with open(path, "rb") as f:
        head = f.read(24)
        if head[:4] != b"RDAR":
            raise SystemExit("not an archive: " + path)
        idx = struct.unpack_from("<Q", head, 8)[0]
        f.seek(idx)
        meta = f.read(28)
        ft = struct.unpack_from("<I", meta, 0)[0]
        n = struct.unpack_from("<I", meta, 16)[0]
        f.seek(idx + ft + 20)
        raw = f.read(n * 56)
    out = {}
    for i in range(n):
        o = i * 56
        h = struct.unpack_from("<Q", raw, o)[0]
        a, b = struct.unpack_from("<II", raw, o + 20)
        out[h] = (a, b)
    return out, idx


def main():
    arc = sys.argv[1]
    if not os.path.isabs(arc) and not os.path.exists(arc):
        root = open(os.path.join(HERE, "game-root.txt"), encoding="utf-8").read().strip()
        arc = os.path.join(root, "archive", "pc", "content", arc)
    table, _ = load_hashes(arc)
    print("%s: %d files indexed" % (os.path.basename(arc), len(table)))
    BS = chr(92)
    for p in sys.argv[2:]:
        key = p.replace("/", BS).lower()
        hit = table.get(fnv1a64(key))
        print("  %-6s %s" % ("FOUND" if hit else "-", p))


main()
