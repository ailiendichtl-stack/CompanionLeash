"""Liest die Eintragsnamen aus einer Voiceset-Szene.

Voicesets sind .scene-Ressourcen, nicht TweakDB-Records. Ihre Eintragsnamen sind das, was
`questPlayVoiceset_NodeTypeParams.voicesetName` erwartet - und damit die einzige Liste, aus
der sich zuverlaessig spielen laesst. Geratene Namen trafen 4 von 54.

Einwortige Eintraege werden ausdruecklich mitgenommen: der erste Anlauf verlangte einen
Unterstrich im Namen und hat dadurch `grapple` verloren - ausgerechnet Judys laengste
Zeile. Erkannt werden sie daran, dass derselbe Name klein UND gross vorkommt; die
Grossschreibung ist der Debug-Name des Eintrags.

    python tools/vset_names.py <pfad.scene> [...]
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#  Feldnamen der Szenen-Struktur, keine Voiceset-Eintraege.
ENGINE = {
    "editorEventId", "editorNodeId", "editorPerformerId", "screenplayLineId",
    "sceneEventIds", "sceneGraph", "startNodes", "outputSockets", "numOutSockets",
    "originNodeId", "performerId", "playerGenderMask", "isHolocallSpeaker",
    "sectionDuration", "specRecordId", "voiceVagId", "voicetagId", "contextualName",
    "findActorInContextParams", "findInContext", "itemId", "lipsyncAnimSet",
    "lipsyncAnimSets", "asyncRefLipsyncAnimSet", "femaleLipsyncAnimationName",
    "maleLipsyncAnimationName", "sceneCategoryTag", "screenplayStore", "actorBehaviors",
    "actorId", "actorName", "acquisitionPlan", "returnConditions", "resouresReferences",
    "debugSymbols", "cookingPlatform", "performersDebugSymbols", "sceneNodesDebugSymbols",
    "sceneEventsDebugSymbols", "vdEntries", "vpEntries", "vpeIndex", "inVoTrigger",
    "outVoTrigger", "voParams", "voInfo", "voContext", "voExpression", "visualStyle",
    "isockStamp", "variantId", "ruid", "raRef", "weights", "mask", "ordinal", "duration",
    "seconds", "stamp", "signature", "graph", "events", "lines", "actors", "addressee",
    "speaker", "trigger", "usage", "presence", "replacement", "replaces", "notification",
    "objective", "destinations", "content", "current", "empty", "general", "generic",
    "simple", "short", "systemic", "whispered", "overHead", "player", "voiceset",
    "VoicesetHolder", "TweakDBID", "CR2W", "ECookingPlatform", "Voiceset", "Default",
    "PLATFORM_PC",
}


def names(path):
    data = open(path, "rb").read()
    strs = set(s.decode("ascii") for s in re.findall(rb"[a-zA-Z0-9_]{3,60}", data))

    snake = re.compile(r"^[a-z]+(_[a-z0-9]+)*(_var_[0-9]+|_[0-9]+)?$")
    hexid = re.compile(r"^[fm]_[0-9A-F]{16}$")

    out = set()
    for w in strs:
        if hexid.match(w) or w in ENGINE or not snake.match(w):
            continue
        if "_" in w:
            out.add(w)
        elif w.capitalize() in strs:
            #  einwortiger Eintrag: die Grossschreibung ist sein Debug-Name
            out.add(w)

    #  Familien mit Varianten sind sicher; Einzelgaenger koennen Text-Fragmente sein und
    #  muessen im Spiel geprueft werden.
    fams = {}
    for n in out:
        base = re.sub(r"(_var_[0-9]+|_[0-9]+)$", "", n)
        fams.setdefault(base, set()).add(n)
    return out, fams


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    result = {}
    for path in sys.argv[1:]:
        if not os.path.exists(path):
            print("nicht gefunden: %s" % path)
            continue
        out, fams = names(path)
        key = os.path.basename(path).replace(".scene", "")
        result[key] = sorted(out)
        multi = {b: sorted(v) for b, v in fams.items() if len(v) > 1}
        print("=== %s: %d Eintraege, %d Familien mit Varianten ===" % (key, len(out), len(multi)))
        for b in sorted(multi):
            print("   %-26s %s" % (b, ", ".join(multi[b])))
        singles = sorted(b for b, v in fams.items() if len(v) == 1)
        print("   Einzelgaenger (%d, im Spiel zu pruefen): %s"
              % (len(singles), ", ".join(singles[:40])))
        print()
    path = os.path.join(HERE, "data", "voicesets.json")
    json.dump(result, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("geschrieben: %s" % os.path.relpath(path, HERE))


main()
