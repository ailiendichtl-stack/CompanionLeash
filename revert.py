import hashlib, json, os, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MAN  = json.load(open(os.path.join(HERE, "manifest.json"), encoding="utf-8"))

def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()

def game_root():
    #  Resolution order:
    #    1. explicit CLI argument
    #    2. game-root.txt next to this script (machine-specific, not committed)
    #    3. the parent folder - only correct while the project sits inside the game
    #
    #  The source of truth deliberately lives OUTSIDE the game directory so it survives
    #  Steam file verification, game updates and reinstalls. That means the game path has
    #  to be configured rather than inferred.
    cfg = os.path.join(HERE, "game-root.txt")
    if len(sys.argv) > 1:
        root = sys.argv[1]
    elif os.path.exists(cfg):
        root = open(cfg, encoding="utf-8").read().strip()
    else:
        root = os.path.dirname(HERE)

    if not os.path.exists(os.path.join(root, "bin", "x64", "Cyberpunk2077.exe")):
        q = chr(34)
        print("Not a Cyberpunk 2077 install: " + root)
        print("Pass the game root once and it will be remembered:")
        print("  python " + os.path.basename(sys.argv[0]) + " " + q + "D:/SteamLibrary/steamapps/common/Cyberpunk 2077" + q)
        return None

    if not os.path.exists(cfg):
        open(cfg, "w", encoding="utf-8").write(root)
        print("Remembered game root in game-root.txt")
    return root

def paths(root):
    target = os.path.join(root, *MAN["patch"]["target"].split("/"))
    scripts = os.path.join(root, "r6", "scripts", "CompanionLeash")
    tweaks  = os.path.join(root, "r6", "tweaks")
    cet     = os.path.join(root, "bin", "x64", "plugins", "cyber_engine_tweaks", "mods")
    return target, scripts, tweaks, cet

def main():
    root = game_root()
    if root is None: return 1
    target, scripts, tweaks, cet = paths(root)

    post = MAN["patch"]["postimage_md5"]
    pre  = MAN["patch"]["preimage_md5"]

    if os.path.exists(target):
        cur = md5(target)
        if cur == pre:
            print("Bridge already stock.")
        elif cur == post:
            shutil.copyfile(os.path.join(HERE, "FollowPlayerBehavior.ORIGINAL.reds"), target)
            print("Bridge reverted to stock NCA.")
        else:
            print("REFUSING TO REVERT - target is neither our patched file nor stock.")
            print("  current md5: " + cur)
            print("Resolve by hand; not overwriting unknown content.")
            return 1

    for name in MAN.get("tweak_files", {}):
        f = os.path.join(tweaks, name)
        if os.path.exists(f):
            os.remove(f)
            print("Removed r6/tweaks/" + name)

    for rel in MAN.get("cet_files", {}):
        d = os.path.join(cet, rel.split("/")[0])
        if os.path.isdir(d):
            shutil.rmtree(d)
            print("Removed CET mod " + rel.split("/")[0])

    if os.path.isdir(scripts):
        shutil.rmtree(scripts)
        print("Removed r6/scripts/CompanionLeash/")

    print("Restart the game.")
    return 0

sys.exit(main())
