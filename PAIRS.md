# Wortwechsel - Judy und V

Beide Seiten sind ueber denselben Quest-Voiceset-Knoten **sofort spielbar**: Judy
ueber ihren Tag `NCA_Companion`, V ueber `isPlayer` mit `#player`. Ohne Cooldown,
ohne Audioware, ohne Fake-Lipsync - und Vs Mundbewegung sieht ohnehin niemand, weil
sie Player-POV ist.

Alle Dauern sind **im Spiel gemessen** (Judy 55 Zeilen, V 160), nicht geschaetzt.

Die Zuordnung ist Handarbeit. Automatisch geht sie nicht: sortiert man eine Szene
nach stringId, liegen die Zeilen nach Aufnahme-Charge beieinander, nicht nach
Dialogfolge.

## Gespraech unterbrochen  <sub>4.7s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `interrupt_var_6` | 2.12 | Moment ... Bin gleich wieder da. |
| JUDY | `interrupt_var_1` | 2.54 | Okay, wir setzen das später fort. |

## Gespraech unterbrochen, kurz  <sub>3.4s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `interrupt_var_2` | 1.56 | Wir reden später. |
| JUDY | `interrupt` | 1.85 | Hab ich dich gelangweilt? |

## Zurueck im Gespraech  <sub>3.4s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `return_var_2` | 1.97 | Also, wo waren wir? |
| JUDY | `return_answer` | 1.40 | Du bist zurück. |

## Zurueck im Gespraech, laenger  <sub>4.4s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `return_var_4` | 2.41 | Okay, wieder da. Schieß los. |
| JUDY | `return_answer_var_1` | 2.00 | Worüber hatten wir geredet? |

## Gegner gesichtet  <sub>4.1s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `enemy_warning_var_1` | 1.41 | Da kommen sie! |
| V | `reaction_hostiles_var_2` | 2.68 | Oh-o. Das wird ein Spaß. |

## Warnung im Kampf  <sub>3.8s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `combat_ally_warning_var_3` | 1.70 | Hey! Achtung! |
| JUDY | `battlecry_morale_var_3` | 2.10 | Jetzt mach ich ernst! |

## In Deckung  <sub>3.4s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `combat_ally_cover` | 1.51 | In Deckung! |
| JUDY | `danger_var_1` | 1.88 | Oh, Scheiße! |

## Granate  <sub>4.2s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `grenade_enemy_var_3` | 2.23 | In Deckung! Granate! |
| V | `reaction_surprise_var_3` | 1.95 | Oh, Scheiße ... |

## Nachfrage im Kampf  <sub>2.7s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `combat_ally_check` | 1.34 | Alles okay? |
| JUDY | `danger_var_3` | 1.38 | Bin bei dir. |

## Judy sorgt sich um V  <sub>4.8s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `player_fallback_var_3` | 2.76 | Alles okay? Schnauf mal kurz durch. |
| V | `scene_thanks_var_2` | 2.04 | Weiß ich zu schätzen. Danke. |

## Kampf vorbei  <sub>4.7s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `combat_ended_var_1` | 2.84 | Oh, das war’s. Wir haben’s geschafft. |
| V | `reaction_happy_var_2` | 1.82 | Das wird ein guter Tag. |

## Leise vorgehen  <sub>3.6s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `combat_ally_stealth` | 2.32 | Man darf uns nicht hören, klar? |
| JUDY | `stealth_warning_bark_var_1` | 1.25 | Sei still! |

## Entdeckungsgefahr  <sub>5.5s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `detection_warning_var_1` | 2.86 | Verschwinde da, sonst sehen sie uns! |
| V | `combat_ally_stealth_var_1` | 2.60 | Pssst. Langsam. |

## Stealth wiederhergestellt  <sub>4.2s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `stealth_restored_var_1` | 2.25 | Perfekt, die sehen uns nicht mehr. |
| V | `reaction_happy_var_3` | 1.90 | Man kann nicht immer Pech haben. |

## Dank nach Hilfe  <sub>3.4s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `scene_thanks_var_2` | 2.04 | Weiß ich zu schätzen. Danke. |
| JUDY | `return_answer` | 1.40 | Du bist zurück. |

## Begleitung endet  <sub>5.8s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `follower_end_var_2` | 3.30 | Das wär erledigt. Mach besser ’nen Abgang. |
| JUDY | `interrupt_var_1` | 2.54 | Okay, wir setzen das später fort. |

## Anrempeln  <sub>3.3s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `bump_var_1` | 1.71 | Hey, pass auf ... |
| V | `reaction_surprise_var_2` | 1.62 | Was zum ... |

## Spieler bleibt zurueck  <sub>4.1s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `follow_me_1` | 2.70 | Was ist los? Hör auf zu trödeln. |
| V | `interrupt_var_4` | 1.36 | Ich muss weiter. |

## Etwas Interessantes entdeckt  <sub>4.2s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| V | `reaction_inspect_var_1` | 2.41 | Oh. Interessant. |
| JUDY | `urge_var_1` | 1.78 | Was ist mit dir los? |

## Fluchen im Kampf  <sub>5.5s</sub>

| Wer | Voiceset | s | Zeile |
|---|---|---|---|
| JUDY | `battlecry_curse_var_3` | 2.89 | Hey, V! Mach was, verdammte Scheiße! |
| V | `battlecry_curse_var_4` | 2.62 | Du willst es hart? Kannst du haben! |

