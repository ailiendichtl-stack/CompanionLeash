# Was wir heute verdrahten koennten - und was fehlt

Bestandsaufnahme vor dem Verdrahten. Die Zeilen sind da und spielbar; die Frage ist, woran
sie haengen sollen. Alles hier ist am Skript-Dump und an NCAs Quelltext geprueft, nicht
geschaetzt.

## Die kurze Antwort

**242 von 302 Zeilen (80 %) lassen sich heute verdrahten, ohne ein einziges neues Signal zu
bauen.** Weitere 23 kosten einen Blackboard-Listener. Was wirklich fehlt, sind 37 Zeilen -
und davon braucht nur ein Teil echte Arbeit.

| | Zeilen | woran es haengt |
|---|---|---|
| sofort verdrahtbar | **242** | vorhandene Ereignisse, nichts zu bauen |
| ein Listener noetig | 23 | Hocken und Schwimmen aus dem Blackboard |
| Judys Wohnung | 11 | ein Lua-Ortsmodul, kein Code |
| noch ohne Konzept | 26 | Aussicht, Zustimmung, Verabredung, gemeinsame Arbeit |

Die Zahl ist gegenueber der ersten Fassung gestiegen, aus zwei Gruenden: *Fahrzeug* und
*Der lange Blick* sind als Situationen dazugekommen, und die Wohnungsfrage war kleiner als
gedacht - Vs fuenf Apartments erkennt NCA bereits.

## Woher die Signale kommen

Drei Quellen, sehr unterschiedlich reich.

**Unsere eigene Mod** rechnet heute fuenf Dinge aus: Abstand, Blickwinkel, Judys
Geschwindigkeit, ob ein Kommando laeuft, und vergangene Zeit. Das ist wenig - aber es ist
genau das, was die Kategorie *Warten und Troedeln* braucht, und die ist mit 38 Zeilen die
groesste.

**NCA** liefert **39 Ereignisse**, und das ist der eigentliche Schatz:

```
Kampf      OnCombatStart/End, OnCompanionTakeDamage, OnCompanionDealDamage, OnCompanionDeath
Ort        OnEnterApartment/Exit, OnEnterLocation/Exit, OnChangeDistrict, OnEnterElevator/Exit
Fahrzeug   OnEnterVehicle/Exit, OnCompanionMounted
Zeit       OnHourPassed, OnMinutePassed, OnDayPassed, OnTimeSkip
Begleitung OnCompanionJoinSquad/Leave
Blick      OnLookAtCompanion, OnLookAtCompanionEnd
Sitzung    OnSessionStart/End, OnFastTravelStart/Complete
Sonstiges  OnQuestStart/Complete, OnConversationFinished, OnAction, OnTick(deltaTime)
```

**NCAs Kontext** fuehrt ausserdem einen Zustand mit, der einiges umsonst mitliefert:

```
isInCombat  isInCar  isInMenu  isInElevator  isInInteraction  isRestrictedTier
day  hour  minute        <- Tageszeit, ohne eigenen Zaehler
district  location       <- location ist ein CName, kein Bezirk
vehicle                  <- das Fahrzeug selbst, nicht nur "in einem"
```

**Das Spiel selbst**, ueber Blackboards und Systeme:

| Was | Wie | belegt |
|---|---|---|
| Hocken, Sprinten | `PlayerStateMachine.Locomotion` -> `gamePSMLocomotionStates` | ja |
| Schwimmen, Tauchen | `gamePSMSwimming`: `Surface`, `Diving` | ja |
| Regen | `WeatherSystem.GetRainIntensity()` / `GetRainIntensityType()` | ja |
| Gesundheit | `StatPoolSystem`-Listener auf `Health` | ja |
| Beziehungsstand | NCA fuehrt `love` / `friendship`, Posen koennen sie bewegen | ja |

## Situation fuer Situation

Sortiert nach Zeilenzahl - da liegt der Ertrag.

### Sofort verdrahtbar, kein neues Signal

| Situation | Zeilen | Ausloeser |
|---|---|---|
| Warten, Troedeln | **38** | unser eigener Abstand, plus `follow`-Zustand. Rechnen wir schon. |
| Sorge | **33** | `OnCompanionTakeDamage`, `StatPool` unter Schwelle, lange Abwesenheit |
| Kampf | **32** | `OnCombatStart` und laufender Kampf |
| Alltag *(ohne Ortsbezug)* | 26 | ruhige Lage, kein Kampf, Abklingzeit |
| Ankunft, Wiedersehen | 24 | `OnCompanionJoinSquad`, `OnSessionStart`, `OnFastTravelComplete` |
| Flirt | 17 | Beziehungsstand plus ruhige Lage plus lange Abklingzeit |
| Tiefe Naehe | 15 | dasselbe, haerter gegated, einmalig |
| Judy meldet sich | 14 | `OnHourPassed` und lange keine Begegnung |
| Nach dem Kampf | 9 | `OnCombatEnd` |
| Anerkennung | 4 | `OnCompanionDealDamage`, Kampfende ohne Schaden |
| Abschied | 3 | `OnCompanionLeaveSquad`, `OnFastTravelStart`, `OnSessionEnd` |

### Ein Blackboard-Listener, Vorbild vorhanden

| Situation | Zeilen | Ausloeser |
|---|---|---|
| Stealth | 13 | `Locomotion == Crouch` plus Entdeckungszustand |
| Wasser | 9 | `Swimming == Surface / Diving` |

### Ortserkennung - billiger als gedacht

Hier lag ich zuerst daneben. `OnEnterApartment` liefert zwar nur einen Bezirk, aber
`Context().location` ist ein **CName**, und NCA registriert bereits neun Orte:

```
Afterlife   Lizzies   Red Dirt   Totentaz
CorpoPlaza_Apartment   Glen_Apartment   H10_Apartment
JapanTown_Apartment    Northside_Apartment
```

**Alle fuenf Wohnungen von V sind also schon erkennbar.** Was fehlt, ist Judys - und ein
Ortsmodul ist reines Lua: `nca_location_apartment_glen.lua` hat **77 Zeilen**, im Kern
Weltkoordinaten fuer Sofa und Kueche. Kein Redscript, keine NCA-Aenderung.

| Situation | Zeilen | Lage |
|---|---|---|
| Alltag | 26 | in Vs Wohnung heute schon moeglich |
| Wohnung und Uebernachtung | 10 | braucht Judys Ort - ein Lua-Modul, kein Code |

Der Aufwand steckt nicht im Bauen, sondern im Beschaffen der Koordinaten. Das geht im Spiel
ueber eine Positionsanzeige, die unser Panel bekommen kann.

### Noch ohne Konzept

| Situation | Zeilen | was fehlt |
|---|---|---|
| Umgebung, Aussicht | 10 | kein Signal fuer "schoener Blick". Hoehe und Freiluft waeren eine Naeherung, kuratierte Orte die ehrliche Loesung. |
| Zustimmung | 5 | setzt voraus, dass **V** etwas vorschlaegt. Es gibt keine Oberflaeche dafuer. |
| Einladung | 5 | braucht einen Verabredungsbegriff - Termin, Ort, Erinnerung. |
| Gemeinsame Arbeit | 5 | braucht eine Taetigkeit (Virtu, Tauchgang), nicht nur eine Zeile. |

## Drei Funde, die die Planung aendern

**Der Blick braucht nicht einmal einen Patch.** `EventBus` ist eine `ScriptableSystem` mit
`public final func`-Methoden - die lassen sich mit `@wrapMethod` umschliessen, ohne NCAs
Quelltext anzufassen. Unsere Mod patcht heute genau eine NCA-Datei; der Blick-Trigger kommt
ohne aus und kostet damit auch keinen Merge-Aufwand bei NCA-Updates.

**Der Blick ist schon da.** `OnLookAtCompanion` haengt am Namensschild-Controller und feuert,
sobald V Judy anvisiert; `OnLookAtCompanionEnd` beim Wegsehen. Die Dauer messen wir selbst
dazwischen. Fuer "V sieht sie laenger an" ist damit **nichts zu bauen** - nur zu entscheiden,
ab welcher Sekunde es zaehlt und welche Zeilen daran haengen. Flirt und Naehe liegen bereit,
32 Zeilen.

**Wetter lohnt nicht.** Das Signal ist da, das Material nicht: neun Treffer in Judys ganzem
Bestand, und davon sind die meisten Fehltreffer. Brauchbar ist genau eine Zeile - *"Du musst
furchtbar frieren. Ich brueh was auf."* Ein Regen-Trigger fuer eine Zeile ist es nicht wert.

**Tageszeit dagegen schon.** 41 Zeilen beruehren sie, darunter *"Morgen."*, *"Ja, es ist
spaet."* und *"Es ist spaet. Du bist muede."* - die letzte steht bereits unter *Wohnung*.
`OnHourPassed` liefert das umsonst.

**Und eine Situation fehlt ganz: Fahrzeug.** `OnEnterVehicle`, `OnExitVehicle` und
`OnCompanionMounted` sind da, Judy hat rund 20 passende Zeilen - *"Ich warte im Auto. Beeil
dich, okay?"*, *"Fahren wir zusammen?"*, *"Gern. Passt mir gut, ich sitz grad eh am Steuer."*
Das ist eine ganze Kategorie, die in keinem der Dokumente vorkam.

## Animationen

Der groessere Hebel, und er kostet weniger Code als alles oben.

```
Auf Judys Rig verfuegbar     13.754
NCA registriert davon           479
ungenutzt                    13.275
```

NCA nimmt Animationen als **reinen Inhalt** entgegen - ein Lua-Modul, automatisch geladen,
keine Aenderung an NCA, kein Merge-Aufwand. Vorhanden sind unter anderem 11.114 `stand`,
8.576 `sit`, 695 dedizierte `idle`, 429 `kneel` fuer Hocken, und Judys vollstaendiges
Tauch-Moveset (`dive_idle`, `action___swim_01/02`, Drehuebergaenge).

Zwei Dinge daran sind fuer uns besonders interessant:

**Zeile plus Pose.** Eine Routine kann Animation und Stimme koppeln. *"Ich brueh was auf."*
mit einer passenden Steh-Idle ist etwas anderes als dieselbe Zeile im Laufmodus.

**Ortsgebundene Idles.** `judy_vibes_on_pool_table` bei Lizzie, das Tauch-Set am Wasser -
dieselbe Ortserkennung, die *Alltag* und *Wohnung* freischaltet, traegt auch das.

## Mein Vorschlag zur Reihenfolge

**Erst das, was nichts Neues braucht.** 189 Zeilen an vorhandenen Ereignissen. Das ist die
Masse, und es beantwortet die eigentliche offene Frage: fuehlt sich das im Spiel richtig an,
oder redet sie zu viel? Diese Antwort brauchen wir, bevor wir Signale bauen.

**Dann die zwei Blackboard-Leser.** Stealth und Wasser, 22 Zeilen, geringer Aufwand,
Vorbild vorhanden.

**Dann Ortserkennung.** Sie schaltet 36 Zeilen frei *und* die ortsgebundenen Idles. Der
Punkt mit dem besten Verhaeltnis von Aufwand zu Wirkung nach den ersten beiden.

**Parallel Animationen**, weil sie kein Code sind und nichts blockieren.

**Zuletzt die vier ohne Konzept.** Aussicht, Zustimmung, Einladung, gemeinsame Arbeit sind
zusammen 25 Zeilen und wollen jeweils ein eigenes System. Das ist der Punkt, an dem aus
Reaktion Interaktion wird - lohnend, aber nicht als Erstes.

## Die Leiter - Entwurf fuer Idle und spaeter Animationen

Der Blick benutzt sie schon, ohne dass sie so hiesse: eine erste Stufe frueh, eine zweite
deutlich spaeter, und wer die zweite bekommt, ueberspringt die erste. Fuer Idle ist genau
das die richtige Form, nur mit mehr Sprossen.

Gemessen wird **Stillstand**, nicht Ruhe.

```
V steht seit   25s   ->  Ungeduld: "Na los, worauf wartest du?"
               75s   ->  Smalltalk
              180s   ->  sie faengt von sich aus etwas an
```

Der erste Entwurf mass, wie lange nichts gesagt wurde. Das war das falsche Mass: Bewegung
ist Aktivitaet. Wer gerade quer durch die Stadt gelaufen ist, steht nicht seit acht Minuten
herum, auch wenn niemand geredet hat.

Zwei Regeln machen den Unterschied zwischen Leiter und Zufallsgenerator:

**Bewegung setzt sie zurueck.** Auf die erste Sprosse, sofort. Wer weitergeht, wartet nicht.

**Die Sprossen wachsen.** Gleichbleibende Abstaende erzeugen ein Ticken, und ein Ticken
merkt man nach dem dritten Mal. Wachsende Abstaende lesen sich als jemand, der irgendwann
aufgibt, still zu bleiben. Nach der letzten Sprosse schweigt sie, bis V sich bewegt.

Ruhe bleibt eine Sperre, aber nicht die Uhr: hat eben erst etwas anderes gesprochen, wartet
die Leiter, statt hinterherzureden.

Dieselbe Leiter traegt spaeter die Animationen: Sprosse eins eine Gewichtsverlagerung,
Sprosse zwei eine Pose, Sprosse drei etwas, das sie an den Ort bindet. Der Sprecher
entscheidet weiterhin, ob geredet wird - die Leiter entscheidet nur, WAS als Naechstes
faellig waere.

## Flirt: die Sperre ist wichtiger als der Ausloeser

Verdrahtet als dritte Blickstufe (75 s ansehen) und vierte Leitersprosse (7 min stehen).
Beides billig, weil die Uhren ohnehin laufen.

Das Entscheidende ist aber die **Sperre**. Wer die Romanze nie gespielt hat, darf nicht
angeflirtet werden - das ist keine Geschmacksfrage, das ist schlicht falsch, und es faellt
sofort auf. NCA fuehrt `love` je Figur in seiner `PersistenceSystem`, und `GetLove(recordID)`
ist von aussen erreichbar. Unbekannt heisst gesperrt, aber **sichtbar** gesperrt: der Wert
steht im Panel, ein stiller Riegel waere nach dieser Woche genau das falsche Verhalten.

Die Schwelle von 25 ist geraten - der Wert geht in NCAs Oberflaeche an einen Balken und
sieht nach 0..100 aus, geprueft ist das nicht.

Dazu ein **Zufallstimer, alle 10 bis 20 Minuten**. Blick und Leiter setzen beide Stillstand
voraus - wer durch die Stadt laeuft, erreicht keinen von beiden, und genau dort fehlt etwas:
sie geht neben V her, und irgendwann sagt sie einfach etwas. Der Abstand ist zufaellig, damit
sich kein Takt einstellt, und im Gefecht laeuft die Uhr nicht weiter - sonst haette sie nach
einem langen Kampf sofort etwas offen, und ein Flirt direkt nach dem letzten Schuss sitzt
falsch.

Alle drei Quellen ziehen aus **demselben Pool** und teilen sich dessen Abklingzeit. Getrennt
gefuehrt koennten sie sich kurz hintereinander bedienen, und Flirt soll selten sein - egal,
woher er kommt.

### Was sich sonst anbietet

**Nah und still.** V steht dicht bei ihr und bewegt sich nicht - das ist etwas anderes als
irgendwo herumzustehen, und der Abstand liegt jetzt vor. Zwei, drei Meter statt der acht,
die der Blick zulaesst.

**Nach einem gewonnenen Gefecht.** Sie ist aufgedreht, "Sieh uns an. Nicht totzukriegen." -
und ein Flirt dahinter sitzt anders als einer aus dem Leerlauf. Braucht Vorsicht, sonst
kommen zwei Zeilen hintereinander.

**Nachts.** `Context().hour` fuehrt NCA bereits mit; spaet und ruhig ist ein anderer Rahmen
als mittags auf der Strasse.

**Ort.** Sobald Judys Wohnung als NCA-Ort registriert ist, ist "bei ihr zu Hause" der
staerkste Rahmen ueberhaupt - und derselbe Ort schaltet *Wohnung* und *Alltag* mit frei.

## Offen: Sorge ist keine Situation, sondern vier

Nach den ersten Sitzungen: `sorge` haelt **30 Zeilen** und hat in 255 Minuten **einmal**
gefeuert. Das liegt nicht am Schwellenwert allein - die Kategorie fasst zusammen, was
denselben Tonfall hat, aber zu voellig verschiedenen Zeitpunkten gehoert.

Durchgesehen zerfaellt sie mindestens in vier Gruppen:

| gehoert zu | Beispiele |
|---|---|
| **Kampf** | *"Pass auf, verdammt! Schalt dein Hirn ein."* &middot; *"V, pass besser auf! Tot nuetzt du niemandem!"* |
| **Nach dem Kampf** | *"Alles okay? Schnauf mal kurz durch."* &middot; *"Tief durchatmen."* &middot; *"Hey, langsam ... Ganz ruhig."* |
| **Abschied** | *"Pass auf dich auf, V."* &middot; *"Komm in einem Stueck zurueck."* |
| **Wiedersehen** | *"Scheisse, V. Ich dachte, du bist tot."* &middot; *"Hab Schuesse gehoert. Lebst du noch?"* |
| **Naehe / Leiter 3** | *"Du kommst mir ... anders vor."* &middot; *"Du bist schon seit 'ner Woche so, V."* &middot; *"Wenn ich irgendwie helfen kann ..."* |

Was danach uebrig bleibt und wirklich an der Gesundheit haengt, sind vielleicht sechs
Zeilen - *"Alles in Ordnung, V?"*, *"Geht's dir wirklich gut?"*, *"V? Du siehst nicht gut
aus ..."*. Die anderen 24 warten auf einen Ausloeser, der nie kommt, weil sie am falschen
haengen.

**Nicht nur umhaengen, auch nachzaehlen:** dieselbe Frage steht bei jeder Kategorie mit
vielen Zeilen und wenigen Treffern. `log_report.py` zeigt sie - eine Situation mit dreissig
Zeilen und einem Treffer ist ein Hinweis auf eine falsche Zuordnung, nicht auf einen
seltenen Zustand.

**Nebenbei der Schwellenwert:** die Sorge-Schwelle vergleicht 40 gegen den ROHEN Wert des
Gesundheitspools. Bei ausgebautem Charakter steht der bei ueber 300, die Schwelle wird also
nie unterschritten. Sie muss auf den Anteil am Maximum rechnen.

## Was ich noch nicht weiss

* **Wie oft ist zu oft.** Keine der Abklingzeiten ist geprueft. Das entscheidet sich im
  Spiel, nicht auf dem Papier - und dann an `tools/log_report.py`, nicht am Gefuehl. Die
  erste Auswertung zeigt schon zweierlei: der Kampf-Ausloeser wollte 131-mal und durfte
  24-mal, und zehn Abstaende lagen unter zehn Sekunden.
* **Ob `NpcHandle.Talk` besser ist als unser Voiceset-Weg.** NCA hat eine eigene
  Sprachausgabe mit Gesicht und Blickrichtung. Ungeprueft, ob sie unsere Eintraege findet.
* **Judys Location-Modul in NCA** ist ein Stub mit 99 Zeilen. Ob wir es erweitern oder
  daneben bauen, ist offen.
