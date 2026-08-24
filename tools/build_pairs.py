"""Baut PAIRS.md: Wortwechsel aus Judys und Vs Voicesets.

Beide Seiten sind ueber denselben Quest-Voiceset-Knoten spielbar - Judy ueber ihren Tag
NCA_Companion, V ueber `isPlayer` mit `#player`. Kein Cooldown, kein Audioware, kein
Fake-Lipsync noetig. Und V ist Player-POV, ihre Mundbewegung sieht ohnehin niemand.

Beide Voicesets sind im Spiel vermessen: Judy 55 Zeilen, V 160. Die Dauern hier sind
gemessen, nicht geschaetzt - anders als bei den Quest-Zeilen.

Die Zuordnung ist von Hand. Automatisch geht sie nicht: sortiert man eine Szene nach
stringId, liegen die Zeilen nach Aufnahme-Charge beieinander, nicht nach Dialogfolge.
"""
import json
import os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#  (Anlass, [Schritte]) - jeder Schritt ist (Sprecher, Voiceset-Name).
#  Reihenfolge = Reihenfolge im Wortwechsel.
EXCHANGES = [
    ("Gespraech unterbrochen", [
        ("V", "interrupt_var_6"),
        ("JUDY", "interrupt_var_1"),
    ]),
    ("Gespraech unterbrochen, kurz", [
        ("V", "interrupt_var_2"),
        ("JUDY", "interrupt"),
    ]),
    ("Zurueck im Gespraech", [
        ("V", "return_var_2"),
        ("JUDY", "return_answer"),
    ]),
    ("Zurueck im Gespraech, laenger", [
        ("V", "return_var_4"),
        ("JUDY", "return_answer_var_1"),
    ]),
    ("Gegner gesichtet", [
        ("JUDY", "enemy_warning_var_1"),
        ("V", "reaction_hostiles_var_2"),
    ]),
    ("Warnung im Kampf", [
        ("V", "combat_ally_warning_var_3"),
        ("JUDY", "battlecry_morale_var_3"),
    ]),
    ("In Deckung", [
        ("V", "combat_ally_cover"),
        ("JUDY", "danger_var_1"),
    ]),
    ("Granate", [
        ("JUDY", "grenade_enemy_var_3"),
        ("V", "reaction_surprise_var_3"),
    ]),
    ("Nachfrage im Kampf", [
        ("V", "combat_ally_check"),
        ("JUDY", "danger_var_3"),
    ]),
    ("Judy sorgt sich um V", [
        ("JUDY", "player_fallback_var_3"),
        ("V", "scene_thanks_var_2"),
    ]),
    ("Kampf vorbei", [
        ("JUDY", "combat_ended_var_1"),
        ("V", "reaction_happy_var_2"),
    ]),
    ("Leise vorgehen", [
        ("V", "combat_ally_stealth"),
        ("JUDY", "stealth_warning_bark_var_1"),
    ]),
    ("Entdeckungsgefahr", [
        ("JUDY", "detection_warning_var_1"),
        ("V", "combat_ally_stealth_var_1"),
    ]),
    ("Stealth wiederhergestellt", [
        ("JUDY", "stealth_restored_var_1"),
        ("V", "reaction_happy_var_3"),
    ]),
    ("Dank nach Hilfe", [
        ("V", "scene_thanks_var_2"),
        ("JUDY", "return_answer"),
    ]),
    ("Begleitung endet", [
        ("V", "follower_end_var_2"),
        ("JUDY", "interrupt_var_1"),
    ]),
    ("Anrempeln", [
        ("JUDY", "bump_var_1"),
        ("V", "reaction_surprise_var_2"),
    ]),
    ("Spieler bleibt zurueck", [
        ("JUDY", "follow_me_1"),
        ("V", "interrupt_var_4"),
    ]),
    ("Etwas Interessantes entdeckt", [
        ("V", "reaction_inspect_var_1"),
        ("JUDY", "urge_var_1"),
    ]),
    ("Fluchen im Kampf", [
        ("JUDY", "battlecry_curse_var_3"),
        ("V", "battlecry_curse_var_4"),
    ]),
]


def load():
    judy = {}
    for u in json.load(open(os.path.join(HERE, "data", "judy_lines_measured.json"),
                            encoding="utf-8"))["unique"]:
        judy[u["name"]] = (u["dur"], u["text"])
    v = {}
    for k, u in json.load(open(os.path.join(HERE, "data", "vset_v_measured.json"),
                               encoding="utf-8")).items():
        v[k] = (u["dur"], u["text"])
    return judy, v


def main():
    judy, v = load()
    missing = []
    out = [
        "# Wortwechsel - Judy und V",
        "",
        "Beide Seiten sind ueber denselben Quest-Voiceset-Knoten **sofort spielbar**: Judy",
        "ueber ihren Tag `NCA_Companion`, V ueber `isPlayer` mit `#player`. Ohne Cooldown,",
        "ohne Audioware, ohne Fake-Lipsync - und Vs Mundbewegung sieht ohnehin niemand, weil",
        "sie Player-POV ist.",
        "",
        "Alle Dauern sind **im Spiel gemessen** (Judy 55 Zeilen, V 160), nicht geschaetzt.",
        "",
        "Die Zuordnung ist Handarbeit. Automatisch geht sie nicht: sortiert man eine Szene",
        "nach stringId, liegen die Zeilen nach Aufnahme-Charge beieinander, nicht nach",
        "Dialogfolge.",
        "",
    ]
    for title, steps in EXCHANGES:
        rows, total = [], 0.0
        for who, name in steps:
            src = judy if who == "JUDY" else v
            if name not in src:
                missing.append((title, who, name))
                continue
            dur, text = src[name]
            total += dur
            rows.append("| %s | `%s` | %.2f | %s |" % (who, name, dur, text))
        if not rows:
            continue
        out += ["## %s  <sub>%.1fs</sub>" % (title, total), "",
                "| Wer | Voiceset | s | Zeile |", "|---|---|---|---|"] + rows + [""]

    path = os.path.join(HERE, "PAIRS.md")
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("PAIRS.md: %d Wortwechsel" % sum(1 for t, s in EXCHANGES))
    if missing:
        print("!! nicht gefunden:")
        for t, who, n in missing:
            print("   %-30s %-5s %s" % (t, who, n))


main()
