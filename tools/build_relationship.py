# -*- coding: utf-8 -*-
"""Baut RELATIONSHIP.md - der eine Ort fuer Judys und Vs Beziehungsdialog.

Zwei Vorschlagsdokumente aus dritter Hand haben sich stark ueberschnitten und beide auf
Zeilen verwiesen, die sie nur zitiert haben. Hier stehen sie zusammengefuehrt und gegen die
echten Daten geprueft - Text, Sprecher, Dauer und Lipsync-Lage kommen aus den Dumps, nicht
aus dem Vorschlag.

Die Pruefung hat sich gelohnt. Von 63 genannten Ids waren vier um je ein Hex-Zeichen
verdreht, eine zu kurz, und `18eec7bfe32fc004` ist "Achtung!", nicht "Bin bei dir."

Woher eine Zeile stammt, entscheidet NICHT ueber ihre Eignung - nur ihr Wortlaut tut das.
Vs "Ich hab dich echt vermisst" ist in Panams Quest aufgenommen, sagt aber keinen Namen und
kann damit ebenso gut Judy gelten. Ausgeschlossen wird deshalb maschinell: nennt eine Zeile
eine andere Figur beim Namen, faellt sie heraus. Sonst zaehlt der Ton, nicht der Ordner.

Kuratiert wird hier, nachgeschlagen wird automatisch. Eine Zeile aufzunehmen heisst, ihre Id
in eine Kategorie zu schreiben; ist sie unbekannt, bricht der Lauf ab, statt still etwas
Falsches zu schreiben.

    python tools/build_relationship.py     -> RELATIONSHIP.md
"""
import json
import os
import re

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WARN_MS = 1000          # ab hier braucht die Zeile geliehenes Lipsync

#  Nennt eine Zeile eine dieser Figuren, gehoert sie nicht in den Pool - egal wie gut sie
#  klingt. Judy fehlt hier bewusst: ihr Name ist ein Vorteil, kein Ausschluss.
FREMDE_NAMEN = ["River", "Panam", "Kerry", "Rogue", "Johnny", "Jackie", "Misty",
                "Takemura", "Hanako", "Songbird", "Reed", "Saul", "Mitch", "Maiko",
                "Hiromi", "Evelyn", "Woodman", "Fingers", "Dex", "Meredith"]

#  ("b", name)  Judy-Bark aus vset_judy - sofort spielbar
#  ("q", hex)   Judy-Questzeile - baubar, Lipsync je nach Animationslage
#  ("bv", name) V-Bark aus vset_v
#  ("qv", hex)  V-Questzeile - V braucht kein Lipsync, Spieler-Perspektive

CATEGORIES = [
 dict(key="wiedersehen", title="Wiedersehen und Rueckkehr",
      when="V kommt nach laengerer Abwesenheit zurueck oder meldet sich",
      note="Der Bark-Bestand deckt das Funktionale ab. Was fehlte, ist die Fassung, in der"
           " sie zugibt, dass sie V vermisst hat.",
      judy=[("b", "greeting"), ("b", "greeting_var_1"), ("b", "return_answer"),
            ("b", "return_answer_var_1"),
            ("q", "2ffdc7962d571000"), ("q", "1893611d242b6000"),
            ("q", "1b07d5a1472b6000"), ("q", "1b07ecef852b6000"),
            ("q", "1b2f276faf2fc000"), ("q", "39669188b9a4e000")],
      v=[("qv", "1811545ef42fc000"), ("qv", "1ab41f674b2ef000"),
         ("qv", "1a04d435ff2c5000"), ("qv", "1b06fde31b2b6000")],
      pairs=[("Sie gibt es zuerst zu",
              [("J", "q", "2ffdc7962d571000"), ("V", "qv", "1811545ef42fc000")],
              "Judy fragt, V antwortet beilaeufig - der Kontrast macht die Zeile."),
             ("V ruft nur so an",
              [("V", "qv", "1ab41f674b2ef000"), ("J", "q", "1893611d242b6000")],
              "Ein Anruf ohne Anlass ist die Geste; ihre Antwort quittiert sie."),
             ("Beide geben es zu",
              [("V", "qv", "1a04d435ff2c5000"), ("J", "q", "1b07d5a1472b6000")],
              "Ihre Antwort setzt Vs Gestaendnis voraus - hier bekommt sie es."),
             ("V weicht aus, Judy laesst es zu",
              [("V", "qv", "1b06fde31b2b6000"), ("J", "q", "1b07ecef852b6000")],
              "V dreht die Frage weg, Judy geht darauf ein statt nachzubohren.")]),

 dict(key="initiative", title="Judy meldet sich von selbst",
      when="Selten, ohne Anlass - sie ruft an, weil sie an V gedacht hat",
      note="Die groesste Luecke im bisherigen Bestand. Judy ist dort fast immer die"
           " Reagierende. Diese Zeilen drehen das um.",
      judy=[("q", "1afc08ecff2fc000"), ("q", "1b07e0e36d2b6000"),
            ("q", "1b0791cfae2b6000"), ("q", "1b0b9169282b6000"),
            ("q", "181ba067292fc000"), ("q", "18795a9ae52fc000"),
            ("q", "1afc12f00d2fc000"), ("q", "1974ca6f6d2b6000"),
            ("q", "1a67b32f202b6000"), ("q", "1b07df75762b6000")],
      v=[("qv", "187e5cd1722fc000"), ("qv", "1a9f1202962fc004"),
         ("qv", "1afc00a4fb2fc004"), ("qv", "1afbfff4872fc004")],
      pairs=[("V hat wenig Zeit, Judy nimmt sie sich",
              [("V", "qv", "1afc00a4fb2fc004"), ("J", "q", "1b07e0e36d2b6000")],
              "Vs Zeile bittet um Zeit, Judys Antwort gibt sie ohne Bedingung."),
             ("V bedauert die Entfernung",
              [("V", "qv", "1afbfff4872fc004"), ("J", "q", "1b0791cfae2b6000")],
              "Vs Bedauern, ihr Trost - zwei Zeilen, die sich nie begegnet sind."),
             ("Sehr selten: der Flirt vorweg",
              [("J", "q", "1afc08ecff2fc000"), ("J", "q", "1b07e0e36d2b6000")],
              "Hoechstens einmal pro Spieltag. Haeufiger verliert die Zeile alles.")]),

 dict(key="flirt", title="Flirt und Necken",
      when="Beziehung steht, Lage ist ruhig",
      note="Judy neckt lieber, als dass sie schwaermt. Der Ton bleibt trocken.",
      judy=[("q", "189736fe942b6000"), ("q", "1812474b462b6000"),
            ("q", "189c5847c42b6000"), ("q", "39675dc8759ce000"),
            ("q", "1a9f63e7252b6000"), ("q", "189806a8512b6000"),
            ("q", "1a67403cc92fc004")],
      v=[("qv", "1a9f07a2ab2fc000"), ("qv", "1532045272401000")],
      pairs=[("Lob und Abwehr",
              [("J", "q", "39675dc8759ce000"), ("V", "qv", "172a8c16fb502000")],
              "Ihr Lob ist beilaeufig - genau deshalb sitzt es."),
             ("Zwei, die sich verdient haben",
              [("J", "q", "1812474b462b6000"), ("J", "q", "189736fe942b6000")],
              "Funktioniert nach etwas, das die beiden zusammen geschafft haben."),
             ("Nur ein Zimmer",
              [("V", "qv", "1532045272401000"), ("J", "q", "189806a8512b6000")],
              "Vs Zeile ist eine Frage ohne Namen - sie traegt in jede Richtung.")]),

 dict(key="alltag", title="Kaffee, Pizza, Zuhause",
      when="V ist bei ihr, nichts Dringendes liegt an",
      note="Der staerkste Fund aus beiden Dokumenten. Alltag traegt eine Beziehung"
           " glaubhafter als weitere Liebeserklaerungen - und das Material dafuer ist da,"
           " samt Vs Antworten.",
      judy=[("q", "3968743729a71000"), ("q", "396871fa77a71000"),
            ("q", "1a0fbd86992b6000"), ("q", "1a0fe8a4772b6000"),
            ("q", "1a0fe9bfde2b6000")],
      v=[("qv", "1a6769eccf2fc000"), ("qv", "1a676a6b122fc000"),
         ("qv", "1a0fd4447d2b6000"), ("qv", "1a0fd5b3d22b6000"),
         ("qv", "39b494eb948bb000")],
      pairs=[("Kaffee, schwarz",
              [("J", "q", "3968743729a71000"), ("V", "qv", "1a6769eccf2fc000"),
               ("J", "q", "396871fa77a71000")],
              "Ihre Pointe setzt voraus, dass V vorher geantwortet hat - hier geht sie auf."),
             ("Kaffee, mit Milch",
              [("J", "q", "3968743729a71000"), ("V", "qv", "1a676a6b122fc000"),
               ("J", "q", "396871fa77a71000")],
              "Dieselbe Pointe, andere Antwort. Beide Wege muessen funktionieren."),
             ("Streit um Pizza",
              [("J", "q", "1a0fbd86992b6000"), ("V", "qv", "1a0fd5b3d22b6000"),
               ("J", "q", "1a0fe8a4772b6000")],
              "Der laengste vollstaendige Wortwechsel im ganzen Bestand."),
             ("Streit um Pizza, kurze Fassung",
              [("J", "q", "1a0fbd86992b6000"), ("V", "qv", "1a0fd4447d2b6000")],
              "Wenn die lange Empoerung zu viel ist."),
             ("Bleib noch",
              [("V", "qv", "39b494eb948bb000"), ("J", "q", "1b07e0e36d2b6000")],
              "Vs Zeile stammt aus dem Hangout und meint genau das.")]),

 dict(key="einladung", title="Einladung und Verabredung",
      when="Judy schlaegt etwas vor, V sagt zu",
      note="Diese Kategorie fehlte bisher ganz.",
      judy=[("q", "1a9f085b672fc000"), ("q", "1a9f0c7fe02fc000"),
            ("q", "181ba067292fc000"), ("q", "18795a9ae52fc000"),
            ("q", "39675ce5d69ce000")],
      v=[("qv", "1a9f07a2ab2fc000"), ("qv", "39b494eb948bb000")],
      pairs=[("Gilt das Angebot noch",
              [("V", "qv", "1a9f07a2ab2fc000"), ("J", "q", "1a9f085b672fc000")],
              "Vs Zeile fragt woertlich nach - der sauberste Anschluss im Bestand."),
             ("Lass mich nicht warten",
              [("J", "q", "1a9f0c7fe02fc000"), ("V", "qv", "39b494eb948bb000")],
              "Ihre Ungeduld und Vs Zusage schliessen die Verabredung ab.")]),

 dict(key="sorge", title="Sorge und Nachsorge",
      when="V ist verletzt, erschoepft oder lange weg gewesen",
      note="Erst schimpft sie aus Angst, dann wird sie weich. Diese Reihenfolge ist"
           " glaubwuerdiger als reine Fuersorge - und beide Haelften liegen vor.",
      judy=[("b", "player_fallback_var_2"), ("b", "player_fallback_var_3"),
            ("q", "1ef8b0186b42f000"), ("q", "1f46421f852b6008"),
            ("q", "28aa62967b4ea000"), ("q", "1f45f8b07b2b6008"),
            ("q", "1ef8b0c1f442f000"), ("q", "1f4640da642b6000"),
            ("q", "1a33ca85c72b6000"), ("q", "14aaba91a329f000"),
            ("q", "14aabd878129f000")],
      v=[("qv", "1a0a374e852fc000"), ("qv", "198e76d299521000")],
      pairs=[("Schimpfen, dann weich werden",
              [("J", "b", "player_fallback_var_2"), ("J", "q", "1f4640da642b6000")],
              "Der Umschlag von Wut zu Sorge ist die ganze Wirkung."),
             ("Ruhig atmen",
              [("J", "q", "1ef8b0186b42f000"), ("J", "q", "1ef8b0c1f442f000")],
              "Nur nach echtem Schaden. Sonst wirkt sie uebergriffig."),
             ("Sie merkt, dass etwas nicht stimmt",
              [("J", "q", "14aaba91a329f000"), ("V", "qv", "1a0a374e852fc000"),
               ("J", "q", "1a33ca85c72b6000")],
              "Vs Zeile stammt aus Judys eigener Quest und passt woertlich.")]),

 dict(key="stolz", title="Anerkennung und Stolz",
      when="V hat etwas gut gemacht - nicht zwingend im Kampf",
      note="Bisher gab es Lob fast nur nach Gefechten.",
      judy=[("q", "16bf45bffc2fc000"), ("q", "39675dc8759ce000"),
            ("q", "39675eebd79ce000"), ("q", "189c5847c42b6000")],
      v=[("qv", "172a8c16fb502000"), ("qv", "18c1d0f46c4e6004")],
      pairs=[("Beeindruckt",
              [("J", "q", "16bf45bffc2fc000"), ("V", "qv", "18c1d0f46c4e6004")],
              "Trockenes Lob, trockene Antwort.")]),

 dict(key="arbeit", title="Gemeinsame Arbeit",
      when="Virtu, Tauchen, Technik - sie laesst V an ihrer Arbeit teilhaben",
      note="Judy zeigt Zuneigung, indem sie jemanden in ihre Arbeit laesst. Das ist ihr"
           " eigentlicher Liebesbeweis, und dafuer gibt es viel Material.",
      judy=[("q", "189d4f49e02b6000"), ("q", "39675eebd79ce000")],
      v=[("qv", "1a6181b1812fc000"), ("qv", "19c6ddabf55b3000"),
         ("qv", "189793991b2b6000"), ("qv", "18c1d0f46c4e6004")],
      pairs=[("Sie fragt, V sagt zu",
              [("J", "q", "189d4f49e02b6000"), ("V", "qv", "1a6181b1812fc000")],
              "Vs Zusage ist aus derselben Questreihe - Ton und Wortwahl passen."),
             ("V vertraut ihr blind",
              [("V", "qv", "19c6ddabf55b3000"), ("J", "q", "39675eebd79ce000")],
              "Vs Zeile nennt Judy beim Namen. Der beste Anschluss im ganzen V-Bestand.")]),

 dict(key="kampf_ende", title="Nach dem Kampf",
      when="Gefecht vorbei, beide stehen noch",
      note="Bereits gut abgedeckt. Hier steht nur, was den Sieg zu etwas Gemeinsamem macht.",
      judy=[("b", "combat_ended_var_1"), ("b", "combat_ended_var_2"),
            ("q", "1f3324ae9552a008"), ("q", "1f3324aeb552a008"),
            ("q", "1f3324aeb752a008")],
      v=[("qv", "172a8c16fb502000")],
      pairs=[("Sieh uns an",
              [("J", "q", "1f3324aeb552a008"), ("J", "q", "1f3324aeb752a008")],
              "Aus dem Sieg wird ein gemeinsames Erlebnis statt einer Meldung."),
             ("Bin bei dir",
              [("J", "q", "1f3324ae9552a008"), ("V", "qv", "172a8c16fb502000")],
              "Sparsam einsetzen - die Zeile traegt viel und nutzt sich schnell ab.")]),

 dict(key="reibung", title="Warten, Troedeln, kleine Reibung",
      when="V bleibt zurueck, bricht ab oder kommt zu spaet",
      note="Reibung ohne Bruch. Ihre Ungeduld liest sich als Vertrautheit, wenn sie nicht"
           " allein steht - deshalb gehoert immer eine Versoehnung dahinter.",
      judy=[("b", "follow_me"), ("b", "hurry_up_var_1"), ("b", "hurry_up_var_2"),
            ("b", "interrupt"), ("b", "interrupt_var_1"),
            ("q", "39675fea699ce000"), ("q", "39675ce5d69ce000"),
            ("q", "1a9f63e7252b6000")],
      v=[],
      pairs=[("Abbruch und Rueckkehr",
              [("J", "b", "interrupt"), ("J", "b", "interrupt_var_1")],
              "Zwischen beiden gehoert eine echte Pause - sonst klingt sie schnippisch."),
             ("Du hast meine Plaene ruiniert",
              [("J", "q", "1a9f63e7252b6000"), ("J", "q", "189806a8512b6000")],
              "Vorwurf mit einem Augenzwinkern, und gleich der Koeder hinterher.")]),

 dict(key="naehe", title="Tiefe Naehe",
      when="Nur nach abgeschlossener Romanze - nie im Ambient-Pool",
      note="Diese Zeilen tragen Gewicht und vertragen keine Wiederholung. Sie gehoeren an"
           " ein Ereignis, nicht an einen Zufallsgenerator.",
      judy=[("q", "175e1a1cba386000"), ("q", "1401fd943a2fc000"),
            ("q", "18fe75e7ff3bc000"), ("q", "197a02720e2b6000"),
            ("q", "1878a052fd2fc000")],
      v=[("qv", "1b3506911a62301c"), ("qv", "126b36bcba404000"),
         ("qv", "18e94ba7da29f000")],
      pairs=[("Sie sagt es",
              [("J", "q", "175e1a1cba386000"), ("V", "qv", "1b3506911a62301c")],
              "Hoechstens einmal. Danach nie wieder aus dem Zufallspool."),
             ("Egal was kommt",
              [("J", "q", "1401fd943a2fc000"), ("V", "qv", "126b36bcba404000")],
              "Ihre Angst zuerst, dann Vs Zusage. Nur an einem echten Wendepunkt.")]),

 dict(key="abschied", title="Abschied",
      when="Ende einer Begleitung oder eines Anrufs",
      note="Nur am tatsaechlichen Ende, nie als Ambient-Zeile.",
      judy=[("q", "1897d495012b6000"), ("q", "18982e23922b6000"),
            ("q", "1b0b9169282b6000")],
      v=[("qv", "1a0a374e852fc000")],
      pairs=[("Bis dann",
              [("J", "q", "1897d495012b6000"), ("V", "qv", "1a0a374e852fc000")],
              "Kurz halten. Die verspielte Fassung `Bis dahaaaann!` nur selten.")]),
]

#  Aussortiert - nicht wegen der Herkunft, sondern wegen des Inhalts.
RISKY = [
 ("qv", "1b35069117623004", "spricht River beim Namen an - der einzige echte Ausschluss"),
 ("q", "1057514c594ea000", "Endgame-Abschied aus Night City; Anim ausserdem +2886 ms"),
 ("q", "18fe75b5663bc000", "Nachricht an eine Sterbende - nur im passenden Ende"),
 ("q", "1afc08ecff2fc000", "sehr direkt; nur nach Romanze und hoechstens einmal taeglich"),
 ("qv", "18e94ba7da29f000", "zweite Haelfte bindet sich ans Bleiben in Night City"),
]


def main():
    d = _load()
    out, stats = [], {"J": 0, "V": 0, "leih": 0, "bark": 0, "namen": []}

    body = []
    for c in CATEGORIES:
        body.append("\n## %s\n" % c["title"])
        body.append("**Wann:** %s\n" % c["when"])
        body.append("%s\n" % c["note"])
        for label, refs in (("Judy", c["judy"]), ("V", c["v"])):
            if not refs:
                continue
            body.append("### %s\n" % label)
            body.append("| Zeile | Dauer | Status | Quelle |")
            body.append("|---|---|---|---|")
            for kind, ref in refs:
                r = _resolve(kind, ref, d)
                stats["J" if label == "Judy" else "V"] += 1
                if "Leih" in r["status"]:
                    stats["leih"] += 1
                if r["status"] == "Bark":
                    stats["bark"] += 1
                if r["fremd"]:
                    stats["namen"].append((r["text"], r["fremd"]))
                body.append("| %s | %s | `%s` | `%s` |"
                            % (r["text"], r["dur"], r["status"], r["src"]))
            body.append("")
        if c.get("pairs"):
            body.append("### Wortwechsel\n")
            for title, seq, why in c["pairs"]:
                body.append("**%s**\n" % title)
                for spk, kind, ref in seq:
                    r = _resolve(kind, ref, d)
                    body.append("- **%s:** %s  <sub>%s</sub>"
                                % ("JUDY" if spk == "J" else "V", r["text"], r["dur"]))
                body.append("")
                body.append("%s\n" % why)

    out.append("# Judy und V - Beziehungsdialog\n")
    out.append("Der zentrale Bestand. Zwei Vorschlagsdokumente sind hier zusammengefuehrt")
    out.append("und **gegen die echten Daten geprueft**: Text, Sprecher, Dauer und")
    out.append("Lipsync-Lage kommen aus den Dumps, nicht aus dem Vorschlag.\n")
    out.append("Erweitern heisst: eine Id in `tools/build_relationship.py` eintragen und")
    out.append("neu erzeugen. Eine unbekannte Id bricht den Lauf ab - hier steht nichts")
    out.append("Unbelegtes.\n")
    out.append("**Bestand:** %d Judy-Zeilen und %d V-Zeilen in %d Kategorien, dazu %d"
               % (stats["J"], stats["V"], len(CATEGORIES),
                  sum(len(c.get("pairs", [])) for c in CATEGORIES)))
    out.append("Wortwechsel. %d Eintraege sind sofort spielbare Barks, %d Judy-Zeilen"
               % (stats["bark"], stats["leih"]))
    out.append("brauchen geliehenes Lipsync.\n")
    out.append("## Woher eine Zeile stammt, zaehlt nicht\n")
    out.append("Der Ordner sagt nichts ueber die Eignung - nur der Wortlaut tut das. Vs")
    out.append("\"Ich hab dich echt vermisst\" wurde fuer Panams Quest aufgenommen, nennt")
    out.append("aber keinen Namen und kann damit ebenso gut Judy gelten. Ausgeschlossen")
    out.append("wird deshalb maschinell: nennt eine Zeile eine andere Figur, faellt sie")
    out.append("heraus. Geprueft wird gegen %d Namen.\n" % len(FREMDE_NAMEN))
    out.append("## Lesart\n")
    out.append("| Kennung | Bedeutung |")
    out.append("|---|---|")
    out.append("| `Bark` | liegt in `vset_judy` bzw. `vset_v` - sofort abspielbar |")
    out.append("| `Zeile` | Questzeile, per Generator baubar, Lipsync sitzt |")
    out.append("| `Zeile+Leih` | Animation laeuft ueber eine Sekunde nach - fremdes Lipsync |")
    out.append("| `Zeile?` | keine Animation im Bestand - Lipsync ungeprueft |")
    out.append("| `VVF` | Vs Seite, ueber das V Voice Framework - kein Lipsync noetig |")
    out += body

    out.append("\n## Unter Vorbehalt\n")
    out.append("Nicht wegen der Herkunft aussortiert, sondern wegen des Inhalts.\n")
    out.append("| Zeile | Warum |")
    out.append("|---|---|")
    for kind, ref, why in RISKY:
        r = _resolve(kind, ref, d)
        out.append("| %s | %s |" % (r["text"], why))

    out.append("\n## Was noch fehlt\n")
    out.append("* **Vs Barks** sind noch nicht einsortiert - 160 gemessene Zeilen liegen in")
    out.append("  `data/vset_v_measured.json` und warten auf dieselbe Durchsicht.")
    out.append("* **Zustandslogik** - welche Kategorie ab welchem Beziehungsstand offen")
    out.append("  ist, steht noch nicht fest.")
    out.append("* **Abklingzeiten** - die Vorschlaege nennen Werte, geprueft ist keiner.")
    out.append("* **Dauern fuer Vs Zeilen** fehlen groesstenteils: `durations.json` deckt")
    out.append("  bisher nur die Szenen mit Judy ab. Fuer die Taktung der Wortwechsel")
    out.append("  muessten die uebrigen Szenen noch eingelesen werden.")
    out.append("* **Der volle Bestand** steht weiter in [LINES.md](LINES.md) und")
    out.append("  [data/v_ALL_de.md](data/v_ALL_de.md) - hier ist nur, was gesichtet ist.")

    p = os.path.join(HERE, "RELATIONSHIP.md")
    open(p, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("Judy %d | V %d | Kategorien %d | Wortwechsel %d"
          % (stats["J"], stats["V"], len(CATEGORIES),
             sum(len(c.get("pairs", [])) for c in CATEGORIES)))
    print("Barks %d | Leih-Lipsync %d" % (stats["bark"], stats["leih"]))
    if stats["namen"]:
        print()
        print("!! nennt eine andere Figur - gehoert nicht in den Pool:")
        for t, n in stats["namen"]:
            print("   %-14s %s" % (n, t[:60]))
    else:
        print("Namenspruefung: keine Zeile nennt eine andere Figur.")
    print("geschrieben: RELATIONSHIP.md (%d KB)" % (os.path.getsize(p) // 1024))


def _load():
    def js(n):
        return json.load(open(os.path.join(HERE, "data", n), encoding="utf-8"))
    jall = js("judy_ALL_de.json")["files"]
    #  v_scene_judy_default liegt in Judys Dump, ist aber Vs Stimme.
    jud = {str(r["id"]): r for r in jall if r["prefix"].startswith("judy")}
    vee = {str(r["id"]): r for r in js("v_ALL_de.json")["lines"]}
    vee.update({str(r["id"]): r for r in jall if r["prefix"].startswith("v_")})
    return dict(jud=jud, vee=vee, barkj=js("judy_lines_measured.json")["hits"],
                barkv=js("vset_v_measured.json"), dur=js("durations.json"),
                anim=js("anim_durations.json"))


def _fremd(text):
    for n in FREMDE_NAMEN:
        if re.search(r"\b%s\b" % n, text):
            return n
    return None


def _resolve(kind, ref, d):
    if kind in ("b", "bv"):
        tab = d["barkj"] if kind == "b" else d["barkv"]
        if ref not in tab:
            raise SystemExit("!! Bark unbekannt: %s" % ref)
        e = tab[ref]
        return {"text": _q(e["text"]), "dur": "%.1f s" % e["dur"], "status": "Bark",
                "src": ref, "fremd": _fremd(e["text"])}
    src = d["jud"] if kind == "q" else d["vee"]
    key = str(int(ref, 16))
    if key not in src:
        raise SystemExit("!! Id nicht im %s-Bestand: %s"
                         % ("Judy" if kind == "q" else "V", ref))
    r = src[key]
    rec = d["dur"].get(key)
    ms = rec["dur"] if rec else None
    if kind == "qv":
        status = "VVF"
    elif not rec:
        status = "Zeile?"
    else:
        a = d["anim"].get("f_%016X" % int(key))
        status = ("Zeile?" if not a
                  else "Zeile+Leih" if a["ms"] - ms > WARN_MS else "Zeile")
    text = r.get("text") or "(ohne Untertitel)"
    return {"text": _q(text), "dur": "%.1f s" % (ms / 1000.0) if ms else "?",
            "status": status, "src": "%s %s" % (ref, r.get("scene", "")),
            "fremd": _fremd(text)}


def _q(t):
    return t.replace("|", "/").strip()


main()
