# Voicesets erweitern - vollstaendige Bauanleitung

Wie sich beliebige vorhandene Sprachzeilen als spielbare Voiceset-Eintraege registrieren
lassen, **mit Lipsync**. Damit waeren Judys 1104 Quest-Zeilen erreichbar, nicht nur ihre
55 Barks - und der Stumm-Trick waere nur noch Reserve.

Das Verfahren ist nicht erdacht, sondern abgelesen: **V Voice Framework** macht genau das.
Sein Archiv enthaelt eine einzige Datei, `base/quest/primary_characters/vsets/vset_v.scene`,
mit **12807 eigenen Eintraegen** gegenueber 0 im Original (10251 KB gegen 283 KB).

## Werkzeug

WolvenKit kann die Szene verlustfrei hin- und zurueckwandeln:

```
WolvenKit.CLI convert serialize   vset_judy.scene  -o <ziel>   # -> .scene.json
WolvenKit.CLI convert deserialize vset_judy.scene.json         # -> .scene
```

## Aufbau einer Voiceset-Szene

Am Beispiel `vset_judy.scene`: 65 Einstiegspunkte, 55 Zeilen, 130 Graphknoten.

```
entryPoints            name "player_fallback_var_2"  ->  nodeId 132
sceneGraph.graph       65x scnStartNode        ein Einstieg je Name
                       10x scnRandomizerNode   waehlt bei Familien eine Variante
                       55x scnSectionNode      eine je Zeile
screenplayStore.lines  55x scnscreenplayDialogLine
```

### Die Kette fuer eine Zeile

```
entryPoint(name)  ->  scnStartNode  ->  scnSectionNode  ->  scnDialogLineEvent
                                                              screenplayLineId ->
                                                            scnscreenplayDialogLine
```

### Was die Zeile bindet

```json
{
  "$type": "scnscreenplayDialogLine",
  "itemId":     { "id": 1 },
  "locstringId": { "ruid": "1796592928298090500" },
  "femaleLipsyncAnimationName": { "$value": "f_18EEC7BFE12FC004" },
  "maleLipsyncAnimationName":   { "$value": "m_18EEC7BFE12FC004" },
  "speaker": { "id": 0 }, "addressee": { "id": 0 },
  "usage": { "playerGenderMask": { "mask": 3 } }
}
```

**Der entscheidende Zusammenhang, im Spiel geprueft:** die `ruid` ist dezimal genau der
Hex-Teil des Dateinamens, und die beiden Lipsync-Namen sind `f_<hex>` / `m_<hex>`.

```
1796592928298090500  ==  0x18eec7bfe12fc004  ==  judy_..._f_18eec7bfe12fc004.wem
```

Fuer alle 55 Zeilen des Voicesets stimmt das ausnahmslos. Und **beides haben wir fuer
Judys gesamten Bestand bereits** - `data/judy_ALL_de.json` fuehrt zu jeder der 1662 Dateien
die stringId und den Dateinamen.

### Was das Ereignis steuert

```json
{
  "$type": "scnDialogLineEvent",
  "duration": 3045,
  "screenplayLineId": { "id": 6657 },
  "visualStyle": "overHead",
  "voParams": { "voContext": "Vo_Context_Combat",
                "voExpression": "Vo_Expression_Spoken" }
}
```

`duration` steht in **Millisekunden** - also genau der Wert, den wir bei Judy im Spiel
gemessen haben. Fuer die Quest-Zeilen ist er unbekannt und muesste aus den Audiodateien
kommen; WolvenKit hat dafuer einen `wwise`-Befehl. Eine grobe Schaetzung waere riskant: zu
kurz schneidet ab, zu lang laesst eine Luecke.

## Vorgehen

Fuer jede zusaetzliche Zeile sind vier Eintraege noetig:

1. `scnscreenplayDialogLine` in `screenplayStore.lines`, mit freier `itemId`
2. `scnSectionNode` mit einem `scnDialogLineEvent`, das auf diese `itemId` zeigt
3. `scnStartNode`, der auf den Section-Node zeigt
4. `scnEntryPoint` mit dem gewaehlten Namen, der auf den Start-Node zeigt

Alle vier lassen sich maschinell aus dem vorhandenen Bestand erzeugen. Ein eigener Praefix
wie `cl_` haelt sie von den Vanilla-Namen getrennt.

## Warum maximal gross bauen

VVF filtert nicht: alle 12807 Eintraege sind drin. Das ist die richtige Reihenfolge, denn
ein Voiceset ist eine Nachschlagetabelle - ungenutzte Eintraege kosten zur Laufzeit nichts,
und **Kuratieren wird danach reine Datenarbeit** im Mod-Code, ohne die Szene neu zu bauen.
Wer vorher filtert, baut die Szene bei jeder Meinungsaenderung neu.

## Konflikte

VVF ersetzt `vset_v.scene`. Wir wuerden `vset_judy.scene` ersetzen - kein Konflikt. Wollten
wir **Vs** Voiceset erweitern, muessten wir uns mit VVF abstimmen oder auf dessen
`vfv_`-Eintraege aufsetzen, die ohnehin fast Vs gesamten Bestand abdecken.

## BESTAETIGT im Spiel

`cl_klon_danger` spielt "Ich bin froh, dass du da bist." - eine `mq055`-Quest-Zeile, die in
Judys Voiceset nie vorkam, ueber einen selbst gebauten Eintrag. Das Verfahren traegt.

### Die vollstaendige Rezeptur

Eine Zeile hinzufuegen heisst: einen vorhandenen Eintrag **tief kopieren** und nur das
Noetige ersetzen. Nicht von Hand nachbauen - das hat drei Anlaeufe gekostet.

**Vorlage waehlen.** Eine gewoehnliche Bark, die direkt vom Start-Knoten auf die Section
zeigt. Von Judys 65 Eintraegen sind 55 direkt, die 10 Familien-Basisnamen laufen ueber
einen `scnRandomizerNode`. `danger_var_1` ist eine gute Wahl; `player_fallback_var_2` ist
eine schlechte - der Name deutet auf einen Fallback-Pfad, und der Klon davon blieb
mehrdeutig.

**Kopieren:** Start-Knoten, Section-Knoten samt Ereignis, `voParams`, Sockets,
`actorBehaviors`, `sectionDuration` - und die zugehoerige `scnscreenplayDialogLine`.

**Ersetzen - und nur das:**

| Feld | Wert |
|---|---|
| `nodeId` von Start und Section | naechste freie Ids |
| `HandleId` beider Knoten und des Ereignisses | naechste freie |
| Ereignis-`id` | **Vielfaches von 4** |
| `itemId` der Zeile | **`(n << 8) \| 1`** |
| `screenplayLineId` im Ereignis | dieselbe `itemId` |
| `locstringId.ruid` | die stringId der Zielzeile |
| `femaleLipsyncAnimationName` / `male...` | `f_<hex>` / `m_<hex>` |
| Name im `scnEntryPoint` | frei, z.B. `cl_*` |

**Registrieren:** `entryPoints` **und** `sceneGraph.Data.startNodes` - beide parallel, gleiche
Reihenfolge. Dazu je ein `scnNodeSymbol` pro Knoten und ein `scnSceneEventSymbol` pro
Ereignis.

**Lipsync-Set referenzieren.** Ohne das spielt die Zeile, aber der Mund bewegt sich nicht -
im Spiel beobachtet. Die Animationen liegen sprachabhaengig im Sprach-Archiv, je Szene und
Figur:

```
base/localization/<lang>/lipsync/<szenenpfad>/<figur>.anims
```

Judys Voiceset referenziert nur sein eigenes Set mit den 55 Bark-Animationen. Fuer eine
Quest-Zeile muss das Set ihrer Herkunftsszene in `resouresReferences.lipsyncAnimSets`
ergaenzt werden - beim Vollausbau also je ein Eintrag pro betroffener Szene.

**Nicht anfassen:** `voInfo` (VVF fuehrt 13012 Eintraege bei 205 voInfo), `locStore`
(Editor-Beschriftungen).

### Die beiden Ids sind der Knackpunkt

```
itemId    Judy:  1, 257, 513, 769, 1025 ...  = 0x1, 0x101, 0x201, 0x301
          VVF:   alle 12978 enden auf 0x01
Ereignis  alle auf 4 ausgerichtet, in Vanilla wie bei VVF
```

Beide als "naechste freie Zahl" zu vergeben schlaegt fehl - und zwar **still**: der
Eintrag loest auf, spielt aber eine andere Zeile. Keine Laengenpruefung und kein
Feldvergleich findet das, weil die Felder da sind und die Typen stimmen. Nur die Werte
sind ungueltig.

Das erklaert auch, warum das Umbiegen einer **vorhandenen** Zeile von Anfang an
funktionierte: deren Ids waren bereits wohlgeformt.

## Offen


* **Dauern** der Quest-Zeilen - aus den `.wem` messen statt schaetzen.
* **Randomizer** - wie `scnRandomizerNode` die Varianten waehlt, falls wir Familien bauen.
* **Sprecher-Id** - `speaker`/`addressee` stehen bei Judy beide auf 0; ob das fuer
  zusaetzliche Zeilen so bleiben kann, ist ungeprueft.
* **Dauer** - die Vorlage-Dauer bleibt beim Klonen stehen. Fuer eine laengere Zielzeile
  schneidet das ab. Als naechstes aus den `.wem` messen.
* **Sprachen** - Lipsync-Sets liegen je Sprache getrennt. Der Pfad unten ist `de-de`;
  fuer eine veroeffentlichte Mod muessten die Sets aller unterstuetzten Sprachen mit
  hinein oder pro Sprache ein eigenes Archiv gebaut werden.

## Nachtrag aus dem Durchstich

### Sechs Teile, nicht vier

Neben Zeile, Section-Knoten, Start-Knoten und Einstiegspunkt braucht ein Eintrag zwei
Registrierungen, die **parallel zu `entryPoints`** gefuehrt werden:

```
sceneGraph.Data.startNodes[i]   traegt die nodeId von entryPoints[i]
voInfo[i].outVoTrigger          traegt den Namen von entryPoints[i]
```

Judy: 65/65/65. Vs Vanilla: 201/201/201. Fehlt eine davon, liegt der Start-Knoten zwar im
Graphen, ist aber nirgends als Einstieg registriert.

Dazu die Debug-Symbole, je eines pro Knoten und pro Dialogzeilen-Ereignis. Ob die Engine
sie zur Laufzeit braucht, ist offen - sie sind als Debug-Metadaten benannt, und der
Durchstich lief auch mit stimmigen Symbolen nicht. Als Hygiene trotzdem richtig.

### Lipsync-Anim-Sets sind szenengebunden

`resouresReferences.lipsyncAnimSets` enthaelt bei Judy **einen** Eintrag:

```
base/quest/secondary_characters/vsets/lipsync/en/vset_judy/judy.anims
```

Darin liegen nur die Animationen der 55 Barks. Eine Quest-Zeile aus `mq055` verweist auf
eine Animation, die in `mq055`s eigenem Set liegt - also nicht in diesem. Fuer den
Vollausbau muessten die betroffenen Sets mit referenziert werden.

**Kein Blocker fuers Abspielen:** der Umbau der `danger`-Zeile lieferte Audio, obwohl die
Animation nicht im Set liegt. Es kostet Lippenbewegung, nicht die Zeile.

### Was der Durchstich bewiesen hat

Der Umbau einer **bestehenden** Zeile auf eine fremde `ruid` funktioniert. Damit sind
belegt: das Archiv laedt, `ruid` findet die richtige `.wem`, die Lipsync-Namen sind gueltig,
Audio laeuft ueber eine Voiceset-Section.

Offen ist ausschliesslich, ob ein **neu angelegter** Einstiegspunkt erreichbar ist. Die
Kette dorthin ist feldgenau identisch zu einem funktionierenden Vanilla-Eintrag - Index,
nodeId, Sockets, Section, Ereignis, Zeile, alle Typen gleich.

