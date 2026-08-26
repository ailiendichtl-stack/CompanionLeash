# Wir und Night City Allies - Bestandsaufnahme

Wir bauen auf NCA auf, patchen es an einer Stelle und teilen uns seit dem Crouch einen
Regler mit ihm. Diese Aufstellung sagt, wer was macht, wo wir uns in die Quere kommen und
was auf der anderen Seite liegt, das wir bisher selbst nachbauen.

Stand: 2026-08-26.

## Umfang

| | NCA | wir |
|---|---|---|
| Code | 56 `.reds`, 10.322 Zeilen | 2.959 Zeilen Lua, 746 Zeilen reds |
| Eingriffe ins Spiel | ~30 `@wrapMethod` / `@addMethod` | 1 gepatchte Verhaltensdatei, 1 Tweak-Datei |
| Ereignisse | 36 im EventBus | - (wir fragen ab) |
| Inhalt | - | 244 Zeilen mit Lipsync, 20 Situationen |

NCA ist ein Begleiter-Grundgeruest. Wir sind die Stimme und die Feinabstimmung darauf.

## Wer macht was

| Gebiet | NCA | wir |
|---|---|---|
| Spawnen, Despawnen, Squad | ja | - |
| Folgen (Kommando, Rolle) | `FollowPlayerBehavior` | wir **patchen** es: Leine, Abstaende, Drehen |
| Fahrzeug, Passagier, Aufzug | ja | nur Zeilen dazu |
| Orte, Distrikte | 9 Orte, darunter alle 5 V-Wohnungen | - |
| Telefon, Nachrichten, Anheuern | eigenes UI | - |
| Beziehung | eigene `love`/`friendship`-Progression | wir lesen stattdessen die Quest-Fakten |
| Exp, Level, Schadensverfolgung | ja | - |
| Posen, Routinen | Workspots | - |
| **Lage (`HighLevelState`)** | **Combat / Relaxed** | **Stealth / Relaxed** |
| Stimme | `Talk()` -> `PlayVoiceOver`, 2 Aufrufe | 244 Zeilen, Sprecher mit Prioritaeten |
| Lipsync | - | selbst gebaut, 181 Quest-Zeilen |
| Gesichtsausdruck | `AnimFeature_FacialReaction` | - |
| Blick auf sie | Nameplate-Hook -> Widget | Abfrage `GetLookAtObject` -> Zeilen |
| Haltung, Hocken | tot (s.u.) | verdrahtet |

## Vier Beruehrungspunkte

**1. Die Lage - ein Regler, zwei Schreiber.** NCA setzt `Combat` bei Kampfbeginn und
`Relaxed` bei Kampfende (`CombatBehavior`), wir `Stealth` beim Hocken und `Relaxed` beim
Aufstehen. Entschaerft: wir lesen dieselbe Grenze wie NCA (`PlayerStateMachine.Combat`, das
Signal hinter seinem `OnCombatStateChanged`) und geben im Kampf ab. Beim Kampfende setzt NCA
`Relaxed`; hockt V noch, greift unser naechster Takt nach 0.4 s. **Zu beobachten:** die
Reihenfolge der beiden Schreiber am Kampfende.

`SetStealthState()` und `SetAlertedState()` gibt es in `NpcHandle.reds` bereits - **beide
werden nirgends aufgerufen**. Die Klinke war eingebaut und nicht angeschlossen. Deshalb
hockte sie vorher nie, und deshalb ist unser Crouch kein zweites System, sondern das
fehlende Kabel.

**2. Begruessung.** `CatchUpToPlayerBehavior` ruft `Talk("greeting")`, wenn sie aufschliesst
- genau unser `wiedersehen`. Unser Sprecher erkennt ihre Stimme als fremd und tritt zurueck,
also gibt es keine Ueberlappung. Der Moment gehoert damit aber NCA, nicht uns. **Zu
entscheiden.**

**3. Kampf-Bark.** `CombatBehavior.OnAttach` ruft `Talk("enemy_warning")` im selben
Augenblick, in dem unsere `kampf`-Situation anfragt. Im Log steht beides.

**4. Ein Lagewechsel loest Vanilla-Barks aus.** Gemessen an unseren eigenen Testknoepfen:

    04:16:32  Lage Alerted gesetzt
    04:16:33  Judy: "Oh, Scheisse!"
    04:16:53  Lage Alerted gesetzt
    04:16:53  Judy: "Bin bei dir."

Die auskommentierten Zeilen ueber `Talk()` in `NpcHandle.reds` nennen den Mechanismus beim
Namen: `danger`, `stealth_restored`, `enemy_warning` auf `OnHighLevelStateEnter`. Bei
`Stealth` ist in unseren Daten kein Bark aufgetaucht - was unserem Crouch entgegenkommt,
aber durch Bark-Abklingzeiten verdeckt sein koennte. **Ungeprueft.**

**5. `isInMenu` ist unbrauchbar - gemessen, nicht vermutet.** Der Vergleich aus Phase 2 hat
es am ersten Tag gefunden: `wir false, NCA true`, und der Wert blieb haengen. Grund:
**fuenf** Blackboard-Listener schreiben in denselben einen Bool -

    UI_System.IsInMenu
    UI_ComDevice.ContactsActive
    UI_QuickSlotsData.UIRadialContextRequest
    UI_Scanner.UIVisible
    UI_QuickSlotsData.quickhackPanelOpen

- alle ueber `UpdateContext(value)`, ohne Zaehlung. Scanner auf setzt `true`, Menue zu setzt
`false`, und bei Ueberschneidung gewinnt das letzte Ereignis. **Unsere eigene Menuepruefung
bleibt.** Genau dafuer war der Vergleichsschritt da.

**6. `isInCombat` ist ebenfalls unbrauchbar.** 341 Abweichungen in einer Sitzung, immer in
dieselbe Richtung: **wir true, NCA false**. Sein Wert bleibt stehen, waehrend das Gefecht
laeuft. Damit sind zwei von drei vergleichbaren Kontextfeldern kaputt, und beide auf dieselbe
Weise - der Haken feuert nicht zuverlaessig, und niemand prueft nach.

Unsere Wahl war trotzdem richtig: wir lesen `PlayerStateMachine.Combat` **direkt**, also
dieselbe Quelle, aus der NCAs `OnCombatStateChanged` gespeist wird - nur ohne die Kopie
dazwischen, die veralten kann.

**Bilanz Phase 2:** von den fuenf Feldern, die wir uebernehmen wollten, bleiben `location`
und `isInInteraction` (haben wir nicht selbst) und `isInCar` (stimmt ueberein). `isInMenu`
und `isInCombat` behalten wir selbst. Der Vergleichsschritt hat sich damit zweimal bezahlt
gemacht.

## Was drueben liegt und wir selbst nachbauen

Der wichtigste Befund der Aufstellung: wir fragen jeden Takt Dinge ab, die NCA als Ereignis
veroeffentlicht.

| unser Ausloeser | heute | NCA-Ereignis |
|---|---|---|
| `sorge` | Gesundheit jeden Takt abfragen | `OnCompanionTakeDamage` |
| `stolz` | - | `OnCompanionDealDamage` |
| **36 Wohnungszeilen** | **zurueckgestellt, "braucht ein Ortsmodul"** | `OnEnterApartment` / `OnExitApartment` |
| `fahrzeug` | Fahrzeug abfragen | `OnEnterVehicle` / `OnExitVehicle` |
| Menue-Stopp | selbst gebaut | `OnEnterMenu` / `OnExitMenu` |
| Tageszeit | - | `OnHourPassed`, `OnDayPassed`, `OnTimeSkip` |
| Ortswechsel | - | `OnChangeDistrict`, `OnEnterLocation` |
| Quests | - | `OnQuestStart`, `OnQuestComplete` |

Die Wohnungszeilen stechen heraus. Wir haben sie zurueckgestellt, weil uns ein Ortsmodul
fehlte - NCA hat neun Orte registriert, darunter alle fuenf V-Wohnungen, und meldet Eintritt
und Austritt.

**Haken:** der EventBus ist ein redscript-System; aus CET-Lua kann man sich nicht
einhaengen. Es braucht eine kleine Bruecke auf unserer reds-Seite, die die Ereignisse
weiterreicht. Die Seite haben wir bereits (`src/*.reds`).

Drei weitere Sachen, die drueben liegen:

* **`AnimFeature_FacialReaction`** (`category`, `idle`) - ein allgemeines Ausdruckssystem.
  Wir hatten festgestellt, dass es kein Szenen-Ereignis fuer Mimik gibt und die `.anims` die
  ganze Darbietung tragen. Das hier ist eine **andere Ebene**, die wir nie probiert haben -
  moeglicherweise Ausdruck fuer Zeilen ohne eigene Animation.
* **`ActivateReactionLookAt(player, ...)`** - sie dreht sich beim Sprechen zu V. Ein Aufruf,
  reine Politur, haben wir nicht.
* **Der Nameplate-Hook als Blicksignal** - ereignisgetrieben und genau, wo wir jeden Takt
  `GetLookAtObject` abfragen.

## Drei Stellen in NCA, die fertig daliegen und nicht angeschlossen sind

Ein Muster, kein Zufall - und fuer uns die ergiebigste Ecke des ganzen Mods.

| | Zustand | fuer uns |
|---|---|---|
| `SetStealthState()` | gebaut, **nie aufgerufen** | war unser Crouch |
| `OnEnterApartment` / `OnExitApartment` | leerer Rumpf, `isApartment` wird verworfen | Phase 3 nimmt stattdessen `Context().location` |
| `LiftDevice`-Wraps in `NpcHooks.reds` | **auskommentiert**, samt Erklaerung | Aufzuege, s.u. |

### Aufzuege

NCAs eigener Kommentar nennt die Ursache:

> Lifts only ever enable the PLAYER half of their off-mesh link
> (`LiftDevice.EnableOffMeshConnections`), while doors enable both halves.

Ohne die NPC-Haelfte gibt es fuer die Wegfindung keine Kante in die Kabine. Sie bleibt
davor stehen, und zwar ohne Fehlermeldung - der Weg hat fuer sie nie existiert. Damit ist
alles ausser dem Erdgeschoss unerreichbar; ins Apartment kam man zuletzt nur ueber
Schnellreise.

Der Fix liegt bei uns in `src/CompanionLeashLift.reds`, bewusst als eigene Datei: **warum
NCA ihn auskommentiert hat, wissen wir nicht.** Loeschen der einen Datei nimmt ihn zurueck.

## Zu Boden gehen: laeuft nativ, wir haben es zurueckgebaut

Sie geht im Gefecht zu Boden und steht **von selbst** wieder auf, manchmal noch mitten im
Kampf. Das ist `DefeatedWithRecover`, ein Vanilla-Zustand mit eingebauter Erholung - kein
Fehler und nichts, was jemand reparieren muesste.

Der lange Timer, den ich zuerst dafuer gehalten habe, gehoert einem anderen Fall: dem echten
Tod. Dort entfernt NCA ihren Griff, **despawnt sie** und startet 150 Spielminuten bis zum
`revive_after_death`, das sie lediglich wieder rufbar macht. Dort waere ohnehin niemand mehr
da, dem man aufhelfen koennte.

Was wir gebaut und wieder entfernt haben:

| | Warum weg |
|---|---|
| Eintrag "Aufhelfen" in NCAs `Interactions/` | lag in fremdem Ordner, nie bestaetigt gesehen, und ueberfluessig |
| Umhuellung von `App:OnInteract` | hat NCAs Menue zerlegt - dauerhaft offen, nicht bedienbar |

**Geblieben ist nur Eigenes:** ein Knopf im eigenen Panel, der Gesundheit setzt und
`Defeated`, `DefeatedWithRecover` und `Wounded` abnimmt, plus ein Protokolleintrag, wenn sie
faellt und wenn sie wieder steht. Beides fasst NCA nicht an.

**Gelernt:** NCAs Menue ist ueber mehrere Stellen verzahnt - `ui:Close()` kommt aus seiner
eigenen Beobachtung und laeuft gegen den Zustand, den `OnInteract` gesetzt hat. Eine dieser
Methoden zu ersetzen bringt die beiden Seiten auseinander. Der `Interactions`-Ordner ist die
vorgesehene Erweiterung; alles darueber hinaus ist Eingriff.

## Was NCA nicht tut: heilen

Es gibt **keine** Heilung fuer Begleiter - nur eine Lebensanzeige
(`UI/HealthBarVisibility.reds`). Ihre Gesundheit kommt nur durch einen Respawn zurueck,
etwa nach Schnellreise.

Das trifft mit dem Vanilla-Wundsystem zusammen. Die gebueckte, blutende Haltung mit
haengendem Arm ist **kein Lagezustand**, sondern ein Gliedmassenschaden aus
`hitReactionComponent`: pro Trefferzone wird Schaden gegen eine Schwelle gezaehlt
(`WoundLArmDamageThreshold` und Geschwister), und `ProcessWoundsAndDismemberment` setzt den
Zustand beim Treffer. Einen Rueckweg hat er nicht.

Folgen, die man kennen muss:

* Crouchen aendert daran nichts, und das ist richtig so - es ist eine andere Ebene.
* Wir ueberschreiben dabei nichts. Unsere Lage und ihre Wunde sind verschiedene Dinge.
* Ohne Heilung sammeln Begleiter Wunden **dauerhaft** an, bis sie neu gespawnt werden.

## Was wir haben und NCA nicht

244 kuratierte Zeilen mit gebautem Lipsync. Einen Sprecher mit Prioritaeten, Abklingzeiten,
Warteschlange und Fremdstimmen-Erkennung. Die Leine - Abstaende, Gangart, Drehen. Und den
Crouch.

NCAs ganze Sprachausgabe sind zwei Aufrufe.

## Wie ich die Arbeitsteilung sehe

NCA ist das Fundament: Koerper, Ort, Kontext, Squad. Wir sind Stimme und Feinabstimmung.
Wo NCA ein Ereignis anbietet, sollten wir aufhoeren abzufragen - das ist genauer, billiger
und haelt uns an derselben Grenze wie der Mod, auf dem wir sitzen. Der Kampf-Riegel hat
gerade vorgefuehrt, was passiert, wenn beide Seiten dieselbe Sache verschieden messen.
