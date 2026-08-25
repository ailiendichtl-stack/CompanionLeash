# -*- coding: utf-8 -*-
"""Baut DIALOG_MATRIX.md - der EINE Bestand: welche Zeile in welcher Situation, Judy und V.

Vorher lagen drei Dokumente nebeneinander, die alle dasselbe beschrieben: MATRIX (Barks
und gesichtete Questzeilen je Situation), PAIRS (Wortwechsel) und RELATIONSHIP (die
geprueften Beziehungszeilen mit Vs Seite). Sie ueberschnitten sich, und keins war fuer sich
vollstaendig - man musste wissen, welches gerade gilt. Hier stehen sie zusammen.

Was aus den drei Quellen kommt:

* die **Bark-Familien** je Situation - regelbasiert, deckt alle 55 Judy-Barks ab
* die **111 handverlesenen Questzeilen** aus der Sichtung von 816 eigenstaendigen Zeilen.
  Sie hingen als Zeilennummern an zwei Hilfsdateien; `migrate_picks.py` hat sie einmal in
  Ids aufgeloest, seither liegen sie als `data/matrix_picks.json`.
* die **Beziehungssichtung** aus zwei Vorschlagsdokumenten, gegen die Dumps geprueft
* die **50 Wortwechsel** aus beiden Seiten

Text, Dauer und Lipsync-Lage werden nachgeschlagen, nicht gepflegt. Erweitern heisst: eine
Id in eine Kategorie schreiben. Ist sie unbekannt, bricht der Lauf ab, statt still etwas
Falsches zu schreiben.

Woher eine Zeile stammt, entscheidet NICHT ueber ihre Eignung - nur ihr Wortlaut tut das.
Vs "Ich hab dich echt vermisst" wurde fuer Panams Quest aufgenommen, sagt aber keinen Namen
und kann ebenso gut Judy gelten. Ausgeschlossen wird deshalb maschinell: nennt eine Zeile
eine andere Figur, faellt sie heraus.

    python tools/build_matrix.py     -> DIALOG_MATRIX.md
"""
import json
import os
import re

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WARN_MS = 1000          # ab hier braucht die Zeile geliehenes Lipsync

#  Nennt eine Zeile eine dieser Figuren, gehoert sie nicht in den Pool - egal wie gut sie
#  klingt. Judy fehlt hier bewusst: ihr Name ist ein Vorteil, kein Ausschluss.
#  Szenen, in denen Judy vorkommt. Vs Zeilen von dort setzen ein Gespraech mit ihr
#  fort; alles andere ist eine freie Neukombination - brauchbar, aber es gehoert
#  dazugeschrieben, damit niemand einen Anschluss annimmt, den es nicht gibt.
JUDY_SZENEN = ("q004", "q105", "q115", "q201", "q202", "q203", "mq055", "sq026",
               "sq030", "judy", "finalboards")

FREMDE_NAMEN = ["River", "Panam", "Kerry", "Rogue", "Johnny", "Jackie", "Misty",
                "Takemura", "Hanako", "Songbird", "Reed", "Saul", "Mitch", "Maiko",
                "Hiromi", "Evelyn", "Woodman", "Fingers", "Dex", "Meredith"]

#  In den Wortwechseln:
#  ("b", name)  Judy-Bark      ("q", hex)  Judy-Questzeile
#  ("bv", name) V-Bark         ("qv", hex) V-Questzeile

CATEGORIES = [
 dict(key="wiedersehen", title="Ankunft und Wiedersehen",
      when="V kommt an, kehrt zurueck oder meldet sich",
      note="Die Barks decken das Funktionale ab. Was fehlte, ist die Fassung, in der sie"
           " zugibt, dass sie V vermisst hat - die steht jetzt daneben.",
      fams=["return_answer", "greeting"],
      picks=["Ankunft / Wiedersehen"],
      judy=["2ffdc7962d571000", "1893611d242b6000", "1b07d5a1472b6000",
            "1b07ecef852b6000"],
      v=["1811545ef42fc000", "1ab41f674b2ef000", "1a04d435ff2c5000",
         "1b06fde31b2b6000"],
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
              "V dreht die Frage weg, Judy geht darauf ein statt nachzubohren."),
             ("Zurueck im Gespraech",
              [("V", "bv", "return_var_2"), ("J", "b", "return_answer")],
              "Der knappste Wiedereinstieg, beide Seiten als Bark."),
             ("Zurueck im Gespraech, laenger",
              [("V", "bv", "return_var_4"), ("J", "b", "return_answer_var_1")],
              "Dieselbe Figur mit mehr Luft."),
             ("Dank nach Hilfe",
              [("V", "bv", "scene_thanks_var_2"), ("J", "b", "return_answer")],
              "Funktioniert auch ausserhalb des Wiedersehens.")]),

 dict(key="initiative", title="Judy meldet sich von selbst",
      when="Selten, ohne Anlass - sie ruft an, weil sie an V gedacht hat",
      note="Die groesste Luecke im bisherigen Bestand. Judy war fast immer die"
           " Reagierende. Keine Bark deckt das ab.",
      fams=[], picks=[],
      judy=["1afc08ecff2fc000", "1b07e0e36d2b6000", "1b0791cfae2b6000",
            "1b0b9169282b6000", "181ba067292fc000", "18795a9ae52fc000",
            "1afc12f00d2fc000", "1974ca6f6d2b6000", "1a67b32f202b6000",
            "1b07df75762b6000"],
      v=["187e5cd1722fc000", "1a9f1202962fc004", "1afc00a4fb2fc004",
         "1afbfff4872fc004"],
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
      fams=[], picks=[],
      judy=["189736fe942b6000", "1812474b462b6000", "189c5847c42b6000",
            "39675dc8759ce000", "1a9f63e7252b6000", "189806a8512b6000",
            "1a67403cc92fc004", "18830b966a2b6000", "18983199cf2b6000",
            "18a6e78c9e2b6000", "1897f7fb1a2b6000", "1897f8b7412b6000",
            "19eba4297c2b6000"],
      v=["1a9f07a2ab2fc000", "1532045272401000", "1a04d435ff2c5000",
         "39b494eb948bb000"],
      pairs=[("Lob und Abwehr",
              [("J", "q", "39675dc8759ce000"), ("V", "qv", "172a8c16fb502000")],
              "Ihr Lob ist beilaeufig - genau deshalb sitzt es."),
             ("Zwei, die sich verdient haben",
              [("J", "q", "1812474b462b6000"), ("J", "q", "189736fe942b6000")],
              "Funktioniert nach etwas, das die beiden zusammen geschafft haben."),
             ("Nur ein Zimmer",
              [("V", "qv", "1532045272401000"), ("J", "q", "189806a8512b6000")],
              "Vs Zeile ist eine Frage ohne Namen - sie traegt in jede Richtung."),
             ("War das Timing gut oder denkst du staendig an mich",
              [("J", "q", "18830b966a2b6000"), ("V", "qv", "1a04d435ff2c5000")],
              "Sie stellt die Fangfrage, V faellt darauf herein - besser geht es nicht."),
             ("Ich tauch nicht mit jeder",
              [("J", "q", "18a6e78c9e2b6000"), ("V", "qv", "19c6ddabf55b3000")],
              "Ihr Zugestaendnis ist beilaeufig verpackt; Vs Zusage nennt ihren Namen."),
             ("Ablenkung",
              [("J", "q", "18983199cf2b6000"), ("V", "qv", "39b494eb948bb000")],
              "Beide Zeilen lassen offen, worum es geht. Genau deshalb tragen sie.")]),

 dict(key="alltag", title="Alltag - Kaffee, Pizza, Zuhause",
      when="V ist bei ihr, nichts Dringendes liegt an",
      note="Der staerkste Fund der Beziehungssichtung. Alltag traegt eine Beziehung"
           " glaubhafter als weitere Liebeserklaerungen - und das Material ist da, samt"
           " Vs Antworten.",
      fams=["bump"],
      picks=["Idle / Smalltalk"],
      judy=["3968743729a71000", "396871fa77a71000", "1a0fbd86992b6000",
            "1a0fe8a4772b6000", "1a0fe9bfde2b6000"],
      v=["1a6769eccf2fc000", "1a676a6b122fc000", "1a0fd4447d2b6000",
         "1a0fd5b3d22b6000", "39b494eb948bb000"],
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
              "Vs Zeile stammt aus dem Hangout und meint genau das."),
             ("Anrempeln",
              [("J", "b", "bump_var_1"), ("V", "bv", "reaction_surprise_var_2")],
              "Kleinster moeglicher Wortwechsel, rein koerperlich.")]),

 dict(key="einladung", title="Einladung und Verabredung",
      when="Judy schlaegt etwas vor, V sagt zu",
      note="Diese Kategorie fehlte bisher ganz - in allen drei Dokumenten.",
      fams=[], picks=[],
      judy=["1a9f085b672fc000", "1a9f0c7fe02fc000", "39675ce5d69ce000"],
      v=["1a9f07a2ab2fc000", "39b494eb948bb000"],
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
      fams=["player_fallback", "grapple"],
      picks=["Spieler verletzt / Sorge"],
      judy=["1ef8b0186b42f000", "1f46421f852b6008", "28aa62967b4ea000",
            "1f45f8b07b2b6008", "1ef8b0c1f442f000", "1f4640da642b6000",
            "1a33ca85c72b6000", "14aaba91a329f000", "14aabd878129f000",
            "1afd6f18ec2fc000", "1a82306830610000", "1b971f17262b6000"],
      v=["1a0a374e852fc000", "198e76d299521000", "17bb05d57b5b3000"],
      pairs=[("Schimpfen, dann weich werden",
              [("J", "b", "player_fallback_var_2"), ("J", "q", "1f4640da642b6000")],
              "Der Umschlag von Wut zu Sorge ist die ganze Wirkung."),
             ("Ruhig atmen",
              [("J", "q", "1ef8b0186b42f000"), ("J", "q", "1ef8b0c1f442f000")],
              "Nur nach echtem Schaden. Sonst wirkt sie uebergriffig."),
             ("Sie merkt, dass etwas nicht stimmt",
              [("J", "q", "14aaba91a329f000"), ("V", "qv", "1a0a374e852fc000"),
               ("J", "q", "1a33ca85c72b6000")],
              "Vs Zeile stammt aus Judys eigener Quest und passt woertlich."),
             ("Judy sorgt sich um V",
              [("J", "b", "player_fallback_var_3"), ("V", "bv", "scene_thanks_var_2")],
              "Die Bark-Fassung, ohne Vorbedingung einsetzbar."),
             ("Judy braucht selbst Raum",
              [("J", "q", "1a82306830610000"), ("V", "qv", "17bb05d57b5b3000"),
               ("J", "q", "1b971f17262b6000")],
              "Der einzige Wortwechsel, in dem SIE zurueckzieht und V wartet."),
             ("Sie versteht es",
              [("V", "qv", "1a0a374e852fc000"), ("J", "q", "1afd6f18ec2fc000")],
              "Keine Beschwichtigung, sondern Zustimmung. Das ist selten.")]),

 dict(key="stolz", title="Anerkennung und Stolz",
      when="V hat etwas gut gemacht - nicht zwingend im Kampf",
      note="Bisher gab es Lob fast nur nach Gefechten.",
      fams=[], picks=[],
      judy=["16bf45bffc2fc000", "39675dc8759ce000", "39675eebd79ce000",
            "189c5847c42b6000"],
      v=["172a8c16fb502000", "18c1d0f46c4e6004"],
      pairs=[("Beeindruckt",
              [("J", "q", "16bf45bffc2fc000"), ("V", "qv", "18c1d0f46c4e6004")],
              "Trockenes Lob, trockene Antwort."),
             ("Gegenseitig",
              [("J", "q", "39675dc8759ce000"), ("V", "qv", "172a8c16fb502000"),
               ("J", "q", "1812474b462b6000")],
              "Lob, Gegenlob, und ihre Pointe schliesst es ab.")]),

 dict(key="arbeit", title="Gemeinsame Arbeit",
      when="Virtu, Tauchen, Technik - sie laesst V an ihrer Arbeit teilhaben",
      note="Judy zeigt Zuneigung, indem sie jemanden in ihre Arbeit laesst. Das ist ihr"
           " eigentlicher Liebesbeweis, und dafuer gibt es viel Material.",
      fams=[], picks=[],
      judy=["189d4f49e02b6000", "39675eebd79ce000"],
      v=["1a6181b1812fc000", "19c6ddabf55b3000", "189793991b2b6000",
         "18c1d0f46c4e6004"],
      pairs=[("Sie fragt, V sagt zu",
              [("J", "q", "189d4f49e02b6000"), ("V", "qv", "1a6181b1812fc000")],
              "Vs Zusage ist aus derselben Questreihe - Ton und Wortwahl passen."),
             ("V vertraut ihr blind",
              [("V", "qv", "19c6ddabf55b3000"), ("J", "q", "39675eebd79ce000")],
              "Vs Zeile nennt Judy beim Namen. Der beste Anschluss im ganzen V-Bestand.")]),

 dict(key="kampf", title="Kampf",
      when="Gefecht laeuft",
      note="Vollstaendig ueber Barks abgedeckt - die groesste Bark-Familie im Voiceset.",
      fams=["battlecry_morale", "combat_aggro_bark", "enemy_warning", "battlecry_curse",
            "danger", "elite_warning", "grenade_enemy", "grenade_throw", "reloading"],
      picks=["Kampf"], judy=[], v=[],
      pairs=[("Gegner gesichtet",
              [("J", "b", "enemy_warning_var_1"), ("V", "bv", "reaction_hostiles_var_2")],
              "Warnung und Bestaetigung."),
             ("Warnung im Kampf",
              [("V", "bv", "combat_ally_warning_var_3"), ("J", "b", "battlecry_morale_var_3")],
              "V warnt, Judy geht drauf zu."),
             ("In Deckung",
              [("V", "bv", "combat_ally_cover"), ("J", "b", "danger_var_1")],
              "Vs Kommando, ihr Fluch."),
             ("Granate",
              [("J", "b", "grenade_enemy_var_3"), ("V", "bv", "reaction_surprise_var_3")],
              "Ihre Warnung kommt zuerst."),
             ("Nachfrage im Kampf",
              [("V", "bv", "combat_ally_check"), ("J", "b", "danger_var_3")],
              "\"Bin bei dir\" ist die beste Antwort im ganzen Bark-Bestand."),
             ("Fluchen im Kampf",
              [("J", "b", "battlecry_curse_var_3"), ("V", "bv", "battlecry_curse_var_4")],
              "Beide fluchen - reine Textur, kein Inhalt.")]),

 dict(key="kampf_ende", title="Nach dem Kampf",
      when="Gefecht vorbei, beide stehen noch",
      note="Hier steht, was den Sieg zu etwas Gemeinsamem macht statt zu einer Meldung.",
      fams=["combat_ended"],
      picks=["Kampf vorbei / Lob"],
      judy=["1f3324ae9552a008", "1f3324aeb552a008", "1f3324aeb752a008"],
      v=["172a8c16fb502000"],
      pairs=[("Sieh uns an",
              [("J", "q", "1f3324aeb552a008"), ("J", "q", "1f3324aeb752a008")],
              "Aus dem Sieg wird ein gemeinsames Erlebnis."),
             ("Bin bei dir",
              [("J", "q", "1f3324ae9552a008"), ("V", "qv", "172a8c16fb502000")],
              "Sparsam einsetzen - die Zeile traegt viel und nutzt sich schnell ab."),
             ("Kampf vorbei",
              [("J", "b", "combat_ended_var_1"), ("V", "bv", "reaction_happy_var_2")],
              "Die Bark-Fassung, jederzeit einsetzbar.")]),

 dict(key="stealth", title="Stealth",
      when="Unentdeckt vorgehen, entdeckt werden, wieder verschwinden",
      note="Barks decken alle drei Zustaende ab. Vs `combat_ally_stealth` ist"
           " ausdruecklich fuer Begleiter geschrieben.",
      fams=["stealth_restored", "stealth_warning_bark", "detection_warning",
            "camera_warning", "body_warning"],
      picks=["Stealth"], judy=[], v=[],
      pairs=[("Leise vorgehen",
              [("V", "bv", "combat_ally_stealth"), ("J", "b", "stealth_warning_bark_var_1")],
              "V gibt den Ton vor, Judy bestaetigt."),
             ("Entdeckungsgefahr",
              [("J", "b", "detection_warning_var_1"), ("V", "bv", "combat_ally_stealth_var_1")],
              "Ihre Warnung, Vs Beruhigung."),
             ("Stealth wiederhergestellt",
              [("J", "b", "stealth_restored_var_1"), ("V", "bv", "reaction_happy_var_3")],
              "Erleichterung auf beiden Seiten.")]),

 dict(key="reibung", title="Warten, Troedeln, kleine Reibung",
      when="V bleibt zurueck, bricht ab oder kommt zu spaet",
      note="Reibung ohne Bruch. Ihre Ungeduld liest sich als Vertrautheit, wenn sie nicht"
           " allein steht - deshalb gehoert immer eine Versoehnung dahinter.",
      fams=["follow_me", "hurry_up", "urge", "interrupt", "phone_urge"],
      picks=["Spieler bleibt zurueck", "Warten / Ungeduld"],
      judy=["39675fea699ce000", "39675ce5d69ce000", "1a9f63e7252b6000",
            "18f9e3bc672b6000", "19ec472e462b6000", "137c5715552b1000"],
      v=[],
      pairs=[("Gespraech unterbrochen",
              [("V", "bv", "interrupt_var_6"), ("J", "b", "interrupt_var_1")],
              "V bricht ab, Judy nimmt es hin."),
             ("Gespraech unterbrochen, kurz",
              [("V", "bv", "interrupt_var_2"), ("J", "b", "interrupt")],
              "Dieselbe Figur, knapper."),
             ("Spieler bleibt zurueck",
              [("J", "b", "follow_me_1"), ("V", "bv", "interrupt_var_4")],
              "Ihre Ungeduld, Vs Ausrede."),
             ("Begleitung endet",
              [("V", "bv", "follower_end_var_2"), ("J", "b", "interrupt_var_1")],
              "Vs `follower_end` ist ausdruecklich fuer Begleiter geschrieben."),
             ("Etwas Interessantes entdeckt",
              [("V", "bv", "reaction_inspect_var_1"), ("J", "b", "urge_var_1")],
              "V bleibt stehen, Judy will weiter."),
             ("Du hast meine Plaene ruiniert",
              [("J", "q", "1a9f63e7252b6000"), ("J", "q", "189806a8512b6000")],
              "Vorwurf mit einem Augenzwinkern, und gleich der Koeder hinterher."),
             ("Brett vorm Kopf",
              [("J", "q", "18f9e3bc672b6000"), ("J", "q", "19ec472e462b6000")],
              "Spott ohne Schaerfe - sie bleibt dabei zugewandt.")]),

 dict(key="umgebung", title="Umgebung und Aussicht",
      when="Aussichtspunkt, ungewoehnlicher Ort, gemeinsames Schauen",
      note="Keine Bark deckt das ab - hier lohnt sich der Zeilenbau am meisten. q202"
           " fuellt die Kategorie, die vorher leer war.",
      fams=[], picks=["Umgebung / Aussicht"], judy=[], v=[], pairs=[]),

 dict(key="zustimmung", title="Zustimmung",
      when="V schlaegt etwas vor, Judy geht mit",
      note="Keine Bark deckt das ab.",
      fams=[], picks=["Zustimmung"], judy=[], v=[], pairs=[]),

 dict(key="wasser", title="Wasser und Schwimmen",
      when="Tauchen, Schwimmen, der See",
      note="Der gemeinsame Rueckzugsort - und die einzige Situation, in der Judy die"
           " Fuehrung hat. Keine Bark deckt das ab, jede Zeile muss gebaut werden.",
      fams=[], picks=["Wasser / Schwimmen"],
      judy=["1a6cc1fb6c2fc000", "1a6ce949fa2fc004", "135dba0e2a2fc000",
            "1be51b21f02b6000", "18a6e78c9e2b6000"],
      v=["19c6ddabf55b3000", "1a6181b1812fc000"],
      pairs=[("Weiter raus",
              [("J", "q", "1a6ce949fa2fc004"), ("V", "qv", "1a6181b1812fc000")],
              "Ihre Einladung, Vs Zusage - beide aus derselben Tauchquest."),
             ("Nicht allein abtauchen",
              [("J", "q", "1be51b21f02b6000"), ("J", "q", "135dba0e2a2fc000")],
              "Erst die Warnung, dann das Heranwinken. Sie fuehrt hier.")]),

 dict(key="wohnung", title="Wohnung und Uebernachtung",
      when="V ist bei ihr zu Hause, es wird spaet, jemand bleibt",
      note="Die Kategorie fehlte in allen drei Vorgaengerdokumenten, obwohl das"
           " Material vollstaendig da ist - vom Schluessel ueber den Kaffee bis zur"
           " Couch. Naeher an einer Beziehung als jede Liebeserklaerung.",
      fams=[], picks=[],
      judy=["18795a0a822fc000", "18feb70a322b600c", "1a676388f12fc000",
            "1a96129b222b6000", "18a2fa98762fc004", "18a2fa98762fc00c",
            "1a04f187642fc000", "18795a9ae52fc000"],
      v=["1532045272401000", "39b494eb948bb000", "1b54b12ed62fc004"],
      pairs=[("Der Schluessel",
              [("J", "q", "18795a0a822fc000"), ("V", "qv", "1532045272401000")],
              "Erst das Vertrauen, dann das vorsichtige Nachfassen."),
             ("Unser Nest fuer heut Nacht",
              [("J", "q", "18feb70a322b600c"), ("V", "qv", "39b494eb948bb000")],
              "Ihre Ansage, Vs Zustimmung. Kein Wort zu viel."),
             ("Durchs Fenster statt durch die Tuer",
              [("J", "q", "1a04f187642fc000"), ("V", "qv", "1b54b12ed62fc004")],
              "Sie zieht V auf, V entschuldigt sich halbherzig."),
             ("Kaffee, endlich",
              [("J", "q", "1a676388f12fc000"), ("V", "qv", "1a6769eccf2fc000"),
               ("J", "q", "1a96129b222b6000")],
              "Drei Zeilen, die zusammen einen ganzen Abend andeuten."),
             ("Es wird spaet",
              [("J", "q", "18a2fa98762fc004"), ("J", "q", "18a2fa98762fc00c")],
              "Die Feststellung und das Angebot. Dazwischen gehoert eine Pause.")]),

 dict(key="naehe", title="Tiefe Naehe",
      when="Nur nach abgeschlossener Romanze - nie im Ambient-Pool",
      note="Diese Zeilen tragen Gewicht und vertragen keine Wiederholung. Sie gehoeren an"
           " ein Ereignis, nicht an einen Zufallsgenerator.",
      fams=[], picks=["Zuneigung / Naehe"],
      judy=["175e1a1cba386000", "1401fd943a2fc000", "18fe75e7ff3bc000",
            "197a02720e2b6000", "1878a052fd2fc000"],
      v=["1b3506911a62301c", "126b36bcba404000", "18e94ba7da29f000"],
      pairs=[("Sie sagt es",
              [("J", "q", "175e1a1cba386000"), ("V", "qv", "1b3506911a62301c")],
              "Hoechstens einmal. Danach nie wieder aus dem Zufallspool."),
             ("Egal was kommt",
              [("J", "q", "1401fd943a2fc000"), ("V", "qv", "126b36bcba404000")],
              "Ihre Angst zuerst, dann Vs Zusage. Nur an einem echten Wendepunkt.")]),

 dict(key="abschied", title="Abschied",
      when="Ende einer Begleitung oder eines Anrufs",
      note="Nur am tatsaechlichen Ende, nie als Ambient-Zeile.",
      fams=[], picks=[],
      judy=["1897d495012b6000", "18982e23922b6000", "1b0b9169282b6000"],
      v=["1a0a374e852fc000"],
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
    st = {"J": 0, "V": 0, "leih": 0, "namen": [], "used": set(), "barks": set(),
          "vbarks": set()}
    body = []

    for c in CATEGORIES:
        body.append("\n## %s\n" % c["title"])
        body.append("**Wann:** %s\n" % c["when"])
        body.append("%s\n" % c["note"])

        judy = [("b", n) for n in _fam_barks(c["fams"], d)]
        seen = set(n for _, n in judy)
        for cat in c["picks"]:
            for h in d["picks"].get(cat, []):
                k, ref = _normalize("q", h, d)
                if ref not in seen:
                    seen.add(ref); judy.append((k, ref))
        for h in c["judy"]:
            k, ref = _normalize("q", h, d)
            if ref not in seen:
                seen.add(ref); judy.append((k, ref))
        vlines = [("qv", h) for h in c["v"]]

        for label, refs in (("Judy", judy), ("V", vlines)):
            if not refs:
                continue
            body.append("### %s\n" % label)
            body.append("| Zeile | Dauer | Status | Quelle |")
            body.append("|---|---|---|---|")
            for kind, ref in refs:
                kind, ref = _normalize(kind, ref, d)
                r = _resolve(kind, ref, d)
                st["J" if label == "Judy" else "V"] += 1
                st["used"].add(ref)
                if r["status"] == "Bark":
                    st["barks" if label == "Judy" else "vbarks"].add(ref)
                if "Leih" in r["status"]:
                    st["leih"] += 1
                if r["fremd"]:
                    st["namen"].append((r["text"], r["fremd"]))
                body.append("| %s | %s | `%s` | `%s` |"
                            % (r["text"], r["dur"], r["status"], r["src"]))
            body.append("")

        if not judy and not vlines:
            body.append("*Noch nichts einsortiert.*\n")
        if c["pairs"]:
            body.append("### Wortwechsel\n")
            for title, seq, why in c["pairs"]:
                allein = len(set(sp for sp, _, _ in seq)) == 1
                body.append("**%s**%s\n"
                            % (title, "  <sub>Zeilenfolge, nur Judy</sub>"
                               if allein else ""))
                for spk, kind, ref in seq:
                    kind, ref = _normalize(kind, ref, d)
                    r = _resolve(kind, ref, d)
                    st["used"].add(ref)
                    body.append("- **%s:** %s  <sub>%s &middot; `%s`</sub>"
                                % ("JUDY" if spk == "J" else "V", r["text"],
                                   r["dur"], r["ref"]))
                body.append("")
                body.append("%s\n" % why)

    npairs = sum(len(c["pairs"]) for c in CATEGORIES)
    out = ["# Bark- und Zeilen-Matrix\n",
           "Der **eine** Bestand: welche Zeile in welcher Situation, Judy und V.",
           "Fruehere MATRIX, PAIRS und RELATIONSHIP sind hier zusammengefuehrt.\n",
           "Text, Dauer und Lipsync-Lage werden nachgeschlagen, nicht gepflegt. Erweitern",
           "heisst: eine Id in `tools/build_matrix.py` eintragen und neu erzeugen. Eine",
           "unbekannte Id bricht den Lauf ab - hier steht nichts Unbelegtes.\n",
           "**Bestand:** %d Judy-Eintraege und %d V-Zeilen in %d Situationen, dazu %d"
           % (st["J"], st["V"], len(CATEGORIES), npairs),
           "Wortwechsel. Alle %d Judy-Barks sind einsortiert; %d Judy-Zeilen"
           % (len(st["barks"]), st["leih"]),
           "brauchen geliehenes Lipsync, der Rest sitzt.\n",
           "## Woher eine Zeile stammt, zaehlt nicht\n",
           "Der Ordner sagt nichts ueber die Eignung - nur der Wortlaut tut das. Vs",
           "\"Ich hab dich echt vermisst\" wurde fuer Panams Quest aufgenommen, nennt aber",
           "keinen Namen und kann ebenso gut Judy gelten. Ausgeschlossen wird deshalb",
           "maschinell: nennt eine Zeile eine andere Figur, faellt sie heraus. Geprueft",
           "wird gegen %d Namen.\n" % len(FREMDE_NAMEN),
           "## Was die Sichtung ergeben hat\n",
           "Alle 816 eigenstaendigen Szenen-Zeilen wurden durchgelesen. Brauchbar als",
           "Begleiter-Zeile sind davon rund **110**. Der Rest handelt **von der Quest** -",
           "Evelyn, Fingers, Maiko, das Clouds - und funktioniert ausserhalb seines",
           "Zusammenhangs nicht, egal wie gut er klingt. Die 1104 Quest-Zeilen sind also",
           "kein Reservoir von 1104 einsetzbaren Zeilen.\n",
           "Der vollstaendige Bestand steht in [JUDY_LINES.md](JUDY_LINES.md) und",
           "[data/v_ALL_de.md](data/v_ALL_de.md) - hier ist nur, was gesichtet ist.\n",
           "## Lesart\n",
           "| Kennung | Bedeutung |", "|---|---|",
           "| `Bark` | liegt in `vset_judy` bzw. `vset_v` - sofort abspielbar |",
           "| `Zeile` | Questzeile, per Generator baubar, Lipsync sitzt |",
           "| `Zeile+Leih` | Animation laeuft ueber eine Sekunde nach - fremdes Lipsync |",
           "| `Zeile?` | keine Animation im Bestand - Lipsync ungeprueft |",
           "| `VVF` | Vs Seite, ueber das V Voice Framework - kein Lipsync noetig |",
           "| `VVF frei` | dito, aber aus einer Szene ohne Judy - freie"
           " Neukombination, kein Anschluss an ein Gespraech |"]
    out += body

    rest = sorted(set(d["barkj"]) - st["used"])
    out.append("\n## Barks ohne Situation\n")
    if rest:
        out.append("Noch nicht einsortiert - keine geht verloren.\n")
        for n in rest:
            out.append("- `%s` (%.2fs) %s" % (n, d["barkj"][n]["dur"],
                                              _q(d["barkj"][n]["text"])))
    else:
        out.append("Keine - alle %d Judy-Barks sind einsortiert." % len(d["barkj"]))

    out.append("\n## Unter Vorbehalt\n")
    out.append("Nicht wegen der Herkunft aussortiert, sondern wegen des Inhalts.\n")
    out.append("| Zeile | Warum |")
    out.append("|---|---|")
    for kind, ref, why in RISKY:
        out.append("| %s | %s |" % (_resolve(kind, ref, d)["text"], why))

    out.append("\n## Was noch fehlt\n")
    out.append("* **Vs Barks** sind nur dort einsortiert, wo ein Wortwechsel sie braucht."
               " 160 gemessene Zeilen liegen in `data/vset_v_measured.json`.")
    out.append("* **Zustandslogik** - welche Situation ab welchem Beziehungsstand offen"
               " ist, steht noch nicht fest.")
    out.append("* **Abklingzeiten** - die Vorschlaege nennen Werte, geprueft ist keiner.")
    out.append("* **Dauern fuer Vs Zeilen** fehlen groesstenteils: `durations.json` deckt"
               " bisher nur die Szenen mit Judy ab.")

    p = os.path.join(HERE, "DIALOG_MATRIX.md")
    open(p, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("Situationen %d | Judy %d | V %d | Wortwechsel %d"
          % (len(CATEGORIES), st["J"], st["V"], npairs))
    print("Judy-Barks %d von %d | V-Barks %d | Leih-Lipsync %d"
          % (len(st["barks"]), len(d["barkj"]), len(st["vbarks"]), st["leih"]))
    if rest:
        print("ohne Situation: %s" % ", ".join(rest))
    if st["namen"]:
        print("!! nennt eine andere Figur:")
        for t, n in st["namen"]:
            print("   %-12s %s" % (n, t[:60]))
    print("geschrieben: DIALOG_MATRIX.md (%d KB)" % (os.path.getsize(p) // 1024))


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
                anim=js("anim_durations.json"), picks=js("matrix_picks.json"))


def _fam_barks(fams, d):
    """Alle Barks der genannten Familien, laengste zuerst."""
    out = []
    for f in fams:
        hits = [n for n in d["barkj"]
                if n == f or n.startswith(f + "_var_")
                or (f == "follow_me" and n.startswith("follow_me"))]
        out += sorted(hits, key=lambda n: -d["barkj"][n]["dur"])
    seen, uniq = set(), []
    for n in out:
        if n not in seen:
            seen.add(n); uniq.append(n)
    return uniq


def _normalize(kind, ref, d):
    """Questzeilen aus `vset_judy` sind in Wahrheit Barks - dann auch so fuehren.

    Sonst steht "Bin bei dir." zweimal da: als Bark mit 1.4 s und als Questzeile mit
    1.0 s, weil die Dauer im Szenenknoten und die gemessene Bark auseinandergehen.

    Fuer V gilt dasselbe mit `vset_v`: 136 Zeilen im V-Dump stammen von dort und sind
    in Wahrheit Barks - mit gemessener Dauer statt gar keiner.
    """
    if kind not in ("q", "qv"):
        return kind, ref
    src, tab, bk = ((d["jud"], d["barkj"], "b") if kind == "q"
                    else (d["vee"], d["barkv"], "bv"))
    szene = "vset_judy" if kind == "q" else "vset_v"
    r = src.get(str(int(ref, 16)))
    if not r or r.get("scene") != szene:
        return kind, ref
    #  Der Dump fuehrt Varianten als "A | B", die Voicesets nur die erste. Ohne den
    #  Schnitt findet "Sorry. Ist ein Notfall. | Sorry. Ist n Notfall." seine Bark nicht.
    def kern(x):
        return (x or "").split("|")[0].strip()

    t = kern(r.get("text"))
    for name, e in tab.items():
        if kern(e["text"]) == t:
            return bk, name
    return kind, ref


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
                "src": ref, "ref": ref, "fremd": _fremd(e["text"])}
    src = d["jud"] if kind == "q" else d["vee"]
    key = str(int(ref, 16))
    if key not in src:
        raise SystemExit("!! Id nicht im %s-Bestand: %s"
                         % ("Judy" if kind == "q" else "V", ref))
    r = src[key]
    rec = d["dur"].get(key)
    #  100 ms ist keine Zeile, sondern ein Platzhalter im Szenenknoten. Als "0.1 s"
    #  auszugeben behauptet eine Messung, die es nicht gibt.
    ms = rec["dur"] if rec and rec["dur"] > 200 else None
    if kind == "qv":
        scene = r.get("scene") or ""
        status = "VVF" if any(j in scene for j in JUDY_SZENEN) else "VVF frei"
    elif not ms:
        status = "Zeile?"
    else:
        a = d["anim"].get("f_%016X" % int(key))
        status = ("Zeile?" if not a
                  else "Zeile+Leih" if a["ms"] - ms > WARN_MS else "Zeile")
    text = r.get("text") or "(ohne Untertitel)"
    return {"text": _q(text), "dur": "%.1f s" % (ms / 1000.0) if ms else "?",
            "status": status, "src": "%s %s" % (ref, r.get("scene", "")),
            "ref": ref, "fremd": _fremd(text)}


def _q(t):
    return t.replace("|", "/").strip()


main()
