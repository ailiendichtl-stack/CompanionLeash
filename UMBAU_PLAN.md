# Umbauplan nach dem NCA-Fund

Bestaetigt am 2026-08-26, nach dem Crouch und der Bestandsaufnahme in
[NCA_VERGLEICH.md](NCA_VERGLEICH.md).

## Warum gestaffelt und nicht in einem Zug

Es fuehlt sich nach einem grossen Umbau an, ist aber keiner. Von sieben Sachen ist genau
**eine** architektonisch - die Begegnungs-Klammer. Der Rest haengt nicht zusammen und ist
einzeln testbar. Ein grosser Wurf wuerde sie kuenstlich verkoppeln, und wir haben gerade
eine Woche dafuer bezahlt, was eine einzige unbelegte Annahme kostet.

Jeder Schritt bleibt fuer sich ausliefer- und ruecknehmbar.

## Was unangetastet bleibt

**Der Sprecher.** Der Log zeigt ihn beim korrekten Arbeiten: er tritt bei fremder Stimme
zurueck, haelt Abklingzeiten, priorisiert. Wir erweitern nur seine *Darbietung* um Blick und
Mimik. Die Ausloeser bleiben zunaechst unabhaengige Kunden.

---

## 1. Blickkontakt vor jeder Zeile

    Sprecher nimmt Zeile an
      -> Judy schaut zu V
      -> Voiceset-Zeile startet
      -> vorhandenes Lipsync laeuft
      -> Blick endet nach Zeile + Nachlauf

Ein Aufruf, wirkt auf alle 244 Zeilen, aendert keine Ausloeser-Architektur. NCA nutzt in
`Talk()` denselben Ablauf: Blick aktivieren, Stimme spielen, Mimik anwenden.

**Der Sprecher besitzt den Lebenszyklus, nicht die einzelnen Ausloeser.** Sonst laufen bei
konkurrierenden Anfragen mehrere unabhaengige Abschalt-Uhren gegeneinander - und der
Sprecher ist genau die Stelle, die es schon heute verhindert.

## 2. NCAs Kontext lesen statt selbst abfragen

Codeabbau, kein neuer Unterbau:

| statt | nehmen wir |
|---|---|
| eigene Fahrzeugabfrage | `isInCar` |
| eigene Menuepruefung | `isInMenu` |
| - | `location` (Wohnung, Ort) |
| - | `isInInteraction` als globale Sprechsperre |
| `PlayerStateMachine.Combat` | `isInCombat` als gemeinsames Kampf-Gatter |

Alle Felder sind public und aus CET lesbar - keine Bruecke noetig.

**Achtung:** die eigenen Abfragen bleiben zunaechst als Diagnose stehen, bis der Log zeigt,
dass NCA und wir **dieselben Uebergaenge** melden. Genau hier lag der Kampf-Fehler: zwei
Systeme haben dieselbe Grenze verschieden gemessen. Erst vergleichen, dann abbauen.

## 3. Wohnungsmodus und Pools

Kein Poolwechsel, ein anderer Kontextmodus. Und die 36 Zeilen werden **nicht** als 36
Sonderfaelle verdrahtet, sondern datengetrieben:

    location -> Profil -> erlaubte Situationen

    ApartmentProfile:
      allow    = { alltag, smalltalk, flirt, naehe, stolz }
      suppress = { reibung, abschied, distant_follow }
      cooldownMultiplier = 1.5

Zu Hause ist Stillstehen der Normalfall, nicht Vernachlaessigung - die Leiter misst dort das
Falsche. Weniger Ungeduld, mehr Smalltalk, hoeherer Beziehungsanteil, laengere natuerliche
Pausen. Spaeter eigene Idle- und Animationsprioritaeten.

## 4. Besitzmatrix fuer Barks

Vor der Klammer, nicht danach. Technisch klein, aber sonst bauen wir die Zustandsmaschine
und entscheiden erst hinterher, wem welche Zeile gehoert.

    NCA-Ereignis / Zustand  ->  nativer Bark  ->  unser Ersatz / Zusatz / Unterdrueckung

Bekannt bisher: `CombatBehavior.OnAttach` -> `enemy_warning`;
`CatchUpToPlayerBehavior` -> `greeting` (nur nach Abhaengen, **nicht** beim Laden);
jeder Lagewechsel nach `Alerted`/`Combat` -> Vanilla-Bark; `Stealth`/`Relaxed` -> keiner
(gemessen, vier Wechsel ohne Bark).

## 5. Begegnungs-Klammer  (ausgearbeitet)

Der eine echte Umbau. Alles andere in diesem Plan war Zubehoer; hier bekommen drei Ausloeser
zum ersten Mal einen gemeinsamen Begriff.

### Warum ueberhaupt

Heute misst jeder Ausloeser fuer sich, und drei Fehler folgen daraus:

* **Stealth-Einstieg wiederholt sich.** Aufstehen und wieder ducken im selben Gefecht ist
  derselbe Moment, aber der Ausloeser sieht nur "Locomotion == Crouch" und feuert erneut.
* **Kampfende haengt am Flag.** `Combat == false` kommt auch zwischen zwei Wellen. Die Zeile
  "das war knapp" kommt dann mitten hinein.
* **Nichts weiss, ob NCA schon gesprochen hat.** Wir erkennen fremde Stimmen, ordnen sie aber
  keinem Vorgang zu - also koennen wir auch nicht zurueckhalten.

### Der Zustand

    begegnung = {
      offen         = false,
      seitStart     = 0.0,   -- wie lange laeuft sie
      seitRuhe      = 0.0,   -- wie lange nichts mehr passiert ist
      hatteKampf    = false,
      hatteStealth  = false,
      kaempfe       = 0,     -- Wellen: Combat true->false->true zaehlt zwei
      fremdGesagt   = false, -- eine ihrer eigenen Barks lief waehrenddessen
      generation    = 0,     -- steigt bei jedem Oeffnen
    }

`generation` ist nicht Zierde: eine Anfrage, die waehrend Begegnung 3 gestellt wurde, darf in
Begegnung 4 nicht mehr angenommen werden. Der Sprecher hat dieselbe Idee schon (`S.gen`).

### Was sie oeffnet, haelt und schliesst

| | Signal | Stand |
|---|---|---|
| oeffnet | `psm("Combat") == 1` | **gesichert**, lesen wir laengst |
| oeffnet | Feind in X m | **UNGEPRUEFT** - siehe Schritt 0 |
| haelt | Kampf laeuft, oder Feind da, oder sie liegt | gesichert |
| schliesst | nichts davon, N Sekunden am Stueck | N wird gemessen, nicht geraten |

**Das Ruhefenster ist der Kern.** `Combat == false` allein ist wertlos - es faellt auch
zwischen zwei Wellen. Deshalb: kein Kampf, keine Bedrohung, kein neuer Schaden, N Sekunden
stabil.

### Vorgehen: erst messen, dann sperren

Derselbe Zuschnitt wie Phase 2, und aus demselben Grund.

**Schritt 0 - herausfinden, ob wir Feinde sehen.** Ein Panel-Knopf, der einmal abfragt und
protokolliert, was zurueckkommt. Faellt das aus, oeffnet die Begegnung nur ueber den Kampf,
und der Stealth-Einstieg haengt an "geduckt, seit dem letzten Gefecht noch nicht gesagt". Das
waere weniger, aber immer noch besser als heute.

**Schritt 1 - Klammer laeuft mit, sperrt nichts.** Sie oeffnet, zaehlt, protokolliert:

    BEGEGNUNG geoeffnet (Kampf)
    BEGEGNUNG Welle 2
    BEGEGNUNG fremde Stimme waehrenddessen: "Da kommen sie!"
    BEGEGNUNG geschlossen nach 84s, 3 Wellen, Ruhe 6.2s

Nach ein paar Sitzungen sagt der Log, wie lang das Ruhefenster sein muss. Die 2-5 s aus dem
Entwurf sind geraten; die echte Zahl steht im Log.

**Schritt 2 - dann erst die drei Ausloeser daranhaengen.**

    Stealth-Einstieg   einmal je Begegnung, nur wenn V duckt
    kampf              einmal je Welle, nur wenn `fremdGesagt` falsch
    kampf_ende         beim SCHLIESSEN, nicht beim Flag

### Kampf neben NCA - jetzt mit Daten

Die Besitzmatrix (16 gesammelte Barks) hat die Grenze verschoben: die native Ebene deckt den
Kampf **dicht** ab - Granaten, Nachladen, Treffer, Anruecken, Ueberstehen -, ausserhalb ist
sie fast stumm.

Also nicht "nachreichen, wenn NCA schweigt", sondern **zurueckhalten, solange sie selbst
redet**:

    fremde Stimme waehrend der Begegnung  ->  begegnung.fremdGesagt = true
                                         ->  eigene kampf-Anfrage wird verworfen

`kampf_ende` bleibt bei uns: "Sieh uns an. Nicht totzukriegen." ist ihre einzige Zeile dafuer,
und unsere neun sind besser. Aber erst nach dem Ruhefenster.

**Nicht** ueber Hoerbarkeit entscheiden. "Nicht wahrgenommen" und "nicht ausgeloest" sind
verschiedene Dinge - das hat die Voiceset-Arbeit vorgefuehrt.

### Was dabei schiefgehen kann

* **Begegnung schliesst nie.** Wenn ein Signal haengenbleibt - wie NCAs `isInCombat`, das wir
  deswegen nicht benutzen -, laeuft sie ewig und sperrt alles. Deshalb eine harte Obergrenze:
  nach X Minuten ohne Kampf wird sie geschlossen, mit Protokolleintrag.
* **Begegnung schliesst zu frueh.** Dann kommt "das war knapp" zwischen zwei Wellen. Genau
  dagegen wird N gemessen statt gesetzt.
* **Alte Anfragen.** Ohne `generation` spricht sie in der naechsten Begegnung etwas aus der
  vorigen aus.

### Was sie NICHT anfasst

Den Sprecher. Die Klammer ist ein Ausloeser-Begriff; Prioritaeten, Abklingzeiten und
Fremdstimmen-Erkennung bleiben, wo sie sind.

## 6. Mimik - erst ein Bark, dann breit

    AnimFeature_FacialReaction { category, idle }

Das Spiel nutzt fuer replizierte Ausdruecke `ApplyFeatureToReplicate`, NCA nur
`ApplyFeature`. Nach unserer Woche mit der Replikation ist das der erste Test, an **einem**
Bark, mit einem deutlich sichtbaren Ausdruck (`category=3, idle=8`, Ueberraschung). Erst
wenn der Weg steht, die Zuordnung ausrollen.

Vanilla-Tabelle (aus `reactionComponent.script`), die das Spiel selbst nur **auswuerfelt**:

| | category | idle |
|---|---|---|
| Aggressive | 3 | 1 |
| Curiosity | 1 | 3 |
| Disgust | 3 | 7 |
| Fear | 3 | 10 |
| Funny / Joy | 3 | 5 |
| Sad | 3 | 3 |
| Shock / Surprise | 3 | 8 |
| Standard | 2 | 2 |

Zuruecksetzen: leeres Feature. Vanilla-Abklingzeit 2.0 s.

**Trennung beachten:** die 181 Quest-Zeilen tragen ihre Mimik bereits in der `.anims` - 344
Joints, die ganze Darbietung. Nicht blind ueberschreiben. Die **63 Barks** ohne eigene
Gesichtsanimation sind die Zielgruppe. Der langfristig interessanteste Einsatz ist die Mimik
**zwischen** den Zeilen.

## 7. Bruecke fuer Momente

Zuletzt, weil als einziges ein zusaetzlicher Redscript-Bau noetig ist. Die Bruecke ruft
**keine** Lua-Funktionen und kein Audio direkt auf, sondern reicht ein typisiertes Protokoll
durch:

    CompanionEvent { type, timestamp, companionId, source, severity, context }

    TakeDamage(Judy, severity=light)
    DealDamage(Judy, severity=heavy)
    QuestComplete(id)
    VehicleEntered
    ConversationFinished

Die Lua-Seite entscheidet ueber Pool, Prioritaet und Abklingzeit. So bleibt die Bruecke
stabil, waehrend sich der Inhalt aendert.

Damit auch die Sorge-Aufteilung: was Judy **zu V** sagt, haengt an Vs Leben; was sie ueber
sich selbst sagt, an ihrem eigenen Schaden. Dazu passend die Lage `Wounded` - faellt ihr
Leben, bewegt sie sich verletzt, statt es nur zu sagen.

---

## Reihenfolge

    1. Blickkontakt zentral im Sprecher                      ERLEDIGT
    2. NCA-Kontext fuer Fahrzeug, Menue, Interaktion, Ort     ERLEDIGT
    3. Wohnungsmodus und Pools                               ERLEDIGT
    4. Besitzmatrix der Barks dokumentieren                  ERLEDIGT
    5. Begegnungs-Klammer bauen                              <- als naechstes
    6. Mimik an einem Bark testen
    7. Schadens-Bruecke ergaenzen
    8. danach erst weitere Flirt-, Smalltalk- und Sonderpools

Was die ersten vier ergeben haben, steht in `NCA_VERGLEICH.md`:

* **1** Blick laeuft, wirkt aber nur, wo ihr Koerper nicht ohnehin zu V zeigt - die Drehung
  macht das meiste davon schon. Bleibt Unterbau fuer die Mimik.
* **2** Von fuenf Feldern sind zwei unbrauchbar: `isInMenu` (fuenf Listener auf einem Bool)
  und `isInCombat` (341 Abweichungen, bleibt haengen). Beide behalten wir selbst.
* **3** Eigene Wohnungsleiter ohne Ungeduld, plus Tageszeit als neue Dimension.
* **4** Die native Ebene deckt den Kampf dicht ab und schweigt ausserhalb - das setzt die
  Grenze fuer Schritt 5.

Vor Schritt 3 kommt eine einheitliche **Momentaufnahme** des Kontexts - klein, keine
Architektur, aber sonst liest jedes neue Modul die NCA-Felder leicht unterschiedlich:

    combat  vehicle  menu  interaction  location  crouched  encounter
