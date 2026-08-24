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

## Result: the generic VO surface, fully mapped

All 44 event names attested in vanilla scripts were played on Judy in-game and listened to
across three rounds. A missing VO fails silently, so this could only be settled by ear;
the log recorded what was attempted, the listener recorded what sounded.

**11 of 44 work.** Every one of them carries multiple varied German lines.

| Event | German line heard | Natural trigger |
|---|---|---|
| `greeting` | "Hey V" / "Oh hey" | catching up, arrival |
| `stealth_restored` | "Die haben wir abgeschüttelt" / "Perfekt, die sehen uns nicht mehr" | detection broken |
| `stealth_ended` | "Da kommen sie" / "Sie sind hier, bleib wachsam" / "Achtung!" | spotted |
| `combat_ended` | "Oh das wars, wir habens geschafft" / "Sieh uns an. Nicht tot zu kriegen." | fight over |
| `coop_irritation` | "Aaah!" | annoyed |
| `coop_reports_kill` | "Echt jetzt!?" | she got a kill |
| `sniper_warning` | "Wo haben die nur diese Ausrüstung her?" / "Ordentlich ausgestattet die Typen." | well-equipped enemy spotted |
| `attack_fragile_player_order` | "Hey V! Mach was, verdammte Scheiße!" | urging V to act |
| `battlecry_curse` | "Fuuuuck!" | combat |
| `bump` | "Was zur Hölle?" | **player walks into her** |
| `combat_target_hit` | "Na, wie schmeckt dir das?" | she hit an enemy |

**Silent (33):** `danger`, `stlh_curious_grunt`, `stlh_call`, `stlh_death`, `enemy_warning`,
`start_combat`, `start_dead`, `crowd_combat`, `shove`, `fear_beg`, `fear_run`,
`hit_reaction_heavy`, `hit_reaction_light`, `hit_grapple`, `vo_any_damage_hit`,
`grenade_throw`, `heavy_reloading`, `hmg_charge`, `pedestrian_hit`, `vehicle_bump`,
`octant_warning`, and every `*_warning` except sniper, plus the entire `cpo_*` family.

The pattern is coherent: she answers **companion and stealth** events, and stays silent on
enemy-NPC combat chatter. `cpo_*` looked promising after `coop_*` paid off, but is empty.

### How the mapping was derived, and its one weakness

Sounds were matched to events by two independent signals: semantic fit of the German line
to the event name, and position within the logged cycle. Both agree.

The weak point is per-index attribution rather than the working set. Individual variants
are sometimes silent — one round-1 group produced two lines where three were expected — so
a given slot can appear empty on one pass. The **set** of working events is solid; if a
line turns out to sit on a neighbouring event, it will be obvious the first time it fires
in the wrong context, and it costs nothing to move.

Also observed: "Sieh uns an, nicht tot zu kriegen" surfaced under both `stealth_restored`
and `combat_ended`, so events appear to share a line pool.

### What this unlocks

Seven of the eleven map directly onto triggers CompanionLeash already computes:

    greeting          -> arrival, after a catch-up
    bump              -> the Crowding cancel we already detect
    stealth_ended     -> PlayerStateMachine detection change
    stealth_restored  -> ditto, the other direction
    combat_ended      -> EventBus.OnCombatEnd
    coop_reports_kill -> EventBus.OnCompanionDealDamage
    sniper_warning    -> threat spotted

No new detection work is needed for those — the events already exist in the policy or in
NCA's EventBus. What remains is a cooldown table so lines cannot chain or repeat.

## Technical notes

The extractor reads the RDAR archive format directly, resolves paths by FNV-1a64 hash,
and decompresses Kraken blocks through the game's own `oo2ext_7_win64.dll`.

CR2W strings are varint length-prefixed: bit 7 marks a string, bit 6 marks a continuation
byte, the low 6 bits are the length. Reading only a single length byte silently truncates
every line longer than 63 characters and corrupts multi-byte characters at the cut — the
first pass here produced exactly that before it was fixed.
