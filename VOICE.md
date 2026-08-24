# Voice inventory

Extracted directly from the shipped localisation archives with
[tools/voice_inventory.py](tools/voice_inventory.py). **No speech-to-text needed** — the
game ships subtitle text as data.

    python tools/voice_inventory.py                       # Judy questlines, German
    python tools/voice_inventory.py --lang en             # same, English
    python tools/voice_inventory.py --filter panam,sq027  # anything else

Output goes to `data/voicelines_<lang>.json`.

---

## What is in there

| | |
|---|---|
| Subtitle files referenced by the German index | **3,303** |
| Matched for Judy's questlines | **161** |
| Distinct German lines extracted | **8,154** |
| Files named after Judy specifically | 17 (**1,039** lines) |

Richest single files:

```
quest\judy\judy_default.json          136   ambient / conversational pool
quest\sq029\sq029_04a_dinner.json     255   Both Sides, Now
quest\sq026\sq026_08_plan.json        246   Pyramid Song lead-in
quest\sq030\sq030_09_pier.json        177   Pisces - the pier scene
quest\sq030\sq030_06_lake_exploration.json 164
quest\q105\q105_11_judys_evelyn.json  165
quest\vset\vset_judy.json              55   V-set / relationship states
```

`judy_default.json` is the interesting one for companion work: conversational lines that
are not welded to a single scene beat. Sample (German, verbatim from the archive):

```
Hey, V.
Was gibt's Neues?
Ich würde gerne mehr Zeit mit dir verbringen.
Lass uns noch ein bisschen reden.
Hab's mir anders überlegt. Ich will doch tauchen gehen.
Cool. Heute Abend in der Hütte am See. Lass mich nicht warten.
```

---

## The distinction that decides what is buildable

Two different things are easy to conflate:

| | Subtitle text | VO events |
|---|---|---|
| What it is | recorded dialogue, ~8k lines for Judy's questlines | names like `greeting`, `stlh_curious_grunt` |
| Where it lives | `lang_de_text.archive`, extracted above | audio metadata / character voice bank |
| Callable from script | **no** — belongs to quest scenes | **yes** — `NpcHandle.Talk(vo)` / `PlayVoiceOver` |
| Size of surface | very large | small, and per-character coverage **unverified** |

This inventory covers the first. It tells us precisely what Judy *can* say and in which
context it was recorded — which is what makes it possible to judge whether a line fits a
situation. It does **not** by itself make those lines playable on demand.

## Known limitations

- **No speaker tag.** Subtitle files contain every speaker in a scene. `femaleVariant` /
  `maleVariant` distinguishes *V's gender*, not who is talking. Separating Judy's lines
  from V's and others' needs either manual passes or the scene resources.
- **Scene-bound.** A line existing does not mean it can be triggered outside its quest.
- **VO event coverage is still open.** Whether Judy answers to generic events such as
  `greeting` is untested, and a missing VO fails silently rather than erroring. That is a
  listening test, not something the data can settle.

## Next step for voice

The cheap, decisive experiment: call `Talk(n"greeting")` on Judy in-game and listen. It
costs one launch and settles whether the whole generic-VO approach is viable before any
design work rests on it.

If generic events turn out to be empty for her, the fallback is scene-bound: trigger
existing quest dialogue through the quest system rather than the VO system. That is
considerably more involved, which is exactly why the spike comes first.


---

## Result: the generic VO surface

Mapped in two passes. A timed redscript sweep played every name on a schedule; a CET panel
(`cet/CompanionLeashVO`) then allowed clicking each event by hand.

**The timed sweep was substantially wrong.** It reported 11 working and 33 silent. Manual
testing showed many "silent" events do work — they just need several attempts, because
individual variants are frequently empty. A single scheduled attempt per event produced
false negatives at scale. The manual panel is the authoritative source below.

### Distinct, contextual lines — the valuable set

| Event | German line | Natural trigger |
|---|---|---|
| `greeting` | "Hey V" / "Oh hey" | catching up, arrival |
| `stealth_restored` | "Die haben wir abgeschüttelt" / "Perfekt, die sehen uns nicht mehr" | detection broken |
| `stealth_ended` | "Da kommen sie" / "Sie sind hier, bleib wachsam" / "Achtung!" | spotted |
| `combat_ended` | "Oh das wars, wir habens geschafft" / "Sieh uns an. Nicht tot zu kriegen." | fight over |
| `elite_warning` | "Wo haben die nur diese Ausrüstung her?" / "Ordentlich ausgestattet die Typen" | tough enemy — **reliable** |
| `camera_warning` | several distinct lines | camera spotted |
| `bump` | "Was zur Hölle?" | **player walks into her** |
| `combat_target_hit` | "Na, wie schmeckt dir das?" | she hit an enemy |
| `attack_fragile_player_order` | "Hey V! Mach was, verdammte Scheiße!" | urging V to act |
| `battlecry_curse` | "Fuuuuck!" | combat |
| `coop_reports_kill` | "Echt jetzt!?" | she got a kill |
| `coop_irritation` | "Aaah!" | annoyed |
| `start_combat` | works, most attempts | fight starts |
| `enemy_warning` | works | enemy spotted |
| `hit_reaction_light` | works | taking a light hit |
| `grenade_throw` | works | grenade |
| `vehicle_bump` | the short "…?" | vehicle contact |

### Generic pool only — low value

`octant_warning`, `turret_warning`, `drones_warning`, `netrunner_warning`, `mech_warning`,
`heavy_warning` — these fire sometimes, but only ever produce the generic "Aaah!" and
"Echt jetzt!?" reactions. No distinct lines of their own. Usable as filler, not worth
wiring to a specific situation when `elite_warning` or `camera_warning` say something real.

### Confirmed silent

Clicked by hand, repeatedly, and never produced audio:

`danger`, `stlh_curious_grunt`, `stlh_call`, `stlh_death`, `start_dead`, `crowd_combat`,
`shove`, `fear_beg`, `fear_run`, `hit_reaction_heavy`, `hit_grapple`, `vo_any_damage_hit`,
`heavy_reloading`, `hmg_charge`, `pedestrian_hit`, `cpo_armor_broken`, `cpo_got_data`,
`cpo_nearly_dead`, `following`, `waiting`.

The `cpo_*` family is genuinely empty for her, despite `coop_*` paying off — the two
prefixes are not the halves of one set.

### Final tally

    17  distinct, usable lines
     6  generic pool only ("Aaah!" / "Echt jetzt!?")
    20  silent
     1  open: sniper_warning
    --
    44  names in the vanilla catalogue

`sniper_warning` is the one loose end. The timed sweep attributed the gear lines to it by
cycle position, but manual testing showed `elite_warning` carries those reliably. Since
`sniper_warning` sits in the panel's *confirmed* section it was never re-clicked, so it is
unknown whether it has lines of its own or the original attribution was simply wrong.
One click settles it.

### Structure worth knowing

**Events share line pools.** "Sieh uns an, nicht tot zu kriegen" surfaced under both
`stealth_restored` and `combat_ended`. The gear lines appear under both `sniper_warning`
(timed sweep, position-derived) and `elite_warning` (manual, reliable) — the manual result
is the one to trust. Half a dozen warning events resolve to the same two generic screams.

**Empty variants are normal.** Even confirmed events stay silent on some presses. Anything
built on these must tolerate a call producing no audio, and must not treat silence as an
error or retry into a stutter.

**Design consequence:** prefer events with distinct lines, and treat the generic-pool
events as interchangeable filler rather than meaningful signals.

---

## Beyond events: a custom line archive

The 17 working events are a fixed, small set chosen by CDPR. The ~8,000 recorded lines are
not reachable through them. A separate route exists, and every piece of it is verified:

### The pipeline

    1. TEXT      tools/voice_inventory.py            DONE
                 8,367 German lines, each with a stable stringId

    2. AUDIO     WolvenKit                            external tool
                 voice lives in lang_de_voice.archive: 90,253 files, 4.7 GB,
                 stored as opus packs. Paths are FNV-1a64 hashes, so locating a
                 specific line needs WolvenKit's hash database - guessing path
                 patterns does not work and was tried.

    3. PLAYBACK  Audioware                            already installed, API verified
                 declare wav files in r6/audioware/<bank>/<bank>.yml, then:

                 GameInstance.GetAudioSystemExt(game)
                     .Play(n"lineName", judyEntityID, n"emitter", scnDialogLineType.Regular)

                 Play() takes an entityID and a scnDialogLineType, so the line is
                 positioned on her and carries subtitle support. PlayOnEmitter and
                 PlayOverThePhone exist too - the latter is interesting for holocalls.

    4. TRIGGER   CompanionLeash policy layer          existing

The "Go on a Date (Judy) - Language support Dialogues" mod already ships wav files through
Audioware this way, so the approach is proven in this exact install.

### What it costs, honestly

Step 2 is the real work and it is manual: identify the line, extract it, convert to wav,
name it, add it to a bank. That is per-line effort, not a batch job, because choosing
*which* lines are worth having is a judgement call - the inventory has 8,367 of them and
most are welded to a specific story moment.

Two limits worth knowing before committing to it:

- **No lip sync.** Audioware plays audio; it does not drive the facial rig. Standing next
  to her, a line without matching mouth movement is noticeable. The built-in VO events do
  not have this problem.
- **Context.** A line recorded for one scene often refers to that scene. The inventory
  makes this checkable in advance, which is exactly what it is for.

### Sensible split

Use the **17 events** for reactive, frequent behaviour: greeting, stealth, combat, bump.
They are free, lip-synced, and already contextual.

Use a **custom bank** for a small number of deliberately chosen lines where the event
system has nothing to offer. Quality over quantity - a handful of well-placed lines beats
a large library that fires at the wrong moment.

---

## The line archive

WolvenKit's archive listing revealed the voice file naming scheme, and it changes what is
possible:

    base\localization\de-deo\judy_q202_f_1787cc94372cd000.wem
                                  ^^^^ ^^^^ ^ ^^^^^^^^^^^^^^^^
                               speaker quest │ stringId in hex
                                          V's gender

The hex suffix **is** the subtitle `stringId`. That gives a direct join between text and
audio - and the speaker sits in the filename, which solves attribution that the subtitle
data alone cannot provide. Earlier notes in this file called speaker attribution
impossible from the data; that was wrong, it just required the audio side.

    tools/line_archive.py

    subtitle entries : 8,367
    voice files      : 62,196 with a resolvable id
    joined for Judy  : 1,473   (1,440 female-V variants)

Output is `data/line_archive_judy_de.json`, one row per line:

    id, speaker, gender, scene, text[], wem-path

Richest scenes: `q105_07_judy_braindance` (108), `judy_default` (94),
`sq030_06_lake_exploration` (90), `sq030_09_pier` (69), `sq026_02_holocall_judy` (62).

`judy_default` remains the most interesting for companion work - lines that are not welded
to a single story beat.

### What remains

Extraction and conversion: `.wem` out of the archive, then to a format Audioware accepts.
WolvenKit ships `opus-tools` and has `extract` and `wwise` commands, so the tooling is
present. The archive above tells us exactly which files to pull, which was the missing
piece.

---

## Face and lipsync — tested, not assumed

### VO events carry lipsync — confirmed

Verified in-game by playing an event and watching her mouth. This had been asserted in
earlier notes without ever being checked, which was careless: the whole "use events for
anything visible" recommendation rests on it. It holds.

### Workspot animations do not

Judy's `talk` variants (`synced__v_hug_judy__talk__01__judy` and friends) produce body
motion only — head shakes, gestures — and no mouth movement. The idea that the mouth
movement might be baked into the animation, making a scene unnecessary, does not hold.

Supporting evidence: the animation database has **no facial rig**. Every rig is a body rig
(`Woman Average`, `Player Woman`, …), and names containing "face" are gestures such as
`rub_face`. Facial animation is a separate track that workspots do not drive.

### Facial expression IS script-controllable

`AnimFeature_FacialReaction` takes two ints, and AMM has already mapped them - an earlier
note in RESEARCH.md called this an unexplored axis, which was simply wrong:

| Expression | category | idle | | Expression | category | idle |
|---|---|---|---|---|---|---|
| Neutral | 2 | 2 | | Anger | 3 | 1 |
| Joy | 3 | 5 | | Disgust | 3 | 7 |
| Smile | 3 | 6 | | Disappointed | 3 | 4 |
| Sad | 3 | 3 | | Interested | 1 | 3 |
| Surprise | 3 | 8 | | Disinterested | 1 | 6 |
| Aggressive | 3 | 2 | | Exertion | 1 | 1 |

**A facial feature latches.** Applying a second one on top of a live one does nothing —
the first expression sticks until reset. The working sequence, taken from AMM and matching
vanilla's own use of `ResetFacial(0.0)`:

    stim:ResetFacial(0)
    -- wait ~0.5s for the cooldown
    anim:ApplyFeature(CName.new("FacialReaction"), feature)

Without the reset and the delay, only the first expression after a load ever applies.

### Consequence for the design

Lipsync comes only from VO events (and scenes). Expression is ours to drive at any time.
So a custom Audioware line can still be given a fitting face — mouth shape will not match
the words, but a line delivered with the right expression reads far better than one
delivered by a frozen face.

## Technical notes

The extractor reads the RDAR archive format directly, resolves paths by FNV-1a64 hash,
and decompresses Kraken blocks through the game's own `oo2ext_7_win64.dll`.

CR2W strings are varint length-prefixed: bit 7 marks a string, bit 6 marks a continuation
byte, the low 6 bits are the length. Reading only a single length byte silently truncates
every line longer than 63 characters and corrupts multi-byte characters at the cut — the
first pass here produced exactly that before it was fixed.

## Lipsync ohne eigene Szene: der Stumm-Trick

Getestet und bestaetigt: **das Muten des Dialog-Busses stoppt das Lipsync nicht.** Der Mund
bewegt sich weiter. Damit laesst sich ein stummes VO-Event als Mundanimation missbrauchen,
waehrend die eigentliche Zeile ueber den SFX-Bus laeuft - Audioware registriert eigene
Dateien unter `sfx:`, einem anderen Bus als `DialogueVolume`.

Zwei Probleme des ersten Ansatzes und der Trick, der beide zugleich loest:

| Problem | Ursache |
|---|---|
| Manchmal passiert gar nichts | Ein VO-Event zieht eine zufaellige Variante aus einem Pool; einige von Judys sind leer |
| Mundbewegung passt nicht zur Zeile | Der Mund bewegt sich so lange wie das *Event*, nicht wie unsere Zeile |

Weil das Event stumm ist, kostet mehrfaches Abfeuern nichts. Wir feuern deshalb im Intervall
nach, solange die Zeile laeuft: eine tote Variante faengt der naechste Schuss ab, und der
Mund bleibt bis zum Ende in Bewegung. Ueberlappung ist gratis, wenn sie niemand hoert.

### Zwei Einstellungen, beide `update_policy: immediately`

| Pfad | Var | Typ | Zweck |
|---|---|---|---|
| `/audio/volume` | `DialogueVolume` | int | auf 0 - macht das VO-Event stumm |
| `/accessibility/subtitles` | `Overheads` | bool | auf false - unterdrueckt den Text ueber dem Kopf |

`Overheads` betrifft ausschliesslich Bark-Untertitel ueber NPC-Koepfen. `Cinematic` ist eine
eigene Variable und bleibt unangetastet.

`DialogueVolume` ist laut Optionsnamen global. In der Praxis blieben andere NPCs waehrend
des Fensters hoerbar und nur Judy war stumm - im Spiel getestet. Warum, ist offen; moeglich,
dass Companion-VO und Crowd-Barks auf verschiedenen Bussen liegen. Die Annahme "alles wird
stumm" hat sich jedenfalls nicht bestaetigt.

Zugriff zur Laufzeit ueber `Game.GetSettingsSystem():GetVar(pfad, name)` und `:SetValue()` -
dasselbe Muster wie AMMs `External/GameSettings.lua`.

Beide Werte werden per Timer, beim Shutdown und per Knopf zurueckgesetzt, mit hartem Deckel
bei 20 s. Eine haengende Sitzung darf den Spieler nicht stumm zuruecklassen.

### Offen: die Aussetzer

Der Trick greift nicht zuverlaessig - mal bewegt sich der Mund, mal nicht. Nachfeuern im
Intervall half nicht spuerbar, was gegen die "leere Variante"-Erklaerung spricht: dann
haette der naechste Schuss sie abfangen muessen.

Zwei Mechanismen kommen infrage, mit **gegensaetzlichen** Konsequenzen:

| Mechanismus | Folge | Fix |
|---|---|---|
| Jeder neue Trigger bricht den laufenden ab | Nachfeuern macht es *schlimmer* | genau ein Schuss |
| Cooldown pro Event | dasselbe Event kurz hintereinander wird verworfen | nie zweimal dasselbe Event |

Beides ist als Modus im Panel umschaltbar (Einzelschuss / Rotation), inklusive Logzeile pro
Schuss. Ein Vergleich entscheidet, welcher Mechanismus wirkt - geraten wird nicht.

Die Rotation nutzt zwoelf bestaetigte Events. Judys gesamter Bark-Wortschatz sind 57 Dateien
mit 55 verschiedenen Zeilen im VoiceSet `judy_vs_vset_judy`.

### Der saubere Weg, falls der Trick nicht traegt

`LizziesBDs/Audio.reds` zeigt das kanonische Muster fuer eigene vertonte Zeilen: per
`CallbackSystem` auf `Resource/Loaded` haengen und

* `base/localization/volanguagedatamap.json` um eigene `voiceovermap.json`-Chunks je Sprache
  erweitern (stringId -> .wem),
* `base/sound/event/eventsmetadata.json` um eigene Eintraege erweitern
  (`audioAudioEventArray`, je Event `redId` als CName und `wwiseId`).

Normale Audio-Events sind damit deterministisch. Die Zufaelligkeit sitzt erst in der
VO-Schicht darueber, die ueber den `voiceTag` des Characters aufloest - `voiceTag` ist ein
TweakDB-Flat auf Character-Records.

Ob eine so registrierte Zeile Lipsync bekommt, ist ungetestet.
