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

## Technical notes

The extractor reads the RDAR archive format directly, resolves paths by FNV-1a64 hash,
and decompresses Kraken blocks through the game's own `oo2ext_7_win64.dll`.

CR2W strings are varint length-prefixed: bit 7 marks a string, bit 6 marks a continuation
byte, the low 6 bits are the length. Reading only a single length byte silently truncates
every line longer than 63 characters and corrupts multi-byte characters at the cut — the
first pass here produced exactly that before it was fixed.
