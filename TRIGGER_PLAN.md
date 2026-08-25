# Was wir heute verdrahten koennten - und was fehlt

Bestandsaufnahme vor dem Verdrahten. Die Zeilen sind da und spielbar; die Frage ist, woran
sie haengen sollen. Alles hier ist am Skript-Dump und an NCAs Quelltext geprueft, nicht
geschaetzt.

## Die kurze Antwort

**189 von 272 Zeilen (69 %) lassen sich heute verdrahten, ohne ein einziges neues Signal zu
bauen.** Weitere 22 kosten einen Blackboard-Listener. Der Rest haengt an drei Dingen, von
denen nur eines wirklich Arbeit ist.

| | Zeilen | woran es haengt |
|---|---|---|
| sofort verdrahtbar | **189** | vorhandene Ereignisse, nichts zu bauen |
| ein Listener noetig | 22 | Spielerzustand aus dem Blackboard |
| Ortserkennung noetig | 36 | *welche* Wohnung, nicht nur *eine* |
| noch ohne Konzept | 25 | Aussicht, Zustimmung, Verabredung, gemeinsame Arbeit |

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

### Ortserkennung noetig

`OnEnterApartment` liefert nur einen **Bezirk**, nicht *welche* Wohnung. Fuer *Kaffee, Pizza,
Zuhause* und *Wohnung und Uebernachtung* ist aber genau das der Unterschied - dieselbe Zeile
in Vs Apartment und in Judys sagt nicht dasselbe.

| Situation | Zeilen |
|---|---|
| Alltag *(mit Ortsbezug)* | 26 |
| Wohnung und Uebernachtung | 10 |

NCAs Location-Module sind der vorgesehene Weg dafuer; Lizzies ist mit 261 Zeilen ausgebaut,
Judys Revier nur angefangen.

### Noch ohne Konzept

| Situation | Zeilen | was fehlt |
|---|---|---|
| Umgebung, Aussicht | 10 | kein Signal fuer "schoener Blick". Hoehe und Freiluft waeren eine Naeherung, kuratierte Orte die ehrliche Loesung. |
| Zustimmung | 5 | setzt voraus, dass **V** etwas vorschlaegt. Es gibt keine Oberflaeche dafuer. |
| Einladung | 5 | braucht einen Verabredungsbegriff - Termin, Ort, Erinnerung. |
| Gemeinsame Arbeit | 5 | braucht eine Taetigkeit (Virtu, Tauchgang), nicht nur eine Zeile. |

## Drei Funde, die die Planung aendern

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

## Was ich noch nicht weiss

* **Wie oft ist zu oft.** Keine der Abklingzeiten ist geprueft. Das entscheidet sich im
  Spiel, nicht auf dem Papier.
* **Ob `NpcHandle.Talk` besser ist als unser Voiceset-Weg.** NCA hat eine eigene
  Sprachausgabe mit Gesicht und Blickrichtung. Ungeprueft, ob sie unsere Eintraege findet.
* **Judys Location-Modul in NCA** ist ein Stub mit 99 Zeilen. Ob wir es erweitern oder
  daneben bauen, ist offen.
