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
    return target, scripts, tweaks

def main():
    root = game_root()
    if root is None: return 1
    target, scripts, tweaks = paths(root)

    if not os.path.exists(target):
        print("Night City Allies not installed - target missing:")
        print("  " + target)
        return 1

    pre  = MAN["patch"]["preimage_md5"]
    post = MAN["patch"]["postimage_md5"]
    cur  = md5(target)

    if cur != pre and cur != post:
        print("REFUSING TO PATCH.")
        print("The target matches neither the stock file we recorded nor our patched")
        print("version. Night City Allies has almost certainly been updated.")
        print("")
        print("  recorded NCA : " + MAN["environment"]["nca_vortex_source"])
        print("  current  md5 : " + cur)
        print("  preimage md5 : " + pre)
        print("  postimage md5: " + post)
        print("")
        print("Re-merge: copy the new stock file over FollowPlayerBehavior.ORIGINAL.reds,")
        print("re-apply companion-leash.patch, save as FollowPlayerBehavior.PATCHED.reds,")
        print("refresh manifest.json hashes, then re-run.")
        return 1

    # policy layer - our own files, never overwritten by anyone else
    if not os.path.isdir(scripts):
        os.makedirs(scripts)
    for name in MAN["standalone_files"]:
        shutil.copyfile(os.path.join(HERE, "src", name), os.path.join(scripts, name))

    for name in MAN.get("tweak_files", {}):
        shutil.copyfile(os.path.join(HERE, "tweaks", name), os.path.join(tweaks, name))

    if cur == pre:
        shutil.copyfile(os.path.join(HERE, "FollowPlayerBehavior.PATCHED.reds"), target)

    if md5(target) != post:
        print("ERROR: post-install verification failed.")
        return 1

    print("Installed CompanionLeash " + MAN["version"] + ".")
    print("  bridge  : " + MAN["patch"]["target"])
    print("  policy  : r6/scripts/CompanionLeash/ (" + str(len(MAN["standalone_files"])) + " files)")
    print("Restart the game; redscript recompiles at launch.")
    print("Check r6/logs/redscript_rCURRENT.log if the compile dialog appears.")
    return 0

sys.exit(main())
