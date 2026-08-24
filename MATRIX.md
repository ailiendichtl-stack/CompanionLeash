# Bark- und Zeilen-Matrix

Bestandsaufnahme vor dem Verdrahten.

**Barks** aus `vset_judy.scene` - benannt, im Spiel gemessen, ueber den
Quest-Voiceset-Knoten sofort spielbar. 55 Zeilen, vollstaendig.

**Quest-Zeilen** sind **noch nicht spielbar** - dafuer braucht es Fake-Lipsync
ueber Audioware oder eine eigene Szene. Ihre Dauer ist aus der Zeichenzahl
geschaetzt, nicht gemessen.

## Was die Sichtung ergeben hat

Alle 816 eigenstaendigen Szenen-Zeilen wurden durchgelesen, dazu 111 weitere, die erst
durch den erweiterten Untertitel-Bestand sichtbar wurden. Brauchbar als Begleiter-Zeile
sind davon rund **110**.

**`mq055` ist der beste Fund.** Das ist die Hangout-Quest, und ihre Zeilen sind fuer genau
diese Art Begleiter-Interaktion geschrieben - "Komm schon, V. Bleib bei mir.", "Geniesst
du die Aussicht?", "Ich bin froh, dass du da bist." Sie fehlten bis eben komplett, weil
der Untertitel-Filter in `voice_inventory.py` sie nie erfasst hat. **`q202`** (Epilog)
fuellt die Kategorie Aussicht, die vorher gar keine Zeile hatte.

Der Rest handelt **von der Quest** - Evelyn, Fingers, Maiko, das Clouds, der
Braindance-Job - und funktioniert ausserhalb seines Zusammenhangs nicht, egal wie
gut er klingt. Das ist die wichtigste Einschraenkung fuer die Planung: die 1104
Quest-Zeilen sind kein Reservoir von 1104 einsetzbaren Zeilen.

Die vorherige Stichwortsuche war untauglich - sie beruehrte 20% der Zeilen, zeigte
davon sechs pro Kategorie und stellte dabei "Zusammen mit meinen Grosseltern"
unter Zuneigung. Der vollstaendige Bestand steht in [LINES.md](LINES.md).

---

## Ankunft / Wiedersehen

| Bark | s | Zeile |
|---|---|---|
| `return_answer_var_1` | 2.00 | Worüber hatten wir geredet? |
| `return_answer` | 1.40 | Du bist zurück. |
| `greeting_var_1` | 1.35 | Oh, hey! |
| `greeting` | 1.11 | Hey, V. |

Quest-Zeilen (gesichtet, 10):

- ~3.3s V! Siehst gut aus! | V, du bist echt gekommen.  <sub>`sq030_01_dam_meetup`</sub>
- ~2.5s Hey V, danke dass du gekommen bist.  <sub>`sq026_04_maiko`</sub>
- ~2.1s Ich bin froh, dass du da bist.  <sub>`judy_mq055_01_megabuilding`</sub>
- ~1.5s Gut, dass du da bist.  <sub>`q105_07_judy_braindance`</sub>
- ~1.4s Hey, da bist du ja.  <sub>`q004_03_this_is_judy`</sub>
- ~1.3s V! Siehst gut aus.  <sub>`judy_mq055_01_megabuilding`</sub>
- ~1.2s Hey, V! Was geht?  <sub>`fb_judy`</sub>
- ~1.2s Okay, ich bin da.  <sub>`q105_07_judy_braindance`</sub>
- ~1.2s V, da bist du ja!  <sub>`judy_q202`</sub>
- ~1.1s Wird auch Zeit.  <sub>`q105_02_lizzy_meet_judy`</sub>

## Spieler bleibt zurueck

| Bark | s | Zeile |
|---|---|---|
| `follow_me_1` | 2.70 | Was ist los? Hör auf zu trödeln. |
| `follow_me` | 2.26 | Komm schon, V, bleib bei mir. |
| `hurry_up_var_2` | 2.53 | Wir haben was vor, schon vergessen? |
| `hurry_up_var_3` | 2.11 | Konzentration, V. |
| `hurry_up_var_1` | 1.90 | Na? Los jetzt! |
| `urge_var_1` | 1.78 | Was ist mit dir los? |
| `urge` | 1.64 | Komm schon, V. |

Quest-Zeilen (gesichtet, 16):

- ~2.7s Deine Entscheidung, aber trödel nicht.  <sub>`q105_07_judy_braindance`</sub>
- ~2.7s Na dann komm. Ich will dir was zeigen.  <sub>`sq030_06_lake_exploration`</sub>
- ~2.6s Jepp. Bin sofort da. Warte auf mich.  <sub>`q105_07_judy_braindance`</sub>
- ~2.6s Jepp, bin sofort da. Warte auf mich.  <sub>`judy_mq055_01_megabuilding`</sub>
- ~2.3s Komm schon! Keine falsche Scheu.  <sub>`sq030_01_dam_meetup`</sub>
- ~2.1s Komm schon, V. Bleib bei mir.  <sub>`judy_mq055_04_heywood`</sub>
- ~1.9s V, warte. Ich bin ganz nah.  <sub>`q105_07_judy_braindance`</sub>
- ~1.9s Aye aye, Käpt’n – mir nach.  <sub>`sq030_06_lake_exploration`</sub>
- ~1.9s Wart ’ne Sekunde auf mich.  <sub>`q105_07_judy_braindance`</sub>
- ~1.9s Na los, worauf wartest du?  <sub>`q105_02_lizzy_meet_judy`</sub>
- ~1.6s Lass mich nicht warten.  <sub>`judy_mq055_04_heywood`</sub>
- ~1.5s V? Worauf wartest du?  <sub>`q004_03_this_is_judy`</sub>
- ~1.4s V, lass uns abhauen.  <sub>`sq026_05a_leave`</sub>
- ~1.1s Komm, gehen wir.  <sub>`sq026_04_maiko`</sub>
- ~1.1s Schon unterwegs.  <sub>`sq030_06_lake_exploration`</sub>
- ~1.0s V, warte noch.  <sub>`sq026_05a_leave`</sub>

## Warten / Ungeduld

| Bark | s | Zeile |
|---|---|---|
| `interrupt_var_1` | 2.54 | Okay, wir setzen das später fort. |
| `interrupt` | 1.85 | Hab ich dich gelangweilt? |
| `phone_urge_var_2` | 2.68 | Bist du da? Kannst du mich hören? |
| `phone_urge_var_1` | 1.76 | Äh ... V? |

Quest-Zeilen (gesichtet, 6):

- ~3.3s Sei vorsichtig, okay? Ich warte hier auf dich.  <sub>`judy_q115`</sub>
- ~3.0s Okay ... Aber lass dir nicht zu viel Zeit.  <sub>`q105_06c_finding_studio`</sub>
- ~2.6s Sag Bescheid, wenn du weiter willst.  <sub>`sq030_06_lake_exploration`</sub>
- ~2.3s Was sagst du, wollen wir weiter?  <sub>`sq030_06_lake_exploration`</sub>
- ~2.1s Okay, ich warte hier auf dich.  <sub>`judy_q202`</sub>
- ~1.9s So lang hat das nicht Zeit.  <sub>`q105_06a_fingers_escape`</sub>

## Kampf

| Bark | s | Zeile |
|---|---|---|
| `battlecry_morale_var_1` | 2.55 | Jetzt bin ich richtig sauer! |
| `battlecry_morale_var_3` | 2.10 | Jetzt mach ich ernst! |
| `battlecry_morale` | 1.75 | Hast es so gewollt! |
| `combat_aggro_bark_var_1` | 1.42 | Echt jetzt?! |
| `combat_aggro_bark_var_2` | 1.34 | Aaah! |
| `enemy_warning_var_2` | 2.06 | Sie sind hier. Bleib wachsam. |
| `enemy_warning_var_1` | 1.41 | Da kommen sie! |
| `battlecry_curse_var_3` | 2.89 | Hey, V! Mach was, verdammte Scheiße! |
| `battlecry_curse_var_2` | 1.65 | Was zur Hölle? |
| `battlecry_curse` | 1.18 | Fuuuck! |
| `danger_var_1` | 1.88 | Oh, Scheiße! |
| `danger_var_3` | 1.38 | Bin bei dir. |
| `danger` | 1.22 | Achtung! |
| `elite_warning_var_1` | 2.72 | Wo haben die nur diese Ausrüstung her? |
| `elite_warning_var_2` | 2.32 | Ordentlich ausgestattet, die Typen! |
| `grenade_enemy_var_3` | 2.23 | In Deckung! Granate! |
| `grenade_enemy_var_2` | 1.92 | Achtung, Granate! |
| `grenade_enemy_var_1` | 1.45 | Granate! |
| `grenade_throw` | 2.28 | Na, wie schmeckt dir das?! |
| `reloading_var_3` | 2.07 | Warte kurz, muss nachladen. |
| `reloading_var_2` | 2.01 | Deck mich, ich lade nach! |
| `reloading_var_1` | 1.70 | Ich muss nachladen. |

Quest-Zeilen (gesichtet, 7):

- ~2.7s Kommeee! Die sind so gut wie erledigt!  <sub>`sq030_06_lake_exploration`</sub>
- ~2.4s Ich lenk sie ab, du erledigst sie.  <sub>`q105_07_judy_braindance`</sub>
- ~2.4s Pass auf – da könnten Leute sein.  <sub>`sq026_11_to_penthouse`</sub>
- ~1.9s Kannst du sie ausschalten?  <sub>`sq026_11_to_penthouse`</sub>
- ~1.6s Jetzt! Mach sie fertig!  <sub>`q105_07_judy_braindance`</sub>
- ~1.6s Vorsicht. Da sind zwei.  <sub>`q105_07_judy_braindance`</sub>
- ~1.6s Erledige die, schnell.  <sub>`q105_07_judy_braindance`</sub>

## Kampf vorbei / Lob

| Bark | s | Zeile |
|---|---|---|
| `combat_ended_var_1` | 2.84 | Oh, das war’s. Wir haben’s geschafft. |
| `combat_ended_var_2` | 2.83 | Sieh uns an. Nicht totzukriegen. |

Quest-Zeilen (gesichtet, 6):

- ~4.5s Fresst das, Arschlöcher. Scheint, als hättest du alle erwischt.  <sub>`q105_07_judy_braindance`</sub>
- ~3.5s Du verschwendest keine Munition. Bin beeindruckt.  <sub>`q105_07_judy_braindance`</sub>
- ~3.1s Okay, jetzt geht der Spaß erst richtig los.  <sub>`judy_mq055_01_megabuilding`</sub>
- ~2.1s Dein Ernst? Die ist großartig!  <sub>`sq030_06_lake_exploration`</sub>
- ~1.6s Heeey, nicht schlecht.  <sub>`judy_mq055_04_heywood`</sub>
- ~1.4s Hey, nicht schlecht.  <sub>`q105_07_judy_braindance`</sub>

## Stealth

| Bark | s | Zeile |
|---|---|---|
| `stealth_restored_var_1` | 2.25 | Perfekt, die sehen uns nicht mehr. |
| `stealth_restored_var_2` | 1.79 | Die haben wir abgeschüttelt. |
| `stealth_warning_bark_var_2` | 1.33 | Vorsicht! |
| `stealth_warning_bark_var_1` | 1.25 | Sei still! |
| `detection_warning_var_1` | 2.86 | Verschwinde da, sonst sehen sie uns! |
| `detection_warning_var_2` | 2.38 | Vorsicht, die haben was gehört! |
| `camera_warning_var_1` | 2.13 | Pass auf die Kameras auf, okay? |
| `camera_warning_var_2` | 2.07 | Die haben hier alles im Blick. |
| `body_warning_var_1` | 3.15 | Lass uns hier klar Schiff machen, sonst fliegen wir auf. |
| `body_warning_var_2` | 2.22 | Versteck den Körper, okay? |

Quest-Zeilen (gesichtet, 3):

- ~2.6s Danach schleichen wir uns vorbei ...  <sub>`q105_07_judy_braindance`</sub>
- ~1.6s Gesichert. Geh weiter.  <sub>`q105_07_judy_braindance`</sub>
- ~1.1s Mist, entdeckt!  <sub>`q105_07_judy_braindance`</sub>

## Spieler verletzt / Sorge

| Bark | s | Zeile |
|---|---|---|
| `player_fallback_var_2` | 3.46 | V, pass besser auf! Tot nützt du niemandem! |
| `player_fallback_var_1` | 2.84 | Pass auf, verdammt! Schalt dein Hirn ein. |
| `player_fallback_var_3` | 2.76 | Alles okay? Schnauf mal kurz durch. |
| `grapple` | 3.94 | Ungh ... Aaargh ... Lass ... los! |

Quest-Zeilen (gesichtet, 18):

- ~3.9s Schön langsam atmen. Ruhig. Alles okay, dir geht’s gut.  <sub>`judy_q004`</sub>
- ~3.5s Pass auf dich auf, V. Komm in einem Stück zurück.  <sub>`q203_02c_judy`</sub>
- ~3.3s Oh, ich kenne diese Stimme, V. Alles ... okay?  <sub>`sq030_00_holocall`</sub>
- ~2.6s Was zum Teufel, V? Bist du ... krank?  <sub>`sq026_08_plan`</sub>
- ~2.6s Hey, es war ja nicht deine Schuld ...  <sub>`judy_q115`</sub>
- ~2.6s Scheiße, V. Ich dachte, du bist tot.  <sub>`judy_q201`</sub>
- ~2.4s Hab Schüsse gehört. Lebst du noch?  <sub>`q105_07_judy_braindance`</sub>
- ~2.3s Pass auf dich auf da draußen, V.  <sub>`q203_02c_judy`</sub>
- ~2.1s V? Du siehst nicht gut aus ...  <sub>`sq026_08_plan`</sub>
- ~2.1s Sag schon, wie fühlst du dich?  <sub>`judy_q004`</sub>
- ~2.0s Hey, langsam ... Ganz ruhig.  <sub>`sq030_09_pier`</sub>
- ~1.9s Ganz ruhig, ist alles okay?  <sub>`sq026_08_plan`</sub>
- ~1.9s Du solltest langsam machen.  <sub>`sq030_09_pier`</sub>
- ~1.8s Alles in Ordnung bei dir?  <sub>`sq030_01_dam_meetup`</sub>
- ~1.7s Geht’s dir wirklich gut?  <sub>`sq030_09_pier`</sub>
- ~1.5s Pass auf dich auf, V.  <sub>`sq030_11_morning`</sub>
- ~1.4s Alles in Ordnung, V?  <sub>`judy_q004`</sub>
- ~1.1s Tief durchatmen.  <sub>`judy_mq055_01_megabuilding`</sub>

## Idle / Smalltalk

| Bark | s | Zeile |
|---|---|---|
| `bump_var_2` | 2.01 | Komm schon, ernsthaft? |
| `bump_var_1` | 1.71 | Hey, pass auf ... |

Quest-Zeilen (gesichtet, 16):

- ~4.4s Was auch immer du jetzt vorhast ... Kann ich irgendwie helfen?  <sub>`q203_02c_judy`</sub>
- ~3.8s Schon gelangweilt? Wir können weiter, wenn du willst.  <sub>`sq030_06_lake_exploration`</sub>
- ~3.0s Wie trinkst du deinen? Heh, genau wie ich.  <sub>`judy_mq055_05_downtown`</sub>
- ~2.9s Mal sehen, was wir noch so alles finden.  <sub>`sq030_06_lake_exploration`</sub>
- ~2.7s Willst du schon weg? Kein Sightseeing?  <sub>`sq030_06_lake_exploration`</sub>
- ~2.6s Was ist sonst so in deinem Leben los?  <sub>`judy_default`</sub>
- ~1.4s Ooooh, ausgefallen.  <sub>`judy_mq055_05_downtown`</sub>
- ~1.3s Hast du ’ne Kippe?  <sub>`sq026_01b_roof`</sub>
- ~1.3s Machen wir weiter.  <sub>`judy_q004`</sub>
- ~1.3s Und? Was sagst du?  <sub>`judy_q004`</sub>
- ~1.2s Was gibt’s Neues?  <sub>`judy_default`</sub>
- ~1.2s Ich brüh was auf.  <sub>`judy_mq055_05_downtown`</sub>
- ~1.1s Wie sieht’s aus?  <sub>`sq026_12_penthouse_gameplay`</sub>
- ~1.1s Sieh dich um ...  <sub>`sq030_06_lake_exploration`</sub>
- ~1.1s Was machen wir?  <sub>`q105_07_judy_braindance`</sub>
- ~1.0s Wie geht’s so?  <sub>`judy_mq055_04_heywood`</sub>

## Zuneigung / Naehe

*Keine Bark deckt das ab - hier lohnt sich Fake-Lipsync am meisten.*

Quest-Zeilen (gesichtet, 11):

- ~6.1s Ich mag dich. Ich will dich oft sehen. Aus meiner Sicht gibt’s da nichts zu überlegen.  <sub>`sq030_11_morning`</sub>
- ~4.6s Hab davon geträumt, wie es wird, wenn wir’s endlich schaffen ...  <sub>`judy_q202`</sub>
- ~4.1s Ich weiß nicht, was ich mache, wenn du nicht mehr da bist.  <sub>`judy_q201`</sub>
- ~2.9s Woher weißt du immer, wenn du mir fehlst?  <sub>`judy_default`</sub>
- ~2.8s Hey, setzt du dich ein bisschen zu mir?  <sub>`sq030_11_morning`</sub>
- ~2.3s Für dich hab ich den ganzen Tag.  <sub>`judy_default`</sub>
- ~2.2s Ich bin froh, dass wir das tun.  <sub>`judy_q202`</sub>
- ~2.1s Außen tough ... und innen süß.  <sub>`sq030_09_pier`</sub>
- ~2.1s Wir haben alle Zeit der Welt.  <sub>`judy_default`</sub>
- ~1.6s Gib mir deine Hand, V.  <sub>`sq030_11_morning`</sub>
- ~1.4s Ich dich auch, V ...  <sub>`sq030_11_morning`</sub>

## Umgebung / Aussicht

*Keine Bark deckt das ab - hier lohnt sich Fake-Lipsync am meisten.*

Quest-Zeilen (gesichtet, 10):

- ~8.1s Mhm. Von hier aus sieht die Stadt so weit weg und unschuldig aus. Komisches Gefühl ... Als wär ich ein Flüchtling.  <sub>`judy_q202`</sub>
- ~6.4s Jedes Mal dachte ich, ich hätte ein Zuhause gefunden. Und jedes Mal wurde ich enttäuscht.  <sub>`judy_q202`</sub>
- ~5.1s Fast, als wären wir jenseits von Raum und Zeit. Wie in ’ner Schneekugel.  <sub>`sq030_06_lake_exploration`</sub>
- ~5.0s Ich hab gerade erst erkannt, dass Night City nie richtig für mich war.  <sub>`judy_q202`</sub>
- ~3.9s Genießt du die Aussicht? | Hübsche Aussicht, Machoman?  <sub>`sq030_05_lake_test`</sub>
- ~2.6s Wollen wir über den Platz schlendern?  <sub>`sq030_06_lake_exploration`</sub>
- ~2.5s Frag mich, ob’s mir fehlen wird ...  <sub>`judy_q202`</sub>
- ~1.7s Genießt du die Aussicht?  <sub>`judy_mq055_05_downtown`</sub>
- ~1.4s Beeindruckend, oder?  <sub>`sq030_05_lake_test`</sub>
- ~1.0s Gefällt’s dir?  <sub>`sq030_05_lake_test`</sub>

## Zustimmung

*Keine Bark deckt das ab - hier lohnt sich Fake-Lipsync am meisten.*

Quest-Zeilen (gesichtet, 5):

- ~1.9s Da könntest du recht haben.  <sub>`sq026_05a_leave`</sub>
- ~1.6s Ich glaub, wir können.  <sub>`q105_06a_fingers_escape`</sub>
- ~1.3s Wenn du meinst ...  <sub>`sq030_09_pier`</sub>
- ~1.2s Sehe ich genauso.  <sub>`sq026_05a_leave`</sub>
- ~1.0s Wie du willst.  <sub>`sq026_08_plan`</sub>

## Wasser / Schwimmen

*Keine Bark deckt das ab - hier lohnt sich Fake-Lipsync am meisten.*

Quest-Zeilen (gesichtet, 3):

- ~4.4s Schwimm nicht zu weit weg, ja? Sonst werden wir nur asynchron.  <sub>`sq030_06_lake_exploration`</sub>
- ~3.4s Komm nicht zu schnell hoch, das ist gefährlich.  <sub>`sq030_06_lake_exploration`</sub>
- ~2.1s Du steigst zu schnell hoch, V!  <sub>`sq030_06_lake_exploration`</sub>

