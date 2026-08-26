--  "Aufhelfen" - ein Eintrag in NCAs Begleiter-Menue.
--
--  Warum hier und nicht bei uns: NCA laedt diesen Ordner rekursiv ein
--  (`ModuleLoader:LoadInteractions` -> `getFilesRecursively("./Interactions", ...)`), und
--  jede Datei gibt einfach eine Liste von Eintraegen zurueck. Das ist eine
--  Erweiterungsschnittstelle, auch wenn sie nirgends so genannt wird - und der einzige
--  Weg, in dieses Menue zu kommen, ohne NCAs eigene Dateien anzufassen.
--
--  ACHTUNG: die Datei liegt IN NCAs Mod-Ordner. Ein Update von NCA raeumt sie weg. Sie
--  gehoert deshalb zu unserer Auslieferung (`manifest.json` -> `cet_files`), damit ein
--  erneutes `apply.py` sie zurueckbringt.
--
--  Was passiert, wenn sie umkippt: NCA meldet den Tod, entfernt ihren Griff, DESPAWNT sie
--  und startet einen Timer ueber 150 SPIELminuten. Erst danach ist sie ueberhaupt wieder
--  rufbar. Das trifft aber nur den echten Tod. Bleibt sie liegen und ist noch da - der
--  haeufigere Fall -, ist sie `Defeated`, und das ist ein Statuseffekt wie die Wunde:
--  abnehmbar.

local ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.HandshakeIcon")

--  Deutsch fest verdrahtet. NCAs `Labels()` uebersetzt ueber Schluessel aus seinen eigenen
--  Sprachdateien, und dort einen eigenen einzutragen hiesse, seine Dateien doch anzufassen.
local LABEL = "Aufhelfen"

local function koerper(npc)
  local e
  pcall(function() e = npc:GetEntity() end)
  return e
end

local function amBoden(npc)
  local e = koerper(npc)
  if not e then return false end
  local v = false
  pcall(function() v = ScriptedPuppet.IsDefeated(e) end)
  return v == true
end

local function aufhelfen(npc)
  local e = koerper(npc)
  if not e then return end

  --  Gesundheit ZUERST. Nimmt man ihr nur den Zustand, faellt sie mit zwei Trefferpunkten
  --  sofort wieder um, und das saehe aus wie ein kaputter Knopf.
  pcall(function()
    Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
      e:GetEntityID(), gamedataStatPoolType.Health, 100.0, nil, true)
  end)

  --  `Defeated` und `DefeatedWithRecover` sind die beiden, die `ScriptedPuppet.IsDefeated`
  --  abfragt. `Wounded` kommt mit weg - wer jemandem aufhilft, laesst ihn nicht humpelnd
  --  stehen. Jeder Typ einzeln, damit ein fehlender nicht die anderen mitnimmt.
  for _, typ in ipairs({ "Defeated", "DefeatedWithRecover", "Wounded" }) do
    pcall(function()
      StatusEffectHelper.RemoveAllStatusEffectsByType(e, gamedataStatusEffectType[typ])
    end)
  end
end

return {
  { label = LABEL, icon = ICON, callback = aufhelfen, condition = amBoden },
}
