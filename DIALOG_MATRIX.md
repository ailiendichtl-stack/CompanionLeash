# Bark- und Zeilen-Matrix

Der **eine** Bestand: welche Zeile in welcher Situation, Judy und V.
Fruehere MATRIX, PAIRS und RELATIONSHIP sind hier zusammengefuehrt.

Text, Dauer und Lipsync-Lage werden nachgeschlagen, nicht gepflegt. Erweitern
heisst: eine Id in `tools/build_matrix.py` eintragen und neu erzeugen. Eine
unbekannte Id bricht den Lauf ab - hier steht nichts Unbelegtes.

**Bestand:** 262 Judy-Eintraege und 40 V-Zeilen in 21 Situationen, dazu 68
Wortwechsel. Alle 63 Judy-Barks sind einsortiert; 9 Judy-Zeilen
brauchen geliehenes Lipsync, der Rest sitzt.

## Woher eine Zeile stammt, zaehlt nicht

Der Ordner sagt nichts ueber die Eignung - nur der Wortlaut tut das. Vs
"Ich hab dich echt vermisst" wurde fuer Panams Quest aufgenommen, nennt aber
keinen Namen und kann ebenso gut Judy gelten. Ausgeschlossen wird deshalb
maschinell: nennt eine Zeile eine andere Figur, faellt sie heraus. Geprueft
wird gegen 20 Namen.

## Was die Sichtung ergeben hat

Alle 816 eigenstaendigen Szenen-Zeilen wurden durchgelesen. Brauchbar als
Begleiter-Zeile sind davon rund **110**. Der Rest handelt **von der Quest** -
Evelyn, Fingers, Maiko, das Clouds - und funktioniert ausserhalb seines
Zusammenhangs nicht, egal wie gut er klingt. Die 1104 Quest-Zeilen sind also
kein Reservoir von 1104 einsetzbaren Zeilen.

Der vollstaendige Bestand steht in [JUDY_LINES.md](JUDY_LINES.md) und
[data/v_ALL_de.md](data/v_ALL_de.md) - hier ist nur, was gesichtet ist.

## Lesart

| Kennung | Bedeutung |
|---|---|
| `Bark` | liegt in `vset_judy` bzw. `vset_v` - sofort abspielbar |
| `Zeile` | Questzeile, per Generator baubar, Lipsync sitzt |
| `Zeile+Leih` | Animation laeuft ueber eine Sekunde nach - fremdes Lipsync |
| `Zeile?` | keine Animation im Bestand - Lipsync ungeprueft |
| `VVF` | Vs Seite, ueber das V Voice Framework - kein Lipsync noetig |
| `VVF frei` | dito, aber aus einer Szene ohne Judy - freie Neukombination, kein Anschluss an ein Gespraech |

## Ankunft und Wiedersehen

**Wann:** V kommt an, kehrt zurueck oder meldet sich

Die Barks decken das Funktionale ab. Was fehlte, ist die Fassung, in der sie zugibt, dass sie V vermisst hat - die steht jetzt daneben.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Worüber hatten wir geredet? | 2.0 s | `Bark` | `return_answer_var_1` |
| Du bist zurück. | 1.4 s | `Bark` | `return_answer` |
| Du bist zurück. | 1.4 s | `Bark` | `return_answer_var_2` |
| Oh, hey! | 1.4 s | `Bark` | `greeting_var_1` |
| Hey, V. | 1.1 s | `Bark` | `greeting` |
| Hey, V. | 1.1 s | `Bark` | `greeting_var_2` |
| Hey, V! Was geht? | 2.1 s | `Zeile` | `18d9a13a264ea004 fb_judy` |
| Hey, da bist du ja. | 2.5 s | `Zeile` | `0f339c53952e3010 q004_03_this_is_judy` |
| Gut, dass du da bist. | 1.9 s | `Zeile` | `1b2f276faf2fc000 q105_07_judy_braindance` |
| Okay, ich bin da. | 1.5 s | `Zeile` | `16bf49d3352fc000 q105_07_judy_braindance` |
| Hey V, danke dass du gekommen bist. | 2.8 s | `Zeile` | `1a7712a0b22fc000 sq026_04_maiko` |
| V! Siehst gut aus! / V, du bist echt gekommen. | 2.6 s | `Zeile` | `1826c0c4492fc000 sq030_01_dam_meetup` |
| Wird auch Zeit. | 1.8 s | `Zeile` | `17c0a2ca2c610000 q105_02_lizzy_meet_judy` |
| V! Siehst gut aus. | 3.1 s | `Zeile` | `39668f23c9a4e000 mq055_05_downtown` |
| Ich bin froh, dass du da bist. | 2.9 s | `Zeile+Leih` | `39669188b9a4e000 mq055_01_megabuilding` |
| V, da bist du ja! | 2.2 s | `Zeile` | `1ee881e18b42f000 q202_05_convoy` |
| Woher weißt du immer, wenn du mir fehlst? | 3.1 s | `Zeile` | `2ffdc7962d571000 judy_default` |
| Hoo, ich bin nur froh, dass du überhaupt an mich denkst. | 4.2 s | `Zeile` | `1893611d242b6000 sq030_00_holocall` |
| Mich auch. Ich wurde sogar schon gefragt, warum ich so strahle. | 4.8 s | `Zeile` | `1b07d5a1472b6000 mq055_05_downtown` |
| Ich lass es langsam angehen. Aber ich mach mich bald wieder an die Arbeit. Hab ’ne Idee für ’ne experimentelle Virtu-Serie. | 7.0 s | `Zeile` | `1b07ecef852b6000 mq055_05_downtown` |
| Scheiße, V. Ich dachte, du bist tot. | 4.3 s | `Zeile` | `175e197aaa386000 q201_05_cabin_day_7` |
| Hab Schüsse gehört. Lebst du noch? | 2.2 s | `Zeile` | `1bd4dab9c42b6000 q105_07_judy_braindance` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hey, Judy. Wie geht’s dir? | 3.4 s | `VVF` | `1811545ef42fc000 sq026_02_holocall_judy` |
| Ich wollte nur mal hören, wie’s dir geht. Alles okay? | ? | `VVF frei` | `1ab41f674b2ef000 sq018_00_mama_welles_holocall` |
| Ich hab dich echt vermisst. | ? | `VVF frei` | `1a04d435ff2c5000 sq027_04_preparations_panam` |
| Ach, nichts Besonderes. Würde lieber wissen, wie’s dir so ergangen ist. | 4.0 s | `VVF` | `1b06fde31b2b6000 judy_default` |

### Wortwechsel

**Sie gibt es zuerst zu**

- **JUDY:** Woher weißt du immer, wenn du mir fehlst?  <sub>3.1 s &middot; `2ffdc7962d571000`</sub>
- **V:** Hey, Judy. Wie geht’s dir?  <sub>3.4 s &middot; `1811545ef42fc000`</sub>

Judy fragt, V antwortet beilaeufig - der Kontrast macht die Zeile.

**V ruft nur so an**

- **V:** Ich wollte nur mal hören, wie’s dir geht. Alles okay?  <sub>? &middot; `1ab41f674b2ef000`</sub>
- **JUDY:** Hoo, ich bin nur froh, dass du überhaupt an mich denkst.  <sub>4.2 s &middot; `1893611d242b6000`</sub>

Ein Anruf ohne Anlass ist die Geste; ihre Antwort quittiert sie.

**Beide geben es zu**

- **V:** Ich hab dich echt vermisst.  <sub>? &middot; `1a04d435ff2c5000`</sub>
- **JUDY:** Mich auch. Ich wurde sogar schon gefragt, warum ich so strahle.  <sub>4.8 s &middot; `1b07d5a1472b6000`</sub>

Ihre Antwort setzt Vs Gestaendnis voraus - hier bekommt sie es.

**V weicht aus, Judy laesst es zu**

- **V:** Ach, nichts Besonderes. Würde lieber wissen, wie’s dir so ergangen ist.  <sub>4.0 s &middot; `1b06fde31b2b6000`</sub>
- **JUDY:** Ich lass es langsam angehen. Aber ich mach mich bald wieder an die Arbeit. Hab ’ne Idee für ’ne experimentelle Virtu-Serie.  <sub>7.0 s &middot; `1b07ecef852b6000`</sub>

V dreht die Frage weg, Judy geht darauf ein statt nachzubohren.

**Zurueck im Gespraech**

- **V:** Also, wo waren wir?  <sub>2.0 s &middot; `return_var_2`</sub>
- **JUDY:** Du bist zurück.  <sub>1.4 s &middot; `return_answer`</sub>

Der knappste Wiedereinstieg, beide Seiten als Bark.

**Zurueck im Gespraech, laenger**

- **V:** Okay, wieder da. Schieß los.  <sub>2.4 s &middot; `return_var_4`</sub>
- **JUDY:** Worüber hatten wir geredet?  <sub>2.0 s &middot; `return_answer_var_1`</sub>

Dieselbe Figur mit mehr Luft.

**Dank nach Hilfe**

- **V:** Weiß ich zu schätzen. Danke.  <sub>2.0 s &middot; `scene_thanks_var_2`</sub>
- **JUDY:** Du bist zurück.  <sub>1.4 s &middot; `return_answer`</sub>

Funktioniert auch ausserhalb des Wiedersehens.


## Judy meldet sich von selbst

**Wann:** Selten, ohne Anlass - sie ruft an, weil sie an V gedacht hat

Die groesste Luecke im bisherigen Bestand. Judy war fast immer die Reagierende. Keine Bark deckt das ab.

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
| Du kommst mir ... anders vor. Bist irgendwie ... abwesend. Denkst du an Mikoshi? Oder ist es der Job? | 9.9 s | `Zeile` | `14aaba91a329f000 q203_02c_judy` |
| Du bist schon seit ’ner Woche so, V. Ich hab das Gefühl ... du verschweigst mir was. | 5.2 s | `Zeile` | `14aabd878129f000 q203_02c_judy` |
| Wenn ich irgendwie helfen kann ... egal, wie ... musst du’s nur sagen. | 5.5 s | `Zeile` | `1a33ca85c72b6000 sq026_08_plan` |
| Ich ... muss das verarbeiten, und zwar allein. | 6.6 s | `Zeile` | `1a82306830610000 sq026_15_end` |
| Kann ich verstehen, V. Ehrlich gesagt würde das auch ’ne Weile dauern. | 4.1 s | `Zeile+Leih` | `1afd6f18ec2fc000 sq026_02_holocall_judy` |
| Aber wenn du Zeit hast, sag mir Bescheid, okay? | ? | `Zeile?` | `1b971f17262b6000 sq026_02_holocall_judy` |
| Denk nicht zu viel drüber nach, okay? | 2.0 s | `Zeile` | `1f4640da642b6000 sq030_01_dam_meetup` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Und? Was treibst du so? | 2.1 s | `VVF` | `187e5cd1722fc000 mq055_05_downtown` |
| Was gibt’s Neues bei den Mox? | 1.7 s | `VVF` | `1a9f1202962fc004 mq055_05_downtown` |
| Lass uns noch ein bisschen reden, bevor ich wieder irgendwohin muss. | 4.4 s | `VVF` | `1afc00a4fb2fc004 mq055_05_downtown` |
| Wenn ich nicht ständig unterwegs wäre, hätten wir beide mehr Zeit zusammen, mehr Spaß ... | 5.6 s | `VVF` | `1afbfff4872fc004 mq055_05_downtown` |

### Wortwechsel

**V hat wenig Zeit, Judy nimmt sie sich**

- **V:** Lass uns noch ein bisschen reden, bevor ich wieder irgendwohin muss.  <sub>4.4 s &middot; `1afc00a4fb2fc004`</sub>
- **JUDY:** Für dich hab ich den ganzen Tag.  <sub>2.3 s &middot; `1b07e0e36d2b6000`</sub>

Vs Zeile bittet um Zeit, Judys Antwort gibt sie ohne Bedingung.

**V bedauert die Entfernung**

- **V:** Wenn ich nicht ständig unterwegs wäre, hätten wir beide mehr Zeit zusammen, mehr Spaß ...  <sub>5.6 s &middot; `1afbfff4872fc004`</sub>
- **JUDY:** Wir haben alle Zeit der Welt.  <sub>1.9 s &middot; `1b0791cfae2b6000`</sub>

Vs Bedauern, ihr Trost - zwei Zeilen, die sich nie begegnet sind.

**Sehr selten: der Flirt vorweg**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Hab grad an dich gedacht. Und ehe du fragst ... In meinen Gedanken warst du nackt.  <sub>5.7 s &middot; `1afc08ecff2fc000`</sub>
- **JUDY:** Für dich hab ich den ganzen Tag.  <sub>2.3 s &middot; `1b07e0e36d2b6000`</sub>

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
| Oh, heißt das, mein Timing war perfekt, oder denkst du immer an mich? | 4.7 s | `Zeile` | `18830b966a2b6000 sq030_00_holocall` |
| Na ja, glaub, ich hab genau das Richtige, um dich abzulenken. | 3.8 s | `Zeile` | `18983199cf2b6000 sq030_00_holocall` |
| Und das andere ... Na ja, ich tauch nicht mit jeder. / Und das andere ... Na ja, da bin ich wählerisch. | 5.5 s | `Zeile` | `18a6e78c9e2b6000 sq030_03_dam_equipment` |
| Jetzt mach keinen Rückzieher mehr. Benutz einfach deine Fantasie. | 5.2 s | `Zeile` | `1897f7fb1a2b6000 sq030_00_holocall` |
| Sag nicht, ich hätte dich nicht gewarnt. | 2.5 s | `Zeile` | `1897f8b7412b6000 sq030_00_holocall` |
| Ich summe ein Lied, du sagst mir, welches es ist. | 2.7 s | `Zeile` | `19eba4297c2b6000 sq030_05_lake_test` |
| Puh, manchmal hast du echt ein Brett vorm Kopf. | 3.8 s | `Zeile` | `18f9e3bc672b6000 sq030_11_morning` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hey, gilt dein Angebot vom Damm noch? | 4.5 s | `VVF` | `1a9f07a2ab2fc000 judy_default` |
| Vielleicht nur ein Zimmer? | ? | `VVF frei` | `1532045272401000 q103_15_roadhouse_bar` |
| Ich hab dich echt vermisst. | ? | `VVF frei` | `1a04d435ff2c5000 sq027_04_preparations_panam` |
| Ich könnte die ganze Nacht hierbleiben. | 2.9 s | `VVF` | `39b494eb948bb000 mq055_05_downtown` |

### Wortwechsel

**Lob und Abwehr**

- **JUDY:** Du hast echt Talent, Kleines.  <sub>2.1 s &middot; `39675dc8759ce000`</sub>
- **V:** Du bist die Beste.  <sub>? &middot; `172a8c16fb502000`</sub>

Ihr Lob ist beilaeufig - genau deshalb sitzt es.

**Zwei, die sich verdient haben**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Da haben sich zwei gefunden.  <sub>2.5 s &middot; `1812474b462b6000`</sub>
- **JUDY:** Interessante Leute langweilen sich eben selten.  <sub>2.7 s &middot; `189736fe942b6000`</sub>

Funktioniert nach etwas, das die beiden zusammen geschafft haben.

**Nur ein Zimmer**

- **V:** Vielleicht nur ein Zimmer?  <sub>? &middot; `1532045272401000`</sub>
- **JUDY:** Aber vertrau mir, es wird sich lohnen.  <sub>2.7 s &middot; `189806a8512b6000`</sub>

Vs Zeile ist eine Frage ohne Namen - sie traegt in jede Richtung.

**War das Timing gut oder denkst du staendig an mich**

- **JUDY:** Oh, heißt das, mein Timing war perfekt, oder denkst du immer an mich?  <sub>4.7 s &middot; `18830b966a2b6000`</sub>
- **V:** Ich hab dich echt vermisst.  <sub>? &middot; `1a04d435ff2c5000`</sub>

Sie stellt die Fangfrage, V faellt darauf herein - besser geht es nicht.

**Ich tauch nicht mit jeder**

- **JUDY:** Und das andere ... Na ja, ich tauch nicht mit jeder. / Und das andere ... Na ja, da bin ich wählerisch.  <sub>5.5 s &middot; `18a6e78c9e2b6000`</sub>
- **V:** Was immer du vorhast, Judy. Ich bin dabei.  <sub>4.3 s &middot; `19c6ddabf55b3000`</sub>

Ihr Zugestaendnis ist beilaeufig verpackt; Vs Zusage nennt ihren Namen.

**Ablenkung**

- **JUDY:** Na ja, glaub, ich hab genau das Richtige, um dich abzulenken.  <sub>3.8 s &middot; `18983199cf2b6000`</sub>
- **V:** Ich könnte die ganze Nacht hierbleiben.  <sub>2.9 s &middot; `39b494eb948bb000`</sub>

Beide Zeilen lassen offen, worum es geht. Genau deshalb tragen sie.


## Alltag - Kaffee, Pizza, Zuhause

**Wann:** V ist bei ihr, nichts Dringendes liegt an

Der staerkste Fund der Beziehungssichtung. Alltag traegt eine Beziehung glaubhafter als weitere Liebeserklaerungen - und das Material ist da, samt Vs Antworten.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Komm schon, ernsthaft? | 2.0 s | `Bark` | `bump_var_2` |
| Hey, pass auf ... | 1.7 s | `Bark` | `bump_var_1` |
| Was ist sonst so in deinem Leben los? | 2.2 s | `Zeile` | `1afc15dc392fc004 judy_default` |
| Was gibt’s Neues? | 1.2 s | `Zeile` | `1afc0918ac2fc000 judy_default` |
| Was machen wir? | 1.4 s | `Zeile` | `1806ce4c842fc000 q105_07_judy_braindance` |
| Wie sieht’s aus? | 1.5 s | `Zeile` | `18552511902fc000 sq026_12_penthouse_gameplay` |
| Was auch immer du jetzt vorhast ... Kann ich irgendwie helfen? | 7.1 s | `Zeile` | `14ab207df129f000 q203_02c_judy` |
| Hast du ’ne Kippe? | 3.9 s | `Zeile` | `1786566a832fc000 sq026_01b_roof` |
| Schon gelangweilt? Wir können weiter, wenn du willst. | 3.1 s | `Zeile` | `1a6cd20de02fc004 sq030_06_lake_exploration` |
| Willst du schon weg? Kein Sightseeing? | 2.7 s | `Zeile` | `1a6cd20dde2fc000 sq030_06_lake_exploration` |
| Mal sehen, was wir noch so alles finden. | 2.8 s | `Zeile` | `1a6c24d46f2fc000 sq030_06_lake_exploration` |
| Sieh dich um ... | 2.4 s | `Zeile` | `1a716d4e8a2b6000 sq030_06_lake_exploration` |
| Wie geht’s so? | 1.7 s | `Zeile` | `396b7ccf489ce000 mq055_05_downtown` |
| Wie trinkst du deinen? Heh, genau wie ich. | 3.8 s | `Zeile` | `396871fa77a71000 mq055_05_downtown` |
| Machen wir weiter. | 1.4 s | `Zeile` | `15a89ee0355ae010 q004_04a_bd_tutorial_robbery` |
| Und? Was sagst du? | 1.8 s | `Zeile` | `15a8a4c8875ae000 q004_04a_bd_tutorial_robbery` |
| Ooooh, ausgefallen. | 2.3 s | `Zeile` | `3968769546a71000 mq055_05_downtown` |
| Ich brüh was auf. | 2.1 s | `Zeile` | `3968743729a71000 mq055_05_downtown` |
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

- **JUDY:** Ich brüh was auf.  <sub>2.1 s &middot; `3968743729a71000`</sub>
- **V:** Schwarz, bitte.  <sub>1.7 s &middot; `1a6769eccf2fc000`</sub>
- **JUDY:** Wie trinkst du deinen? Heh, genau wie ich.  <sub>3.8 s &middot; `396871fa77a71000`</sub>

Ihre Pointe setzt voraus, dass V vorher geantwortet hat - hier geht sie auf.

**Kaffee, mit Milch**

- **JUDY:** Ich brüh was auf.  <sub>2.1 s &middot; `3968743729a71000`</sub>
- **V:** Mit ein bisschen Milch.  <sub>1.6 s &middot; `1a676a6b122fc000`</sub>
- **JUDY:** Wie trinkst du deinen? Heh, genau wie ich.  <sub>3.8 s &middot; `396871fa77a71000`</sub>

Dieselbe Pointe, andere Antwort. Beide Wege muessen funktionieren.

**Streit um Pizza**

- **JUDY:** Ich hab was richtig Großes. Sag’s dir heute Abend. Ach so – was willst du auf deine Pizza?  <sub>6.8 s &middot; `1a0fbd86992b6000`</sub>
- **V:** Tofu-Thunfisch und Ananasgeschmack.  <sub>2.7 s &middot; `1a0fd5b3d22b6000`</sub>
- **JUDY:** Igitt. Das sind zwei Wörter, die nicht in denselben Satz gehören. Schon gar nicht auf dieselbe Pizza. Du machst Witze, oder?  <sub>6.5 s &middot; `1a0fe8a4772b6000`</sub>

Der laengste vollstaendige Wortwechsel im ganzen Bestand.

**Streit um Pizza, kurze Fassung**

- **JUDY:** Ich hab was richtig Großes. Sag’s dir heute Abend. Ach so – was willst du auf deine Pizza?  <sub>6.8 s &middot; `1a0fbd86992b6000`</sub>
- **V:** Heuschreckensalami. Und ganz viel extra Käse.  <sub>3.9 s &middot; `1a0fd4447d2b6000`</sub>

Wenn die lange Empoerung zu viel ist.

**Bleib noch**

- **V:** Ich könnte die ganze Nacht hierbleiben.  <sub>2.9 s &middot; `39b494eb948bb000`</sub>
- **JUDY:** Für dich hab ich den ganzen Tag.  <sub>2.3 s &middot; `1b07e0e36d2b6000`</sub>

Vs Zeile stammt aus dem Hangout und meint genau das.

**Anrempeln**

- **JUDY:** Hey, pass auf ...  <sub>1.7 s &middot; `bump_var_1`</sub>
- **V:** Was zum ...  <sub>1.6 s &middot; `reaction_surprise_var_2`</sub>

Kleinster moeglicher Wortwechsel, rein koerperlich.


## Einladung und Verabredung

**Wann:** Judy schlaegt etwas vor, V sagt zu

Diese Kategorie fehlte bisher ganz - in allen drei Dokumenten.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Klar. Heute Abend in der Hütte am See. Wir sehen uns dort? | 4.1 s | `Zeile` | `1a9f085b672fc000 judy_default` |
| Cool. Heute Abend in der Hütte am See. Lass mich nicht warten. | 4.5 s | `Zeile` | `1a9f0c7fe02fc000 judy_default` |
| Lass mich nicht warten. | 1.4 s | `Zeile` | `39675ce5d69ce000 mq055_04_heywood` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Hey, gilt dein Angebot vom Damm noch? | 4.5 s | `VVF` | `1a9f07a2ab2fc000 judy_default` |
| Ich könnte die ganze Nacht hierbleiben. | 2.9 s | `VVF` | `39b494eb948bb000 mq055_05_downtown` |

### Wortwechsel

**Gilt das Angebot noch**

- **V:** Hey, gilt dein Angebot vom Damm noch?  <sub>4.5 s &middot; `1a9f07a2ab2fc000`</sub>
- **JUDY:** Klar. Heute Abend in der Hütte am See. Wir sehen uns dort?  <sub>4.1 s &middot; `1a9f085b672fc000`</sub>

Vs Zeile fragt woertlich nach - der sauberste Anschluss im Bestand.

**Lass mich nicht warten**

- **JUDY:** Cool. Heute Abend in der Hütte am See. Lass mich nicht warten.  <sub>4.5 s &middot; `1a9f0c7fe02fc000`</sub>
- **V:** Ich könnte die ganze Nacht hierbleiben.  <sub>2.9 s &middot; `39b494eb948bb000`</sub>

Ihre Ungeduld und Vs Zusage schliessen die Verabredung ab.


## Sorge und Nachsorge

**Wann:** V ist verletzt, erschoepft oder lange weg gewesen

Erst schimpft sie aus Angst, dann wird sie weich. Diese Reihenfolge ist glaubwuerdiger als reine Fuersorge - und beide Haelften liegen vor.  **Zu zerlegen:** 30 Zeilen, ein Treffer in 255 Minuten. Was hier liegt, teilt sich den Tonfall, nicht den Zeitpunkt - die Kampfwarnungen gehoeren zu *Kampf*, das Durchatmen zu *Nach dem Kampf*, *Pass auf dich auf* zu *Abschied*, *Ich dachte, du bist tot* zu *Wiedersehen*. Uebrig bleiben rund sechs Zeilen, die wirklich an der Gesundheit haengen. Siehe TRIGGER_PLAN.md.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Was zum Teufel, V? Bist du ... krank? | 3.5 s | `Zeile` | `18a2feb32f2fc004 sq026_08_plan` |
| V? Du siehst nicht gut aus ... | 2.5 s | `Zeile` | `1a33ace66d2b6000 sq026_08_plan` |
| Ganz ruhig, ist alles okay? | 2.1 s | `Zeile` | `28aa62967b4ea000 sq026_08_plan` |
| Alles in Ordnung bei dir? | 1.6 s | `Zeile` | `1f46421f852b6008 sq030_01_dam_meetup` |
| Du solltest langsam machen. | 2.2 s | `Zeile` | `1a95b684a12b6000 sq030_09_pier` |
| Geht’s dir wirklich gut? | 1.4 s | `Zeile` | `1f45f63cf42b6000 sq030_09_pier` |
| Oh, ich kenne diese Stimme, V. Alles ... okay? | 4.8 s | `Zeile` | `1892e2683e2b6000 sq030_00_holocall` |
| Sag schon, wie fühlst du dich? | 1.8 s | `Zeile` | `1ef8b0825f42f000 q004_04b_after_tutorial` |
| Alles in Ordnung, V? | 1.6 s | `Zeile` | `1ef8b0186b42f000 q004_04b_after_tutorial` |
| Ganz ruhig, ist alles okay? | 1.9 s | `Zeile+Leih` | `1f45f8b07b2b6008 sq030_09_pier` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Wenn irgendwas ist, ruf mich an, okay? | 2.2 s | `VVF` | `1a0a374e852fc000 sq026_01b_roof` |
| Aber denk dran: Ich bin für dich da, wenn du mich brauchst. Jederzeit. | ? | `VVF frei` | `198e76d299521000 sq021_11_finale` |
| Gut. Ich warte. | 1.6 s | `VVF` | `17bb05d57b5b3000 q105_06a_fingers_escape` |

### Wortwechsel

**Schimpfen, dann weich werden**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** V, pass besser auf! Tot nützt du niemandem!  <sub>3.5 s &middot; `player_fallback_var_2`</sub>
- **JUDY:** Denk nicht zu viel drüber nach, okay?  <sub>2.0 s &middot; `1f4640da642b6000`</sub>

Der Umschlag von Wut zu Sorge ist die ganze Wirkung.

**Ruhig atmen**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Alles in Ordnung, V?  <sub>1.6 s &middot; `1ef8b0186b42f000`</sub>
- **JUDY:** Schön langsam atmen. Ruhig. Alles okay, dir geht’s gut.  <sub>4.5 s &middot; `1ef8b0c1f442f000`</sub>

Nur nach echtem Schaden. Sonst wirkt sie uebergriffig.

**Sie merkt, dass etwas nicht stimmt**

- **JUDY:** Du kommst mir ... anders vor. Bist irgendwie ... abwesend. Denkst du an Mikoshi? Oder ist es der Job?  <sub>9.9 s &middot; `14aaba91a329f000`</sub>
- **V:** Wenn irgendwas ist, ruf mich an, okay?  <sub>2.2 s &middot; `1a0a374e852fc000`</sub>
- **JUDY:** Wenn ich irgendwie helfen kann ... egal, wie ... musst du’s nur sagen.  <sub>5.5 s &middot; `1a33ca85c72b6000`</sub>

Vs Zeile stammt aus Judys eigener Quest und passt woertlich.

**Judy sorgt sich um V**

- **JUDY:** Alles okay? Schnauf mal kurz durch.  <sub>2.8 s &middot; `player_fallback_var_3`</sub>
- **V:** Weiß ich zu schätzen. Danke.  <sub>2.0 s &middot; `scene_thanks_var_2`</sub>

Die Bark-Fassung, ohne Vorbedingung einsetzbar.

**Judy braucht selbst Raum**

- **JUDY:** Ich ... muss das verarbeiten, und zwar allein.  <sub>6.6 s &middot; `1a82306830610000`</sub>
- **V:** Gut. Ich warte.  <sub>1.6 s &middot; `17bb05d57b5b3000`</sub>
- **JUDY:** Aber wenn du Zeit hast, sag mir Bescheid, okay?  <sub>? &middot; `1b971f17262b6000`</sub>

Der einzige Wortwechsel, in dem SIE zurueckzieht und V wartet.

**Sie versteht es**

- **V:** Wenn irgendwas ist, ruf mich an, okay?  <sub>2.2 s &middot; `1a0a374e852fc000`</sub>
- **JUDY:** Kann ich verstehen, V. Ehrlich gesagt würde das auch ’ne Weile dauern.  <sub>4.1 s &middot; `1afd6f18ec2fc000`</sub>

Keine Beschwichtigung, sondern Zustimmung. Das ist selten.


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
| Du kannst dich auf mich verlassen. | ? | `VVF frei` | `18c1d0f46c4e6004 mq021_01_briefing` |

### Wortwechsel

**Beeindruckt**

- **JUDY:** Du verschwendest keine Munition. Bin beeindruckt.  <sub>3.4 s &middot; `16bf45bffc2fc000`</sub>
- **V:** Du kannst dich auf mich verlassen.  <sub>? &middot; `18c1d0f46c4e6004`</sub>

Trockenes Lob, trockene Antwort.

**Gegenseitig**

- **JUDY:** Du hast echt Talent, Kleines.  <sub>2.1 s &middot; `39675dc8759ce000`</sub>
- **V:** Du bist die Beste.  <sub>? &middot; `172a8c16fb502000`</sub>
- **JUDY:** Da haben sich zwei gefunden.  <sub>2.5 s &middot; `1812474b462b6000`</sub>

Lob, Gegenlob, und ihre Pointe schliesst es ab.


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
| Du kannst dich auf mich verlassen. | ? | `VVF frei` | `18c1d0f46c4e6004 mq021_01_briefing` |

### Wortwechsel

**Sie fragt, V sagt zu**

- **JUDY:** Du, meine Liebe, wirst mit mir eine Virtu machen. / Du, Kumpel, wirst mit mir eine Virtu machen.  <sub>3.5 s &middot; `189d4f49e02b6000`</sub>
- **V:** Klingt nova. Tun wir’s.  <sub>2.4 s &middot; `1a6181b1812fc000`</sub>

Vs Zusage ist aus derselben Questreihe - Ton und Wortwahl passen.

**V vertraut ihr blind**

- **V:** Was immer du vorhast, Judy. Ich bin dabei.  <sub>4.3 s &middot; `19c6ddabf55b3000`</sub>
- **JUDY:** Genial, oder?  <sub>1.7 s &middot; `39675eebd79ce000`</sub>

Vs Zeile nennt Judy beim Namen. Der beste Anschluss im ganzen V-Bestand.


## Kampf

**Wann:** Gefecht laeuft

Vollstaendig ueber Barks abgedeckt - die groesste Bark-Familie im Voiceset.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Jetzt bin ich richtig sauer! | 2.5 s | `Bark` | `battlecry_morale_var_1` |
| Jetzt mach ich ernst! | 2.1 s | `Bark` | `battlecry_morale_var_3` |
| Hast es so gewollt! | 1.8 s | `Bark` | `battlecry_morale` |
| Hast es so gewollt! | 1.8 s | `Bark` | `battlecry_morale_var_2` |
| Echt jetzt?! | 1.4 s | `Bark` | `combat_aggro_bark_var_1` |
| Aaah! | 1.3 s | `Bark` | `combat_aggro_bark_var_2` |
| Sie sind hier. Bleib wachsam. | 2.1 s | `Bark` | `enemy_warning_var_2` |
| Da kommen sie! | 1.4 s | `Bark` | `enemy_warning_var_1` |
| Hey, V! Mach was, verdammte Scheiße! | 2.9 s | `Bark` | `battlecry_curse_var_3` |
| Was zur Hölle? | 1.6 s | `Bark` | `battlecry_curse_var_2` |
| Fuuuck! | 1.2 s | `Bark` | `battlecry_curse` |
| Fuuuck! | 1.2 s | `Bark` | `battlecry_curse_var_1` |
| Oh, Scheiße! | 1.9 s | `Bark` | `danger_var_1` |
| Bin bei dir. | 1.4 s | `Bark` | `danger_var_3` |
| Achtung! | 1.2 s | `Bark` | `danger` |
| Achtung! | 1.2 s | `Bark` | `danger_var_2` |
| Wo haben die nur diese Ausrüstung her? | 2.7 s | `Bark` | `elite_warning_var_1` |
| Ordentlich ausgestattet, die Typen! | 2.3 s | `Bark` | `elite_warning_var_2` |
| In Deckung! Granate! | 2.2 s | `Bark` | `grenade_enemy_var_3` |
| Achtung, Granate! | 1.9 s | `Bark` | `grenade_enemy_var_2` |
| Granate! | 1.4 s | `Bark` | `grenade_enemy_var_1` |
| Na, wie schmeckt dir das?! | 2.3 s | `Bark` | `grenade_throw` |
| Warte kurz, muss nachladen. | 2.1 s | `Bark` | `reloading_var_3` |
| Deck mich, ich lade nach! | 2.0 s | `Bark` | `reloading_var_2` |
| Ich muss nachladen. | 1.7 s | `Bark` | `reloading_var_1` |
| Jetzt! Mach sie fertig! | 1.8 s | `Zeile` | `16bdd8ff5d2fc000 q105_07_judy_braindance` |
| Vorsicht. Da sind zwei. | 2.5 s | `Zeile` | `174f5826962b6000 q105_07_judy_braindance` |
| Erledige die, schnell. | 1.5 s | `Zeile` | `180700ef0d2fc000 q105_07_judy_braindance` |
| Ich lenk sie ab, du erledigst sie. | 2.1 s | `Zeile` | `16be4522142fc000 q105_07_judy_braindance` |
| Pass auf – da könnten Leute sein. | 2.9 s | `Zeile` | `181c6d75ad2fc000 sq026_11_to_penthouse` |
| Kannst du sie ausschalten? | 1.6 s | `Zeile` | `18b6bc8f672fc000 sq026_11_to_penthouse` |
| Kommeee! Die sind so gut wie erledigt! | 3.4 s | `Zeile` | `1a6d33c7952fc000 sq030_06_lake_exploration` |
| Ungh ... Aaargh ... Lass ... los! | 3.9 s | `Bark` | `grapple` |
| Pass auf, verdammt! Schalt dein Hirn ein. | 2.8 s | `Bark` | `player_fallback_var_1` |
| V, pass besser auf! Tot nützt du niemandem! | 3.5 s | `Bark` | `player_fallback_var_2` |

### Wortwechsel

**Gegner gesichtet**

- **JUDY:** Da kommen sie!  <sub>1.4 s &middot; `enemy_warning_var_1`</sub>
- **V:** Oh-o. Das wird ein Spaß.  <sub>2.7 s &middot; `reaction_hostiles_var_2`</sub>

Warnung und Bestaetigung.

**Warnung im Kampf**

- **V:** Hey! Achtung!  <sub>1.7 s &middot; `combat_ally_warning_var_3`</sub>
- **JUDY:** Jetzt mach ich ernst!  <sub>2.1 s &middot; `battlecry_morale_var_3`</sub>

V warnt, Judy geht drauf zu.

**In Deckung**

- **V:** In Deckung!  <sub>1.5 s &middot; `combat_ally_cover`</sub>
- **JUDY:** Oh, Scheiße!  <sub>1.9 s &middot; `danger_var_1`</sub>

Vs Kommando, ihr Fluch.

**Granate**

- **JUDY:** In Deckung! Granate!  <sub>2.2 s &middot; `grenade_enemy_var_3`</sub>
- **V:** Oh, Scheiße ...  <sub>1.9 s &middot; `reaction_surprise_var_3`</sub>

Ihre Warnung kommt zuerst.

**Nachfrage im Kampf**

- **V:** Alles okay?  <sub>1.3 s &middot; `combat_ally_check`</sub>
- **JUDY:** Bin bei dir.  <sub>1.4 s &middot; `danger_var_3`</sub>

"Bin bei dir" ist die beste Antwort im ganzen Bark-Bestand.

**Fluchen im Kampf**

- **JUDY:** Hey, V! Mach was, verdammte Scheiße!  <sub>2.9 s &middot; `battlecry_curse_var_3`</sub>
- **V:** Du willst es hart? Kannst du haben!  <sub>2.6 s &middot; `battlecry_curse_var_4`</sub>

Beide fluchen - reine Textur, kein Inhalt.


## Nach dem Kampf

**Wann:** Gefecht vorbei, beide stehen noch

Hier steht, was den Sieg zu etwas Gemeinsamem macht statt zu einer Meldung.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Oh, das war’s. Wir haben’s geschafft. | 2.8 s | `Bark` | `combat_ended_var_1` |
| Sieh uns an. Nicht totzukriegen. | 2.8 s | `Bark` | `combat_ended_var_2` |
| Fresst das, Arschlöcher. Scheint, als hättest du alle erwischt. | 4.1 s | `Zeile` | `18070264fd2fc000 q105_07_judy_braindance` |
| Du verschwendest keine Munition. Bin beeindruckt. | 3.4 s | `Zeile` | `16bf45bffc2fc000 q105_07_judy_braindance` |
| Hey, nicht schlecht. | 1.7 s | `Zeile` | `1a9600232a2fc000 q105_07_judy_braindance` |
| Dein Ernst? Die ist großartig! | 2.2 s | `Zeile` | `1a76a081672b6000 sq030_06_lake_exploration` |
| Heeey, nicht schlecht. | 1.9 s | `Zeile` | `39675beeb89ce000 mq055_04_heywood` |
| Okay, jetzt geht der Spaß erst richtig los. | 4.4 s | `Zeile` | `396690f54aa4e000 mq055_05_downtown` |
| Bin bei dir. | 1.4 s | `Bark` | `danger_var_3` |
| Hey, es war ja nicht deine Schuld ... | 2.7 s | `Zeile` | `185efbe0f5502008 q115_02b_ripperdoc_roof` |
| Hey, langsam ... Ganz ruhig. | 2.3 s | `Zeile` | `1a7b4c53a32b6000 sq030_09_pier` |
| Schön langsam atmen. Ruhig. Alles okay, dir geht’s gut. | 4.5 s | `Zeile+Leih` | `1ef8b0c1f442f000 q004_04b_after_tutorial` |
| Tief durchatmen. | 2.0 s | `Zeile` | `396692eeb0a4e000 mq055_01_megabuilding` |
| Alles okay? Schnauf mal kurz durch. | 2.8 s | `Bark` | `player_fallback_var_3` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Du bist die Beste. | ? | `VVF` | `172a8c16fb502000 q115_04_plan` |

### Wortwechsel

**Sieh uns an**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Oh, das war’s. Wir haben’s geschafft.  <sub>2.8 s &middot; `combat_ended_var_1`</sub>
- **JUDY:** Sieh uns an. Nicht totzukriegen.  <sub>2.8 s &middot; `combat_ended_var_2`</sub>

Aus dem Sieg wird ein gemeinsames Erlebnis.

**Bin bei dir**

- **JUDY:** Bin bei dir.  <sub>1.4 s &middot; `danger_var_3`</sub>
- **V:** Du bist die Beste.  <sub>? &middot; `172a8c16fb502000`</sub>

Sparsam einsetzen - die Zeile traegt viel und nutzt sich schnell ab.

**Kampf vorbei**

- **JUDY:** Oh, das war’s. Wir haben’s geschafft.  <sub>2.8 s &middot; `combat_ended_var_1`</sub>
- **V:** Das wird ein guter Tag.  <sub>1.8 s &middot; `reaction_happy_var_2`</sub>

Die Bark-Fassung, jederzeit einsetzbar.


## Stealth

**Wann:** Unentdeckt vorgehen, entdeckt werden, wieder verschwinden

Barks decken alle drei Zustaende ab. Vs `combat_ally_stealth` ist ausdruecklich fuer Begleiter geschrieben.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Perfekt, die sehen uns nicht mehr. | 2.2 s | `Bark` | `stealth_restored_var_1` |
| Die haben wir abgeschüttelt. | 1.8 s | `Bark` | `stealth_restored_var_2` |
| Vorsicht! | 1.3 s | `Bark` | `stealth_warning_bark_var_2` |
| Sei still! | 1.2 s | `Bark` | `stealth_warning_bark_var_1` |
| Verschwinde da, sonst sehen sie uns! | 2.9 s | `Bark` | `detection_warning_var_1` |
| Vorsicht, die haben was gehört! | 2.4 s | `Bark` | `detection_warning_var_2` |
| Pass auf die Kameras auf, okay? | 2.1 s | `Bark` | `camera_warning_var_1` |
| Die haben hier alles im Blick. | 2.1 s | `Bark` | `camera_warning_var_2` |
| Lass uns hier klar Schiff machen, sonst fliegen wir auf. | 3.1 s | `Bark` | `body_warning_var_1` |
| Versteck den Körper, okay? | 2.2 s | `Bark` | `body_warning_var_2` |
| Gesichert. Geh weiter. | 1.6 s | `Zeile` | `180ca4ff2f2fc000 q105_07_judy_braindance` |
| Mist, entdeckt! | 1.2 s | `Zeile` | `180ca5fe922fc000 q105_07_judy_braindance` |
| Danach schleichen wir uns vorbei ... | 2.4 s | `Zeile` | `1a95de1e182fc000 q105_07_judy_braindance` |

### Wortwechsel

**Leise vorgehen**

- **V:** Man darf uns nicht hören, klar?  <sub>2.3 s &middot; `combat_ally_stealth`</sub>
- **JUDY:** Sei still!  <sub>1.2 s &middot; `stealth_warning_bark_var_1`</sub>

V gibt den Ton vor, Judy bestaetigt.

**Entdeckungsgefahr**

- **JUDY:** Verschwinde da, sonst sehen sie uns!  <sub>2.9 s &middot; `detection_warning_var_1`</sub>
- **V:** Pssst. Langsam.  <sub>2.6 s &middot; `combat_ally_stealth_var_1`</sub>

Ihre Warnung, Vs Beruhigung.

**Stealth wiederhergestellt**

- **JUDY:** Perfekt, die sehen uns nicht mehr.  <sub>2.2 s &middot; `stealth_restored_var_1`</sub>
- **V:** Man kann nicht immer Pech haben.  <sub>1.9 s &middot; `reaction_happy_var_3`</sub>

Erleichterung auf beiden Seiten.


## Sie bleibt zurueck

**Wann:** V geht allein weiter, sie wartet an Ort und Stelle

Noch OHNE Ausloeser. Diese Zeilen setzen voraus, dass sie stehen bleibt - bei uns folgt sie immer, also wuerde jede von ihnen dem widersprechen, was man sieht. NCA kennt ein Halte-Kommando; sobald wir das lesen, haben sie ihren Platz. Bis dahin liegen sie hier richtig und stumm.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Okay, ich warte hier auf dich. | 2.7 s | `Zeile` | `1787cc94372cd000 q202_05_convoy` |
| Sei vorsichtig, okay? Ich warte hier auf dich. | 3.9 s | `Zeile` | `185efbe0f1502010 q115_02b_ripperdoc_roof` |


## Warten, Troedeln, kleine Reibung

**Wann:** V bleibt zurueck, bricht ab oder kommt zu spaet

Reibung ohne Bruch. Ihre Ungeduld liest sich als Vertrautheit, wenn sie nicht allein steht - deshalb gehoert immer eine Versoehnung dahinter.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Was ist los? Hör auf zu trödeln. | 2.7 s | `Bark` | `follow_me_1` |
| Komm schon, V, bleib bei mir. | 2.3 s | `Bark` | `follow_me` |
| Komm schon, V, bleib bei mir. | 2.3 s | `Bark` | `follow_me_2` |
| Wir haben was vor, schon vergessen? | 2.5 s | `Bark` | `hurry_up_var_2` |
| Konzentration, V. | 2.1 s | `Bark` | `hurry_up_var_3` |
| Na? Los jetzt! | 1.9 s | `Bark` | `hurry_up_var_1` |
| Was ist mit dir los? | 1.8 s | `Bark` | `urge_var_1` |
| Komm schon, V. | 1.6 s | `Bark` | `urge` |
| Komm schon, V. | 1.6 s | `Bark` | `urge_var_2` |
| Okay, wir setzen das später fort. | 2.5 s | `Bark` | `interrupt_var_1` |
| Hab ich dich gelangweilt? | 1.9 s | `Bark` | `interrupt` |
| Hab ich dich gelangweilt? | 1.9 s | `Bark` | `interrupt_var_2` |
| Bist du da? Kannst du mich hören? | 2.7 s | `Bark` | `phone_urge_var_2` |
| Äh ... V? | 1.8 s | `Bark` | `phone_urge_var_1` |
| Deine Entscheidung, aber trödel nicht. | 2.3 s | `Zeile` | `185fea344a2b6000 q105_07_judy_braindance` |
| Jepp. Bin sofort da. Warte auf mich. | 2.9 s | `Zeile` | `16b50051b62fc000 q105_07_judy_braindance` |
| V, warte. Ich bin ganz nah. | 2.9 s | `Zeile` | `16b5046d372fc000 q105_07_judy_braindance` |
| Wart ’ne Sekunde auf mich. | 1.6 s | `Zeile` | `16bf45cbac2fc000 q105_07_judy_braindance` |
| Komm, gehen wir. | 1.7 s | `Zeile` | `1a76bc30fd2fc004 sq026_04_maiko` |
| V, lass uns abhauen. | 2.8 s | `Zeile` | `1a7bd32bec2fc000 sq026_05a_leave` |
| V, warte noch. | 1.5 s | `Zeile` | `1a7b10f6e62fc000 sq026_05a_leave` |
| Komm schon! Keine falsche Scheu. | 2.9 s | `Zeile` | `1f46422d992b6008 sq030_01_dam_meetup` |
| Aye aye, Käpt’n – mir nach. | 2.5 s | `Zeile` | `1a6d3771f92fc000 sq030_06_lake_exploration` |
| Schon unterwegs. | 1.4 s | `Zeile` | `1aa440794d2fc000 sq030_06_lake_exploration` |
| V? Worauf wartest du? | 2.1 s | `Zeile` | `14edc33d565b2000 q004_03_this_is_judy` |
| Na los, worauf wartest du? | 1.9 s | `Zeile+Leih` | `17c00d5613610000 q105_02_lizzy_meet_judy` |
| Na dann komm. Ich will dir was zeigen. | 2.4 s | `Zeile` | `1a6d277cc12fc000 sq030_06_lake_exploration` |
| Jepp, bin sofort da. Warte auf mich. | 3.3 s | `Zeile` | `39669585fca4e000 mq055_05_downtown` |
| Komm schon, V. Bleib bei mir. | 1.3 s | `Zeile` | `39675fea699ce000 mq055_04_heywood` |
| Lass mich nicht warten. | 1.4 s | `Zeile` | `39675ce5d69ce000 mq055_04_heywood` |
| Okay ... Aber lass dir nicht zu viel Zeit. | 2.7 s | `Zeile` | `157e1b71602fc008 q105_06c_finding_studio` |
| So lang hat das nicht Zeit. | 1.7 s | `Zeile` | `183b56df2f2b600c q105_06a_fingers_escape` |
| Sag Bescheid, wenn du weiter willst. | 2.6 s | `Zeile` | `1a6c40ed992fc000 sq030_06_lake_exploration` |
| Was sagst du, wollen wir weiter? | 2.0 s | `Zeile` | `1a6c5010692fc004 sq030_06_lake_exploration` |
| Du hast meine Pläne ruiniert, weißt du? | 2.8 s | `Zeile` | `1a9f63e7252b6000 sq030_11_morning` |

### Wortwechsel

**Gespraech unterbrochen**

- **V:** Moment ... Bin gleich wieder da.  <sub>2.1 s &middot; `interrupt_var_6`</sub>
- **JUDY:** Okay, wir setzen das später fort.  <sub>2.5 s &middot; `interrupt_var_1`</sub>

V bricht ab, Judy nimmt es hin.

**Gespraech unterbrochen, kurz**

- **V:** Wir reden später.  <sub>1.6 s &middot; `interrupt_var_2`</sub>
- **JUDY:** Hab ich dich gelangweilt?  <sub>1.9 s &middot; `interrupt`</sub>

Dieselbe Figur, knapper.

**Spieler bleibt zurueck**

- **JUDY:** Was ist los? Hör auf zu trödeln.  <sub>2.7 s &middot; `follow_me_1`</sub>
- **V:** Ich muss weiter.  <sub>1.4 s &middot; `interrupt_var_4`</sub>

Ihre Ungeduld, Vs Ausrede.

**Begleitung endet**

- **V:** Das wär erledigt. Mach besser ’nen Abgang.  <sub>3.3 s &middot; `follower_end_var_2`</sub>
- **JUDY:** Okay, wir setzen das später fort.  <sub>2.5 s &middot; `interrupt_var_1`</sub>

Vs `follower_end` ist ausdruecklich fuer Begleiter geschrieben.

**Etwas Interessantes entdeckt**

- **V:** Oh. Interessant.  <sub>2.4 s &middot; `reaction_inspect_var_1`</sub>
- **JUDY:** Was ist mit dir los?  <sub>1.8 s &middot; `urge_var_1`</sub>

V bleibt stehen, Judy will weiter.

**Du hast meine Plaene ruiniert**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Du hast meine Pläne ruiniert, weißt du?  <sub>2.8 s &middot; `1a9f63e7252b6000`</sub>
- **JUDY:** Aber vertrau mir, es wird sich lohnen.  <sub>2.7 s &middot; `189806a8512b6000`</sub>

Vorwurf mit einem Augenzwinkern, und gleich der Koeder hinterher.

**Brett vorm Kopf**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Puh, manchmal hast du echt ein Brett vorm Kopf.  <sub>3.8 s &middot; `18f9e3bc672b6000`</sub>
- **JUDY:** Das gefällt dir gar nicht, hm?  <sub>2.5 s &middot; `19ec472e462b6000`</sub>

Spott ohne Schaerfe - sie bleibt dabei zugewandt.


## Umgebung und Aussicht

**Wann:** Aussichtspunkt, ungewoehnlicher Ort, gemeinsames Schauen

Keine Bark deckt das ab - hier lohnt sich der Zeilenbau am meisten. q202 fuellt die Kategorie, die vorher leer war.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Fast, als wären wir jenseits von Raum und Zeit. Wie in ’ner Schneekugel. | 4.3 s | `Zeile` | `1a7183520c2b6000 sq030_06_lake_exploration` |
| Genießt du die Aussicht? / Hübsche Aussicht, Machoman? | 2.5 s | `Zeile` | `136656bfaf2fc000 sq030_05_lake_test` |
| Beeindruckend, oder? | 1.9 s | `Zeile` | `1362d96a1b2fc000 sq030_05_lake_test` |
| Gefällt’s dir? | 1.2 s | `Zeile` | `1362da25582fc000 sq030_05_lake_test` |
| Wollen wir über den Platz schlendern? | 2.2 s | `Zeile` | `1a6c40ec352fc004 sq030_06_lake_exploration` |
| Genießt du die Aussicht? | 1.4 s | `Zeile+Leih` | `39687a048fa71000 mq055_05_downtown` |
| Mhm. Von hier aus sieht die Stadt so weit weg und unschuldig aus. Komisches Gefühl ... Als wär ich ein Flüchtling. | 11.1 s | `Zeile` | `199d9ab23f29f000 q202_05_convoy` |
| Ich hab gerade erst erkannt, dass Night City nie richtig für mich war. | 6.9 s | `Zeile` | `19562ed6af29f000 q202_05_convoy` |
| Frag mich, ob’s mir fehlen wird ... | 1.8 s | `Zeile` | `1a297fc3bf29f000 q202_05_convoy` |
| Jedes Mal dachte ich, ich hätte ein Zuhause gefunden. Und jedes Mal wurde ich enttäuscht. | 6.0 s | `Zeile` | `19562ed6cf29f000 q202_05_convoy` |


## Zustimmung

**Wann:** V schlaegt etwas vor, Judy geht mit

Keine Bark deckt das ab.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Ich glaub, wir können. | 1.7 s | `Zeile` | `166b8c00b24ea000 q105_06a_fingers_escape` |
| Sehe ich genauso. | 1.8 s | `Zeile` | `1a7b507f262fc000 sq026_05a_leave` |
| Da könntest du recht haben. | 2.2 s | `Zeile` | `19faf887702b6000 sq026_05a_leave` |
| Wie du willst. | 1.6 s | `Zeile` | `1a33d8c6a32b6000 sq026_08_plan` |
| Wenn du meinst ... | 2.1 s | `Zeile` | `1a674041712fc000 sq030_09_pier` |
| Warum, gefällt’s dir nicht? | 2.2 s | `Zeile` | `137c5715552b1000 sq030_03_dam_equipment` |
| Das gefällt dir gar nicht, hm? | 2.5 s | `Zeile` | `19ec472e462b6000 sq030_09_pier` |


## Wasser und Schwimmen

**Wann:** Tauchen, Schwimmen, der See

Der gemeinsame Rueckzugsort - und die einzige Situation, in der Judy die Fuehrung hat. Keine Bark deckt das ab, jede Zeile muss gebaut werden.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Schwimm nicht zu weit weg, ja? Sonst werden wir nur asynchron. | 3.8 s | `Zeile` | `15c177f5d44e2000 sq030_06_lake_exploration` |
| Komm nicht zu schnell hoch, das ist gefährlich. | ? | `Zeile?` | `1be5242cf12b6000 sq030_06_lake_exploration` |
| Du steigst zu schnell hoch, V! | 2.0 s | `Zeile` | `1be52435972b6000 sq030_06_lake_exploration` |
| Fühlt sich echt komisch an, hier durchzuschwimmen ... | 4.1 s | `Zeile` | `1a6cc1fb6c2fc000 sq030_06_lake_exploration` |
| Komm, wir schwimmen noch ein bisschen weiter. | 3.2 s | `Zeile` | `1a6ce949fa2fc004 sq030_06_lake_exploration` |
| Sehr gut, hat geklappt. Jetzt schwimm zu mir. / Sehr gut, das hat geklappt. Jetzt hierher, V. | 4.3 s | `Zeile` | `135dba0e2a2fc000 sq030_05_lake_test` |
| Tauch nicht allein ab. Der Anzug hält dem Druck nicht stand. | 3.8 s | `Zeile` | `1be51b21f02b6000 sq030_05_lake_test` |
| Und das andere ... Na ja, ich tauch nicht mit jeder. / Und das andere ... Na ja, da bin ich wählerisch. | 5.5 s | `Zeile` | `18a6e78c9e2b6000 sq030_03_dam_equipment` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Was immer du vorhast, Judy. Ich bin dabei. | 4.3 s | `VVF` | `19c6ddabf55b3000 sq030_05_lake_test` |
| Klingt nova. Tun wir’s. | 2.4 s | `VVF` | `1a6181b1812fc000 sq030_05_lake_test` |

### Wortwechsel

**Weiter raus**

- **JUDY:** Komm, wir schwimmen noch ein bisschen weiter.  <sub>3.2 s &middot; `1a6ce949fa2fc004`</sub>
- **V:** Klingt nova. Tun wir’s.  <sub>2.4 s &middot; `1a6181b1812fc000`</sub>

Ihre Einladung, Vs Zusage - beide aus derselben Tauchquest.

**Nicht allein abtauchen**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Tauch nicht allein ab. Der Anzug hält dem Druck nicht stand.  <sub>3.8 s &middot; `1be51b21f02b6000`</sub>
- **JUDY:** Sehr gut, hat geklappt. Jetzt schwimm zu mir. / Sehr gut, das hat geklappt. Jetzt hierher, V.  <sub>4.3 s &middot; `135dba0e2a2fc000`</sub>

Erst die Warnung, dann das Heranwinken. Sie fuehrt hier.


## Wohnung und Uebernachtung

**Wann:** V ist bei ihr zu Hause, es wird spaet, jemand bleibt

Die Kategorie fehlte in allen drei Vorgaengerdokumenten, obwohl das Material vollstaendig da ist - vom Schluessel ueber den Kaffee bis zur Couch. Naeher an einer Beziehung als jede Liebeserklaerung.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Das war’s schon. Glückwunsch, du hast jetzt Zugang zu meiner Wohnung. | 5.0 s | `Zeile` | `18795a0a822fc000 sq030_11_morning` |
| Nein. Da. Unser Nest für heut Nacht. / Nein. Da drin. Ich übernachte da öfter nach dem Tauchen. | 4.3 s | `Zeile` | `18feb70a322b600c sq030_09_pier` |
| Du musst furchtbar frieren. Ich brüh was auf. | 3.5 s | `Zeile` | `1a676388f12fc000 sq030_09_pier` |
| Hier ist dein Kaffee. Endlich. | 2.5 s | `Zeile` | `1a96129b222b6000 sq030_11_morning` |
| Es ist spät. Du bist müde. | 2.4 s | `Zeile` | `18a2fa98762fc004 sq026_08_plan` |
| Wenn du willst, kannst du auf der Couch schlafen. | 2.3 s | `Zeile` | `18a2fa98762fc00c sq026_08_plan` |
| Oh, du bist schon da? Hättest ja sagen können, dass du kein Fan von Türen bist. | 4.8 s | `Zeile` | `1a04f187642fc000 q105_06a_fingers_escape` |
| Wenn du das willst ... Oder komm einfach vorbei, wenn du magst. | 4.9 s | `Zeile` | `18795a9ae52fc000 sq030_11_morning` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Vielleicht nur ein Zimmer? | ? | `VVF frei` | `1532045272401000 q103_15_roadhouse_bar` |
| Ich könnte die ganze Nacht hierbleiben. | 2.9 s | `VVF` | `39b494eb948bb000 mq055_05_downtown` |
| Sorry. Ist ein Notfall. | 2.1 s | `Bark` | `gp_vehicle_steal` |

### Wortwechsel

**Der Schluessel**

- **JUDY:** Das war’s schon. Glückwunsch, du hast jetzt Zugang zu meiner Wohnung.  <sub>5.0 s &middot; `18795a0a822fc000`</sub>
- **V:** Vielleicht nur ein Zimmer?  <sub>? &middot; `1532045272401000`</sub>

Erst das Vertrauen, dann das vorsichtige Nachfassen.

**Unser Nest fuer heut Nacht**

- **JUDY:** Nein. Da. Unser Nest für heut Nacht. / Nein. Da drin. Ich übernachte da öfter nach dem Tauchen.  <sub>4.3 s &middot; `18feb70a322b600c`</sub>
- **V:** Ich könnte die ganze Nacht hierbleiben.  <sub>2.9 s &middot; `39b494eb948bb000`</sub>

Ihre Ansage, Vs Zustimmung. Kein Wort zu viel.

**Durchs Fenster statt durch die Tuer**

- **JUDY:** Oh, du bist schon da? Hättest ja sagen können, dass du kein Fan von Türen bist.  <sub>4.8 s &middot; `1a04f187642fc000`</sub>
- **V:** Sorry. Ist ein Notfall.  <sub>2.1 s &middot; `gp_vehicle_steal`</sub>

Sie zieht V auf, V entschuldigt sich halbherzig.

**Kaffee, endlich**

- **JUDY:** Du musst furchtbar frieren. Ich brüh was auf.  <sub>3.5 s &middot; `1a676388f12fc000`</sub>
- **V:** Schwarz, bitte.  <sub>1.7 s &middot; `1a6769eccf2fc000`</sub>
- **JUDY:** Hier ist dein Kaffee. Endlich.  <sub>2.5 s &middot; `1a96129b222b6000`</sub>

Drei Zeilen, die zusammen einen ganzen Abend andeuten.

**Es wird spaet**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Es ist spät. Du bist müde.  <sub>2.4 s &middot; `18a2fa98762fc004`</sub>
- **JUDY:** Wenn du willst, kannst du auf der Couch schlafen.  <sub>2.3 s &middot; `18a2fa98762fc00c`</sub>

Die Feststellung und das Angebot. Dazwischen gehoert eine Pause.


## Fahrzeug

**Wann:** Ein- und Aussteigen, Warten am Wagen, gemeinsam fahren

Die Ausloeser liegen bereit - `OnEnterVehicle`, `OnExitVehicle`, `OnCompanionMounted` -, aber keines der drei Vorgaengerdokumente hatte eine Kategorie dafuer. Der Bestand ist duenn: Judy redet kaum uebers Fahren. Was da ist, sitzt dafuer genau.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Ja. Fahren wir zusammen? | 2.0 s | `Zeile` | `16bf05739e2b6000 q105_06c_finding_studio` |
| Ich warte im Auto. Beeil dich, okay? | 2.4 s | `Zeile` | `1a4e3b3a374ea000 q105_04a_judy_holocall` |
| Steig ein. | 1.1 s | `Zeile` | `157e1b71452fc000 q105_06c_finding_studio` |
| Ich komm mit. | 1.3 s | `Zeile` | `1bde5dd1d429f000 q203_02c_judy` |
| Mhm. Ich komm mit. | 2.1 s | `Zeile` | `1bde5d7e5429f000 q203_02c_judy` |
| Gern. Passt mir gut, ich sitz grad eh am Steuer. | 3.7 s | `Zeile` | `1b07df75762b6000 mq055_05_downtown` |
| Fahr hin, wenn du willst. Ich denke, ich bleib noch ein bisschen hier. | 6.3 s | `Zeile` | `18fa35b1a12b6000 sq030_11_morning` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Mega! Bleibst du im Auto? | ? | `VVF frei` | `1241e3e7202b6000 q204_04_to_music_store` |
| Wohin fahren wir? | ? | `VVF frei` | `1288ecf312404000 q114_03b_training` |

### Wortwechsel

**Fahren wir zusammen**

- **JUDY:** Ja. Fahren wir zusammen?  <sub>2.0 s &middot; `16bf05739e2b6000`</sub>
- **V:** Wohin fahren wir?  <sub>? &middot; `1288ecf312404000`</sub>

Ihre Frage, Vs Rueckfrage - passt auf jede Fahrt.

**Sie bleibt im Wagen**

- **V:** Mega! Bleibst du im Auto?  <sub>? &middot; `1241e3e7202b6000`</sub>
- **JUDY:** Ich warte im Auto. Beeil dich, okay?  <sub>2.4 s &middot; `1a4e3b3a374ea000`</sub>

V fragt, sie antwortet mit einer Bedingung. Beim Aussteigen ohne sie.

**Steig ein**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Steig ein.  <sub>1.1 s &middot; `157e1b71452fc000`</sub>
- **JUDY:** Ich komm mit.  <sub>1.3 s &middot; `1bde5dd1d429f000`</sub>

Kurz und beilaeufig, fuer den Moment am offenen Wagen.


## Der lange Blick

**Wann:** V sieht Judy laenger an, ohne etwas zu tun

`OnLookAtCompanion` und `OnLookAtCompanionEnd` gibt es fertig - sie haengen am Namensschild-Controller. Zu bauen ist nur die Uhr dazwischen.

Zwei Stufen, nicht eine. Unter fuenf Sekunden passiert nichts: man sieht seine Begleiterin staendig an, waehrend man laeuft. Ab etwa fuenf faellt es ihr auf und sie fragt nach - kurz, beilaeufig. Wer deutlich laenger schaut und die Beziehung hat, bekommt die zweite Ebene. Die vertraegt keine Wiederholung.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Was denn? | 1.1 s | `Zeile` | `1bde5efe6529f000 q203_02c_judy` |
| Gefällt’s dir? | 1.2 s | `Zeile` | `1362da25582fc000 sq030_05_lake_test` |
| Alles in Ordnung, V? | 1.0 s | `Zeile+Leih` | `39669645a8a4e000 mq055_05_downtown` |
| Alles in Ordnung bei dir? | 0.8 s | `Zeile+Leih` | `3966964c69a4e000 mq055_05_downtown` |
| Schon besser. Dachte für ’n Moment, du bist ’ne Langweilerin. / Schon besser. Dachte für ’n Moment, du bist ’n Langweiler. | 4.3 s | `Zeile` | `18ff52f8fd2b6000 sq030_09_pier` |
| Hmmm … Außen tough und innen süß. | 3.2 s | `Zeile+Leih` | `3966891225a4e000 mq055_01_megabuilding` |
| Außen tough ... und innen süß. | 4.2 s | `Zeile` | `1a676ce3032fc000 sq030_09_pier` |
| Wenn man das bedenkt, siehst du sogar sensationell aus. / Ach, komm schon, red keinen Blödsinn. | 3.9 s | `Zeile` | `189c5847c42b6000 sq030_01_dam_meetup` |
| Oh, heißt das, mein Timing war perfekt, oder denkst du immer an mich? | 4.7 s | `Zeile` | `18830b966a2b6000 sq030_00_holocall` |

### Wortwechsel

**Stufe eins - sie merkt es**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Was denn?  <sub>1.1 s &middot; `1bde5efe6529f000`</sub>
- **JUDY:** Gefällt’s dir?  <sub>1.2 s &middot; `1362da25582fc000`</sub>

Zwei kurze Zeilen als Pool, nicht als Folge. Ab etwa fuenf Sekunden.

**Stufe zwei - sie nimmt es auf**  <sub>Zeilenfolge, nur Judy</sub>

- **JUDY:** Schon besser. Dachte für ’n Moment, du bist ’ne Langweilerin. / Schon besser. Dachte für ’n Moment, du bist ’n Langweiler.  <sub>4.3 s &middot; `18ff52f8fd2b6000`</sub>
- **JUDY:** Außen tough ... und innen süß.  <sub>4.2 s &middot; `1a676ce3032fc000`</sub>

Deutlich laenger, und nur mit Beziehung. Hoechstens einmal je Sitzung.


## Tiefe Naehe

**Wann:** Nur nach abgeschlossener Romanze - nie im Ambient-Pool

Diese Zeilen tragen Gewicht und vertragen keine Wiederholung. Sie gehoeren an ein Ereignis, nicht an einen Zufallsgenerator.

### Judy

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Woher weißt du immer, wenn du mir fehlst? | 3.1 s | `Zeile` | `2ffdc7962d571000 judy_default` |
| Für dich hab ich den ganzen Tag. | 2.3 s | `Zeile` | `1b07e0e36d2b6000 mq055_05_downtown` |
| Wir haben alle Zeit der Welt. | 1.9 s | `Zeile` | `1b0791cfae2b6000 mq055_05_downtown` |
| Ich mag dich. Ich will dich oft sehen. Aus meiner Sicht gibt’s da nichts zu überlegen. | 7.0 s | `Zeile` | `18fa36f3f82b6000 sq030_11_morning` |
| Ich dich auch, V ... | 2.1 s | `Zeile` | `18f9fc80d42b6000 sq030_11_morning` |
| Außen tough ... und innen süß. | 4.2 s | `Zeile` | `1a676ce3032fc000 sq030_09_pier` |
| Hey, setzt du dich ein bisschen zu mir? | 2.0 s | `Zeile` | `184f1ffc6b2fc000 sq030_11_morning` |
| Gib mir deine Hand, V. | 1.6 s | `Zeile` | `184f3f3bbe2fc000 sq030_11_morning` |
| Ich weiß nicht, was ich mache, wenn du nicht mehr da bist. | 2.9 s | `Zeile` | `175e1a1cba386000 q201_05_cabin_day_7` |
| Ich bin froh, dass wir das tun. | 1.9 s | `Zeile` | `170a369e224e6000 q202_06_border_running` |
| Hab davon geträumt, wie es wird, wenn wir’s endlich schaffen ... | 3.1 s | `Zeile` | `19dbc1edd129f000 q202_06_border_running` |
| Scheiße ... Ich hab Angst, V. | 4.0 s | `Zeile` | `1401fd943a2fc000 sq026_08_plan` |
| Und solltest du je Hilfe brauchen, du weißt, dass ich für dich da bin, ja? Immer. | 6.8 s | `Zeile` | `18fe75e7ff3bc000 fb_judy` |
| Ich ... will einfach nicht über irgendwas davon nachdenken. Nicht heute. | 5.4 s | `Zeile` | `197a02720e2b6000 sq030_01_dam_meetup` |
| Ist es dein, ähm, blinder Passagier? Wird es schlimmer? | 5.5 s | `Zeile` | `1878a052fd2fc000 sq030_00_holocall` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Ich mag dich auch. Ein Grund mehr, das nicht ... | ? | `VVF frei` | `1b3506911a62301c sq029_05_morning_after` |
| Ich bin morgen bei dir. Egal, was passiert, wir bleiben zusammen und schaffen es irgendwie. | ? | `VVF frei` | `126b36bcba404000 q114_05_quiet_place` |
| Ich will dich nicht verlieren, aber ich muss hier bleiben. Ich kann nicht anders leben oder denken. Nicht mehr. | ? | `VVF` | `18e94ba7da29f000 q203_02d_panam` |

### Wortwechsel

**Sie sagt es**

- **JUDY:** Ich weiß nicht, was ich mache, wenn du nicht mehr da bist.  <sub>2.9 s &middot; `175e1a1cba386000`</sub>
- **V:** Ich mag dich auch. Ein Grund mehr, das nicht ...  <sub>? &middot; `1b3506911a62301c`</sub>

Hoechstens einmal. Danach nie wieder aus dem Zufallspool.

**Egal was kommt**

- **JUDY:** Scheiße ... Ich hab Angst, V.  <sub>4.0 s &middot; `1401fd943a2fc000`</sub>
- **V:** Ich bin morgen bei dir. Egal, was passiert, wir bleiben zusammen und schaffen es irgendwie.  <sub>? &middot; `126b36bcba404000`</sub>

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
| Pass auf dich auf, V. Komm in einem Stück zurück. | 4.3 s | `Zeile` | `14ab1431b629f000 q203_02c_judy` |
| Pass auf dich auf, V. | 1.7 s | `Zeile` | `19f164ba6d2b6004 sq030_11_morning` |
| Pass auf dich auf da draußen, V. | 2.3 s | `Zeile` | `1f0c4ccf9242f000 q203_02c_judy` |

### V

| Zeile | Dauer | Status | Quelle |
|---|---|---|---|
| Wenn irgendwas ist, ruf mich an, okay? | 2.2 s | `VVF` | `1a0a374e852fc000 sq026_01b_roof` |

### Wortwechsel

**Bis dann**

- **JUDY:** Bis dann, V.  <sub>1.5 s &middot; `1897d495012b6000`</sub>
- **V:** Wenn irgendwas ist, ruf mich an, okay?  <sub>2.2 s &middot; `1a0a374e852fc000`</sub>

Kurz halten. Die verspielte Fassung `Bis dahaaaann!` nur selten.


## Barks ohne Situation

Keine - alle 63 Judy-Barks sind einsortiert.

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

* **Vs Barks** sind nur dort einsortiert, wo ein Wortwechsel sie braucht. 160 gemessene Zeilen liegen in `data/vset_v_measured.json`.
* **Zustandslogik** - welche Situation ab welchem Beziehungsstand offen ist, steht noch nicht fest.
* **Abklingzeiten** - die Vorschlaege nennen Werte, geprueft ist keiner.
* **Dauern fuer Vs Zeilen** fehlen groesstenteils: `durations.json` deckt bisher nur die Szenen mit Judy ab.
