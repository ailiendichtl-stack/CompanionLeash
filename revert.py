import hashlib, json, os, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MAN  = json.load(open(os.path.join(HERE, "manifest.json"), encoding="utf-8"))

def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()

def game_root():
    # CLI arg wins; otherwise assume this folder sits in the game root.
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(HERE)
    if not os.path.exists(os.path.join(root, "bin", "x64", "Cyberpunk2077.exe")):
        print("Not a Cyberpunk 2077 install: " + root)
        print("Pass the game root explicitly:  python " + os.path.basename(sys.argv[0]) + " <game-root>")
        return None
    return root

def paths(root):
    target = os.path.join(root, *MAN["patch"]["target"].split("/"))
    scripts = os.path.join(root, "r6", "scripts", "CompanionLeash")
    tweaks  = os.path.join(root, "r6", "tweaks")
    return target, scripts, tweaks

def main():
    root = game_root()
    if root is None: return 1
    target, scripts, tweaks = paths(root)

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

    if os.path.isdir(scripts):
        shutil.rmtree(scripts)
        print("Removed r6/scripts/CompanionLeash/")

    print("Restart the game.")
    return 0

sys.exit(main())
