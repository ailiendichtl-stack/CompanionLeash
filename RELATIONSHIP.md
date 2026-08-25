# Judy und V - Beziehungsdialog

Der zentrale Bestand. Zwei Vorschlagsdokumente sind hier zusammengefuehrt
und **gegen die echten Daten geprueft**: Text, Sprecher, Dauer und
Lipsync-Lage kommen aus den Dumps, nicht aus dem Vorschlag.

Erweitern heisst: eine Id in `tools/build_relationship.py` eintragen und
neu erzeugen. Eine unbekannte Id bricht den Lauf ab - hier steht nichts
Unbelegtes.

**Bestand:** 75 Judy-Zeilen und 30 V-Zeilen in 12 Kategorien, dazu 30
Wortwechsel. 13 Eintraege sind sofort spielbare Barks, 3 Judy-Zeilen
brauchen geliehenes Lipsync.

## Woher eine Zeile stammt, zaehlt nicht

Der Ordner sagt nichts ueber die Eignung - nur der Wortlaut tut das. Vs
"Ich hab dich echt vermisst" wurde fuer Panams Quest aufgenommen, nennt
aber keinen Namen und kann damit ebenso gut Judy gelten. Ausgeschlossen
wird deshalb maschinell: nennt eine Zeile eine andere Figur, faellt sie
heraus. Geprueft wird gegen 20 Namen.

## Lesart

| Kennung | Bedeutung |
|---|---|
| `Bark` | liegt in `vset_judy` bzw. `vset_v` - sofort abspielbar |
| `Zeile` | Questzeile, per Generator baubar, Lipsync sitzt |
| `Zeile+Leih` | Animation laeuft ueber eine Sekunde nach - fremdes Lipsync |
| `Zeile?` | keine Animation im Bestand - Lipsync ungeprueft |
| `VVF` | Vs Seite, ueber das V Voice Framework - kein Lipsync noetig |

## Wiedersehen und Rueckkehr

**Wann:** V kommt nach laengerer Abwesenheit zurueck oder meldet sich

Der Bark-Bestand deckt das Funktionale ab. Was fehlte, ist die Fassung, in der sie zugibt, dass sie V vermisst hat.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hey, V. | 1.1 s | `Bark` | `greeting` |
| Oh, hey! | 1.4 s | `Bark` | `greeting_var_1` |
| Du bist zurück. | 1.4 s | `Bark` | `return_answer` |
| Worüber hatten wir geredet? | 2.0 s | `Bark` | `return_answer_var_1` |
| Woher weißt du immer, wenn du mir fehlst? | 3.1 s | `Zeile` | `2ffdc7962d571000 judy_default` |
| Hoo, ich bin nur froh, dass du überhaupt an mich denkst. | 4.2 s | `Zeile` | `1893611d242b6000 sq030_00_holocall` |
| Mich auch. Ich wurde sogar schon gefragt, warum ich so strahle. | 4.8 s | `Zeile` | `1b07d5a1472b6000 mq055_05_downtown` |
| Ich lass es langsam angehen. Aber ich mach mich bald wieder an die Arbeit. Hab ’ne Idee für ’ne experimentelle Virtu-Serie. | 7.0 s | `Zeile` | `1b07ecef852b6000 mq055_05_downtown` |
| Gut, dass du da bist. | 1.9 s | `Zeile` | `1b2f276faf2fc000 q105_07_judy_braindance` |
| Ich bin froh, dass du da bist. | 2.9 s | `Zeile+Leih` | `39669188b9a4e000 mq055_01_megabuilding` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hey, Judy. Wie geht’s dir? | 3.4 s | `VVF` | `1811545ef42fc000 sq026_02_holocall_judy` |
| Ich wollte nur mal hören, wie’s dir geht. Alles okay? | ? | `VVF` | `1ab41f674b2ef000 sq018_00_mama_welles_holocall` |
| Ich hab dich echt vermisst. | ? | `VVF` | `1a04d435ff2c5000 sq027_04_preparations_panam` |
| Ach, nichts Besonderes. Würde lieber wissen, wie’s dir so ergangen ist. | 4.0 s | `VVF` | `1b06fde31b2b6000 judy_default` |

### Wortwechsel

**Sie gibt es zuerst zu**

- **JUDY:** Woher weißt du immer, wenn du mir fehlst?  <sub>3.1 s</sub>
- **V:** Hey, Judy. Wie geht’s dir?  <sub>3.4 s</sub>

Judy fragt, V antwortet beilaeufig - der Kontrast macht die Zeile.

**V ruft nur so an**

- **V:** Ich wollte nur mal hören, wie’s dir geht. Alles okay?  <sub>?</sub>
- **JUDY:** Hoo, ich bin nur froh, dass du überhaupt an mich denkst.  <sub>4.2 s</sub>

Ein Anruf ohne Anlass ist die Geste; ihre Antwort quittiert sie.

**Beide geben es zu**

- **V:** Ich hab dich echt vermisst.  <sub>?</sub>
- **JUDY:** Mich auch. Ich wurde sogar schon gefragt, warum ich so strahle.  <sub>4.8 s</sub>

Ihre Antwort setzt Vs Gestaendnis voraus - hier bekommt sie es.

**V weicht aus, Judy laesst es zu**

- **V:** Ach, nichts Besonderes. Würde lieber wissen, wie’s dir so ergangen ist.  <sub>4.0 s</sub>
- **JUDY:** Ich lass es langsam angehen. Aber ich mach mich bald wieder an die Arbeit. Hab ’ne Idee für ’ne experimentelle Virtu-Serie.  <sub>7.0 s</sub>

V dreht die Frage weg, Judy geht darauf ein statt nachzubohren.


## Judy meldet sich von selbst

**Wann:** Selten, ohne Anlass - sie ruft an, weil sie an V gedacht hat

Die groesste Luecke im bisherigen Bestand. Judy ist dort fast immer die Reagierende. Diese Zeilen drehen das um.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hab grad an dich gedacht. Und ehe du fragst ... In meinen Gedanken warst du nackt. | 5.7 s | `Zeile` | `1afc08ecff2fc000 mq055_04_heywood` |
| Für dich hab ich den ganzen Tag. | 2.3 s | `Zeile` | `1b07e0e36d2b6000 mq055_05_downtown` |
| Wir haben alle Zeit der Welt. | 1.9 s | `Zeile` | `1b0791cfae2b6000 mq055_05_downtown` |
| Ich bin für dich da, V. Ruf jederzeit an. | 3.2 s | `Zeile` | `1b0b9169282b6000 judy_default` |
| Kommst du vorbei? | 1.3 s | `Zeile` | `181ba067292fc000 sq026_09_holocall_judy` |
| Wenn du das willst ... Oder komm einfach vorbei, wenn du magst. | 4.9 s | `Zeile` | `18795a9ae52fc000 sq030_11_morning` |
| Oh, eh ich’s vergesse: Da hat so ’ne Elizabeth angerufen. Hat wohl einen Job für jemanden, der ein Auge für Virtus hat. | 7.6 s | `Zeile` | `1afc12f00d2fc000 judy_default` |
| Wollte dich um ’nen Gefallen bitten. | 2.4 s | `Zeile` | `1974ca6f6d2b6000 sq030_00_holocall` |
| Aber deswegen ruf ich nicht an. Ich will dich um einen Gefallen bitten. | 5.3 s | `Zeile` | `1a67b32f202b6000 sq030_00_holocall` |
| Gern. Passt mir gut, ich sitz grad eh am Steuer. | 3.7 s | `Zeile` | `1b07df75762b6000 mq055_05_downtown` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Und? Was treibst du so? | 2.1 s | `VVF` | `187e5cd1722fc000 mq055_05_downtown` |
| Was gibt’s Neues bei den Mox? | 1.7 s | `VVF` | `1a9f1202962fc004 mq055_05_downtown` |
| Lass uns noch ein bisschen reden, bevor ich wieder irgendwohin muss. | 4.4 s | `VVF` | `1afc00a4fb2fc004 mq055_05_downtown` |
| Wenn ich nicht ständig unterwegs wäre, hätten wir beide mehr Zeit zusammen, mehr Spaß ... | 5.6 s | `VVF` | `1afbfff4872fc004 mq055_05_downtown` |

### Wortwechsel

**V hat wenig Zeit, Judy nimmt sie sich**

- **V:** Lass uns noch ein bisschen reden, bevor ich wieder irgendwohin muss.  <sub>4.4 s</sub>
- **JUDY:** Für dich hab ich den ganzen Tag.  <sub>2.3 s</sub>

Vs Zeile bittet um Zeit, Judys Antwort gibt sie ohne Bedingung.

**V bedauert die Entfernung**

- **V:** Wenn ich nicht ständig unterwegs wäre, hätten wir beide mehr Zeit zusammen, mehr Spaß ...  <sub>5.6 s</sub>
- **JUDY:** Wir haben alle Zeit der Welt.  <sub>1.9 s</sub>

Vs Bedauern, ihr Trost - zwei Zeilen, die sich nie begegnet sind.

**Sehr selten: der Flirt vorweg**

- **JUDY:** Hab grad an dich gedacht. Und ehe du fragst ... In meinen Gedanken warst du nackt.  <sub>5.7 s</sub>
- **JUDY:** Für dich hab ich den ganzen Tag.  <sub>2.3 s</sub>

Hoechstens einmal pro Spieltag. Haeufiger verliert die Zeile alles.


## Flirt und Necken

**Wann:** Beziehung steht, Lage ist ruhig

Judy neckt lieber, als dass sie schwaermt. Der Ton bleibt trocken.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Interessante Leute langweilen sich eben selten. | 2.7 s | `Zeile` | `189736fe942b6000 sq030_00_holocall` |
| Da haben sich zwei gefunden. | 2.5 s | `Zeile` | `1812474b462b6000 q105_06c_finding_studio` |
| Wenn man das bedenkt, siehst du sogar sensationell aus. / Ach, komm schon, red keinen Blödsinn. | 3.9 s | `Zeile` | `189c5847c42b6000 sq030_01_dam_meetup` |
| Du hast echt Talent, Kleines. | 2.1 s | `Zeile` | `39675dc8759ce000 mq055_04_heywood` |
| Du hast meine Pläne ruiniert, weißt du? | 2.8 s | `Zeile` | `1a9f63e7252b6000 sq030_11_morning` |
| Aber vertrau mir, es wird sich lohnen. | 2.7 s | `Zeile` | `189806a8512b6000 sq030_00_holocall` |
| Ich hab gerade was Komisches gehört ... Klang wie Nörgelei ...? | 5.0 s | `Zeile` | `1a67403cc92fc004 sq030_09_pier` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hey, gilt dein Angebot vom Damm noch? | 4.5 s | `VVF` | `1a9f07a2ab2fc000 judy_default` |
| Vielleicht nur ein Zimmer? | ? | `VVF` | `1532045272401000 q103_15_roadhouse_bar` |

### Wortwechsel

**Lob und Abwehr**

- **JUDY:** Du hast echt Talent, Kleines.  <sub>2.1 s</sub>
- **V:** Du bist die Beste.  <sub>?</sub>

Ihr Lob ist beilaeufig - genau deshalb sitzt es.

**Zwei, die sich verdient haben**

- **JUDY:** Da haben sich zwei gefunden.  <sub>2.5 s</sub>
- **JUDY:** Interessante Leute langweilen sich eben selten.  <sub>2.7 s</sub>

Funktioniert nach etwas, das die beiden zusammen geschafft haben.

**Nur ein Zimmer**

- **V:** Vielleicht nur ein Zimmer?  <sub>?</sub>
- **JUDY:** Aber vertrau mir, es wird sich lohnen.  <sub>2.7 s</sub>

Vs Zeile ist eine Frage ohne Namen - sie traegt in jede Richtung.


## Kaffee, Pizza, Zuhause

**Wann:** V ist bei ihr, nichts Dringendes liegt an

Der staerkste Fund aus beiden Dokumenten. Alltag traegt eine Beziehung glaubhafter als weitere Liebeserklaerungen - und das Material dafuer ist da, samt Vs Antworten.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Ich brüh was auf. | 2.1 s | `Zeile` | `3968743729a71000 mq055_05_downtown` |
| Wie trinkst du deinen? Heh, genau wie ich. | 3.8 s | `Zeile` | `396871fa77a71000 mq055_05_downtown` |
| Ich hab was richtig Großes. Sag’s dir heute Abend. Ach so – was willst du auf deine Pizza? | 6.8 s | `Zeile` | `1a0fbd86992b6000 sq026_07_judys` |
| Igitt. Das sind zwei Wörter, die nicht in denselben Satz gehören. Schon gar nicht auf dieselbe Pizza. Du machst Witze, oder? | 6.5 s | `Zeile` | `1a0fe8a4772b6000 sq026_07_judys` |
| Was?! Und als Nächstes sagst du mir, du atmest nicht gern? Wie kann man keine Pizza mögen? | 5.6 s | `Zeile` | `1a0fe9bfde2b6000 sq026_07_judys` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Schwarz, bitte. | 1.7 s | `VVF` | `1a6769eccf2fc000 sq030_09_pier` |
| Mit ein bisschen Milch. | 1.6 s | `VVF` | `1a676a6b122fc000 sq030_09_pier` |
| Heuschreckensalami. Und ganz viel extra Käse. | 3.9 s | `VVF` | `1a0fd4447d2b6000 sq026_07_judys` |
| Tofu-Thunfisch und Ananasgeschmack. | 2.7 s | `VVF` | `1a0fd5b3d22b6000 sq026_07_judys` |
| Ich könnte die ganze Nacht hierbleiben. | 2.9 s | `VVF` | `39b494eb948bb000 mq055_05_downtown` |

### Wortwechsel

**Kaffee, schwarz**

- **JUDY:** Ich brüh was auf.  <sub>2.1 s</sub>
- **V:** Schwarz, bitte.  <sub>1.7 s</sub>
- **JUDY:** Wie trinkst du deinen? Heh, genau wie ich.  <sub>3.8 s</sub>

Ihre Pointe setzt voraus, dass V vorher geantwortet hat - hier geht sie auf.

**Kaffee, mit Milch**

- **JUDY:** Ich brüh was auf.  <sub>2.1 s</sub>
- **V:** Mit ein bisschen Milch.  <sub>1.6 s</sub>
- **JUDY:** Wie trinkst du deinen? Heh, genau wie ich.  <sub>3.8 s</sub>

Dieselbe Pointe, andere Antwort. Beide Wege muessen funktionieren.

**Streit um Pizza**

- **JUDY:** Ich hab was richtig Großes. Sag’s dir heute Abend. Ach so – was willst du auf deine Pizza?  <sub>6.8 s</sub>
- **V:** Tofu-Thunfisch und Ananasgeschmack.  <sub>2.7 s</sub>
- **JUDY:** Igitt. Das sind zwei Wörter, die nicht in denselben Satz gehören. Schon gar nicht auf dieselbe Pizza. Du machst Witze, oder?  <sub>6.5 s</sub>

Der laengste vollstaendige Wortwechsel im ganzen Bestand.

**Streit um Pizza, kurze Fassung**

- **JUDY:** Ich hab was richtig Großes. Sag’s dir heute Abend. Ach so – was willst du auf deine Pizza?  <sub>6.8 s</sub>
- **V:** Heuschreckensalami. Und ganz viel extra Käse.  <sub>3.9 s</sub>

Wenn die lange Empoerung zu viel ist.

**Bleib noch**

- **V:** Ich könnte die ganze Nacht hierbleiben.  <sub>2.9 s</sub>
- **JUDY:** Für dich hab ich den ganzen Tag.  <sub>2.3 s</sub>

Vs Zeile stammt aus dem Hangout und meint genau das.


## Einladung und Verabredung

**Wann:** Judy schlaegt etwas vor, V sagt zu

Diese Kategorie fehlte bisher ganz.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Klar. Heute Abend in der Hütte am See. Wir sehen uns dort? | 4.1 s | `Zeile` | `1a9f085b672fc000 judy_default` |
| Cool. Heute Abend in der Hütte am See. Lass mich nicht warten. | 4.5 s | `Zeile` | `1a9f0c7fe02fc000 judy_default` |
| Kommst du vorbei? | 1.3 s | `Zeile` | `181ba067292fc000 sq026_09_holocall_judy` |
| Wenn du das willst ... Oder komm einfach vorbei, wenn du magst. | 4.9 s | `Zeile` | `18795a9ae52fc000 sq030_11_morning` |
| Lass mich nicht warten. | 1.4 s | `Zeile` | `39675ce5d69ce000 mq055_04_heywood` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hey, gilt dein Angebot vom Damm noch? | 4.5 s | `VVF` | `1a9f07a2ab2fc000 judy_default` |
| Ich könnte die ganze Nacht hierbleiben. | 2.9 s | `VVF` | `39b494eb948bb000 mq055_05_downtown` |

### Wortwechsel

**Gilt das Angebot noch**

- **V:** Hey, gilt dein Angebot vom Damm noch?  <sub>4.5 s</sub>
- **JUDY:** Klar. Heute Abend in der Hütte am See. Wir sehen uns dort?  <sub>4.1 s</sub>

Vs Zeile fragt woertlich nach - der sauberste Anschluss im Bestand.

**Lass mich nicht warten**

- **JUDY:** Cool. Heute Abend in der Hütte am See. Lass mich nicht warten.  <sub>4.5 s</sub>
- **V:** Ich könnte die ganze Nacht hierbleiben.  <sub>2.9 s</sub>

Ihre Ungeduld und Vs Zusage schliessen die Verabredung ab.


## Sorge und Nachsorge

**Wann:** V ist verletzt, erschoepft oder lange weg gewesen

Erst schimpft sie aus Angst, dann wird sie weich. Diese Reihenfolge ist glaubwuerdiger als reine Fuersorge - und beide Haelften liegen vor.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| V, pass besser auf! Tot nützt du niemandem! | 3.5 s | `Bark` | `player_fallback_var_2` |
| Alles okay? Schnauf mal kurz durch. | 2.8 s | `Bark` | `player_fallback_var_3` |
| Alles in Ordnung, V? | 1.6 s | `Zeile` | `1ef8b0186b42f000 q004_04b_after_tutorial` |
| Alles in Ordnung bei dir? | 1.6 s | `Zeile` | `1f46421f852b6008 sq030_01_dam_meetup` |
| Ganz ruhig, ist alles okay? | 2.1 s | `Zeile` | `28aa62967b4ea000 sq026_08_plan` |
| Ganz ruhig, ist alles okay? | 1.9 s | `Zeile+Leih` | `1f45f8b07b2b6008 sq030_09_pier` |
| Schön langsam atmen. Ruhig. Alles okay, dir geht’s gut. | 4.5 s | `Zeile+Leih` | `1ef8b0c1f442f000 q004_04b_after_tutorial` |
| Denk nicht zu viel drüber nach, okay? | 2.0 s | `Zeile` | `1f4640da642b6000 sq030_01_dam_meetup` |
| Wenn ich irgendwie helfen kann ... egal, wie ... musst du’s nur sagen. | 5.5 s | `Zeile` | `1a33ca85c72b6000 sq026_08_plan` |
| Du kommst mir ... anders vor. Bist irgendwie ... abwesend. Denkst du an Mikoshi? Oder ist es der Job? | 9.9 s | `Zeile` | `14aaba91a329f000 q203_02c_judy` |
| Du bist schon seit ’ner Woche so, V. Ich hab das Gefühl ... du verschweigst mir was. | 5.2 s | `Zeile` | `14aabd878129f000 q203_02c_judy` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Wenn irgendwas ist, ruf mich an, okay? | 2.2 s | `VVF` | `1a0a374e852fc000 sq026_01b_roof` |
| Aber denk dran: Ich bin für dich da, wenn du mich brauchst. Jederzeit. | ? | `VVF` | `198e76d299521000 sq021_11_finale` |

### Wortwechsel

**Schimpfen, dann weich werden**

- **JUDY:** V, pass besser auf! Tot nützt du niemandem!  <sub>3.5 s</sub>
- **JUDY:** Denk nicht zu viel drüber nach, okay?  <sub>2.0 s</sub>

Der Umschlag von Wut zu Sorge ist die ganze Wirkung.

**Ruhig atmen**

- **JUDY:** Alles in Ordnung, V?  <sub>1.6 s</sub>
- **JUDY:** Schön langsam atmen. Ruhig. Alles okay, dir geht’s gut.  <sub>4.5 s</sub>

Nur nach echtem Schaden. Sonst wirkt sie uebergriffig.

**Sie merkt, dass etwas nicht stimmt**

- **JUDY:** Du kommst mir ... anders vor. Bist irgendwie ... abwesend. Denkst du an Mikoshi? Oder ist es der Job?  <sub>9.9 s</sub>
- **V:** Wenn irgendwas ist, ruf mich an, okay?  <sub>2.2 s</sub>
- **JUDY:** Wenn ich irgendwie helfen kann ... egal, wie ... musst du’s nur sagen.  <sub>5.5 s</sub>

Vs Zeile stammt aus Judys eigener Quest und passt woertlich.


## Anerkennung und Stolz

**Wann:** V hat etwas gut gemacht - nicht zwingend im Kampf

Bisher gab es Lob fast nur nach Gefechten.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Du verschwendest keine Munition. Bin beeindruckt. | 3.4 s | `Zeile` | `16bf45bffc2fc000 q105_07_judy_braindance` |
| Du hast echt Talent, Kleines. | 2.1 s | `Zeile` | `39675dc8759ce000 mq055_04_heywood` |
| Genial, oder? | 1.7 s | `Zeile` | `39675eebd79ce000 mq055_05_downtown` |
| Wenn man das bedenkt, siehst du sogar sensationell aus. / Ach, komm schon, red keinen Blödsinn. | 3.9 s | `Zeile` | `189c5847c42b6000 sq030_01_dam_meetup` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Du bist die Beste. | ? | `VVF` | `172a8c16fb502000 q115_04_plan` |
| Du kannst dich auf mich verlassen. | ? | `VVF` | `18c1d0f46c4e6004 mq021_01_briefing` |

### Wortwechsel

**Beeindruckt**

- **JUDY:** Du verschwendest keine Munition. Bin beeindruckt.  <sub>3.4 s</sub>
- **V:** Du kannst dich auf mich verlassen.  <sub>?</sub>

Trockenes Lob, trockene Antwort.


## Gemeinsame Arbeit

**Wann:** Virtu, Tauchen, Technik - sie laesst V an ihrer Arbeit teilhaben

Judy zeigt Zuneigung, indem sie jemanden in ihre Arbeit laesst. Das ist ihr eigentlicher Liebesbeweis, und dafuer gibt es viel Material.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Du, meine Liebe, wirst mit mir eine Virtu machen. / Du, Kumpel, wirst mit mir eine Virtu machen. | 3.5 s | `Zeile` | `189d4f49e02b6000 sq030_01_dam_meetup` |
| Genial, oder? | 1.7 s | `Zeile` | `39675eebd79ce000 mq055_05_downtown` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Klingt nova. Tun wir’s. | 2.4 s | `VVF` | `1a6181b1812fc000 sq030_05_lake_test` |
| Was immer du vorhast, Judy. Ich bin dabei. | 4.3 s | `VVF` | `19c6ddabf55b3000 sq030_05_lake_test` |
| Na gut, ich bin dabei. | 1.8 s | `VVF` | `189793991b2b6000 sq030_00_holocall` |
| Du kannst dich auf mich verlassen. | ? | `VVF` | `18c1d0f46c4e6004 mq021_01_briefing` |

### Wortwechsel

**Sie fragt, V sagt zu**

- **JUDY:** Du, meine Liebe, wirst mit mir eine Virtu machen. / Du, Kumpel, wirst mit mir eine Virtu machen.  <sub>3.5 s</sub>
- **V:** Klingt nova. Tun wir’s.  <sub>2.4 s</sub>

Vs Zusage ist aus derselben Questreihe - Ton und Wortwahl passen.

**V vertraut ihr blind**

- **V:** Was immer du vorhast, Judy. Ich bin dabei.  <sub>4.3 s</sub>
- **JUDY:** Genial, oder?  <sub>1.7 s</sub>

Vs Zeile nennt Judy beim Namen. Der beste Anschluss im ganzen V-Bestand.


## Nach dem Kampf

**Wann:** Gefecht vorbei, beide stehen noch

Bereits gut abgedeckt. Hier steht nur, was den Sieg zu etwas Gemeinsamem macht.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Oh, das war’s. Wir haben’s geschafft. | 2.8 s | `Bark` | `combat_ended_var_1` |
| Sieh uns an. Nicht totzukriegen. | 2.8 s | `Bark` | `combat_ended_var_2` |
| Bin bei dir. | 1.0 s | `Zeile` | `1f3324ae9552a008 vset_judy` |
| Oh, das war’s. Wir haben’s geschafft. | 3.0 s | `Zeile` | `1f3324aeb552a008 vset_judy` |
| Sieh uns an. Nicht totzukriegen. | 2.7 s | `Zeile` | `1f3324aeb752a008 vset_judy` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Du bist die Beste. | ? | `VVF` | `172a8c16fb502000 q115_04_plan` |

### Wortwechsel

**Sieh uns an**

- **JUDY:** Oh, das war’s. Wir haben’s geschafft.  <sub>3.0 s</sub>
- **JUDY:** Sieh uns an. Nicht totzukriegen.  <sub>2.7 s</sub>

Aus dem Sieg wird ein gemeinsames Erlebnis statt einer Meldung.

**Bin bei dir**

- **JUDY:** Bin bei dir.  <sub>1.0 s</sub>
- **V:** Du bist die Beste.  <sub>?</sub>

Sparsam einsetzen - die Zeile traegt viel und nutzt sich schnell ab.


## Warten, Troedeln, kleine Reibung

**Wann:** V bleibt zurueck, bricht ab oder kommt zu spaet

Reibung ohne Bruch. Ihre Ungeduld liest sich als Vertrautheit, wenn sie nicht allein steht - deshalb gehoert immer eine Versoehnung dahinter.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Komm schon, V, bleib bei mir. | 2.3 s | `Bark` | `follow_me` |
| Na? Los jetzt! | 1.9 s | `Bark` | `hurry_up_var_1` |
| Wir haben was vor, schon vergessen? | 2.5 s | `Bark` | `hurry_up_var_2` |
| Hab ich dich gelangweilt? | 1.9 s | `Bark` | `interrupt` |
| Okay, wir setzen das später fort. | 2.5 s | `Bark` | `interrupt_var_1` |
| Komm schon, V. Bleib bei mir. | 1.3 s | `Zeile` | `39675fea699ce000 mq055_04_heywood` |
| Lass mich nicht warten. | 1.4 s | `Zeile` | `39675ce5d69ce000 mq055_04_heywood` |
| Du hast meine Pläne ruiniert, weißt du? | 2.8 s | `Zeile` | `1a9f63e7252b6000 sq030_11_morning` |

### Wortwechsel

**Abbruch und Rueckkehr**

- **JUDY:** Hab ich dich gelangweilt?  <sub>1.9 s</sub>
- **JUDY:** Okay, wir setzen das später fort.  <sub>2.5 s</sub>

Zwischen beiden gehoert eine echte Pause - sonst klingt sie schnippisch.

**Du hast meine Plaene ruiniert**

- **JUDY:** Du hast meine Pläne ruiniert, weißt du?  <sub>2.8 s</sub>
- **JUDY:** Aber vertrau mir, es wird sich lohnen.  <sub>2.7 s</sub>

Vorwurf mit einem Augenzwinkern, und gleich der Koeder hinterher.


## Tiefe Naehe

**Wann:** Nur nach abgeschlossener Romanze - nie im Ambient-Pool

Diese Zeilen tragen Gewicht und vertragen keine Wiederholung. Sie gehoeren an ein Ereignis, nicht an einen Zufallsgenerator.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Ich weiß nicht, was ich mache, wenn du nicht mehr da bist. | 2.9 s | `Zeile` | `175e1a1cba386000 q201_05_cabin_day_7` |
| Scheiße ... Ich hab Angst, V. | 4.0 s | `Zeile` | `1401fd943a2fc000 sq026_08_plan` |
| Und solltest du je Hilfe brauchen, du weißt, dass ich für dich da bin, ja? Immer. | 6.8 s | `Zeile` | `18fe75e7ff3bc000 fb_judy` |
| Ich ... will einfach nicht über irgendwas davon nachdenken. Nicht heute. | 5.4 s | `Zeile` | `197a02720e2b6000 sq030_01_dam_meetup` |
| Ist es dein, ähm, blinder Passagier? Wird es schlimmer? | 5.5 s | `Zeile` | `1878a052fd2fc000 sq030_00_holocall` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Ich mag dich auch. Ein Grund mehr, das nicht ... | ? | `VVF` | `1b3506911a62301c sq029_05_morning_after` |
| Ich bin morgen bei dir. Egal, was passiert, wir bleiben zusammen und schaffen es irgendwie. | ? | `VVF` | `126b36bcba404000 q114_05_quiet_place` |
| Ich will dich nicht verlieren, aber ich muss hier bleiben. Ich kann nicht anders leben oder denken. Nicht mehr. | ? | `VVF` | `18e94ba7da29f000 q203_02d_panam` |

### Wortwechsel

**Sie sagt es**

- **JUDY:** Ich weiß nicht, was ich mache, wenn du nicht mehr da bist.  <sub>2.9 s</sub>
- **V:** Ich mag dich auch. Ein Grund mehr, das nicht ...  <sub>?</sub>

Hoechstens einmal. Danach nie wieder aus dem Zufallspool.

**Egal was kommt**

- **JUDY:** Scheiße ... Ich hab Angst, V.  <sub>4.0 s</sub>
- **V:** Ich bin morgen bei dir. Egal, was passiert, wir bleiben zusammen und schaffen es irgendwie.  <sub>?</sub>

Ihre Angst zuerst, dann Vs Zusage. Nur an einem echten Wendepunkt.


## Abschied

**Wann:** Ende einer Begleitung oder eines Anrufs

Nur am tatsaechlichen Ende, nie als Ambient-Zeile.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Bis dann, V. | 1.5 s | `Zeile` | `1897d495012b6000 sq030_00_holocall` |
| Bis dahaaaann! | 1.5 s | `Zeile` | `18982e23922b6000 sq030_00_holocall` |
| Ich bin für dich da, V. Ruf jederzeit an. | 3.2 s | `Zeile` | `1b0b9169282b6000 judy_default` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Wenn irgendwas ist, ruf mich an, okay? | 2.2 s | `VVF` | `1a0a374e852fc000 sq026_01b_roof` |

### Wortwechsel

**Bis dann**

- **JUDY:** Bis dann, V.  <sub>1.5 s</sub>
- **V:** Wenn irgendwas ist, ruf mich an, okay?  <sub>2.2 s</sub>

Kurz halten. Die verspielte Fassung `Bis dahaaaann!` nur selten.


## Unter Vorbehalt

Nicht wegen der Herkunft aussortiert, sondern wegen des Inhalts.

| Zeile | Warum |
|---|---|
| Ich ... bin echt gern mit dir zusammen, River. | spricht River beim Namen an - der einzige echte Ausschluss |
| Es ist seltsam, aber ... Mir ist gerade klar geworden, dass ich nie hierher gehört hab. In diese Stadt. | Endgame-Abschied aus Night City; Anim ausserdem +2886 ms |
| Wenn du kannst ... gib mir nur irgendein Zeichen, dass ... dass du lebst und alles okay ist ... Bitte ... | Nachricht an eine Sterbende - nur im passenden Ende |
| Hab grad an dich gedacht. Und ehe du fragst ... In meinen Gedanken warst du nackt. | sehr direkt; nur nach Romanze und hoechstens einmal taeglich |
| Ich will dich nicht verlieren, aber ich muss hier bleiben. Ich kann nicht anders leben oder denken. Nicht mehr. | zweite Haelfte bindet sich ans Bleiben in Night City |

## Was noch fehlt

* **Vs Barks** sind noch nicht einsortiert - 160 gemessene Zeilen liegen in
  `data/vset_v_measured.json` und warten auf dieselbe Durchsicht.
* **Zustandslogik** - welche Kategorie ab welchem Beziehungsstand offen
  ist, steht noch nicht fest.
* **Abklingzeiten** - die Vorschlaege nennen Werte, geprueft ist keiner.
* **Dauern fuer Vs Zeilen** fehlen groesstenteils: `durations.json` deckt
  bisher nur die Szenen mit Judy ab. Fuer die Taktung der Wortwechsel
  muessten die uebrigen Szenen noch eingelesen werden.
* **Der volle Bestand** steht weiter in [LINES.md](LINES.md) und
  [data/v_ALL_de.md](data/v_ALL_de.md) - hier ist nur, was gesichtet ist.
