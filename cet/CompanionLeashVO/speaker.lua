--  Der Sprecher - eine Stelle, die entscheidet, wann Judy redet.
--
--  Vorher hatte der Blick seine eigene Belegt-Fahne. Das funktioniert genau so lange, wie
--  es nur einen Ausloeser gibt. Mit Kampf, Sorge, Warten und Wiedersehen kommen 127 Zeilen
--  dazu, und ohne gemeinsame Instanz schneidet die Kampfende-Zeile mitten in einen Satz.
--
--  Ein Ausloeser spielt nichts mehr selbst ab. Er reicht einen Antrag ein:
--
--      Speaker.Request({ situation = "blick", prio = 40, pool = "blick1",
--                        line = "cl_...", dauer = 1.1, cd = 180.0, ziel = obj })
--
--  KEINE Unterbrechung. Eine wichtigere Zeile wartet, statt zu schneiden - bei echtem
--  Lipsync ist ein sauber zu Ende gesprochener Satz mehr wert als eine korrekte Rangfolge.
--  Die Prioritaet entscheidet also nur unter WARTENDEN Antraegen.
--
--  Der Generationszaehler ist kein Beiwerk. Ohne ihn setzt der Nachlauf-Timer einer
--  abgelaufenen Zeile den Zustand einer laengst laufenden neuen zurueck, und Judy faengt
--  an, sich selbst ins Wort zu fallen - ein Fehler, der nur sporadisch auftritt und sich
--  darum kaum finden laesst.

local Speaker = {}

--  Rangfolge. Nur fuer wartende Antraege, nie gegen eine laufende Zeile.
Speaker.PRIO = {
  kampf       = 100,
  kampf_ende  =  90,
  sorge       =  70,
  wiedersehen =  60,
  abschied    =  50,
  blick       =  40,
  fahrzeug    =  30,
  alltag      =  20,
  stolz       =  20,
  flirt       =  10,
  naehe       =  10,
}

local NACHLAUF   = 1.5    -- Ruhe nach dem Ende einer Zeile
local WECHSEL    = 1.5    -- zusaetzlicher Abstand, wenn die naechste Zeile aus einer
                          -- ANDEREN Situation kommt
local WARTEZEIT  = 2.0    -- ein wartender Antrag verfaellt danach
local MAX_TIER   = 2      -- ueber Tier 2 laeuft Questdialog, Telefonat oder Cutscene

local S = {
  jetzt   = 0.0,
  gen     = 0,
  aktiv   = nil,      -- { situation, prio, line, gen, endeUm }
  ruheBis = 0.0,
  cdBis   = {},       -- Pool -> Zeitpunkt
  zuletzt = {},       -- Pool -> zuletzt gespielter Name
  warten  = {},       -- Situation -> Antrag (hoechstens einer je Situation)
  buch    = {},       -- Ringpuffer der letzten Entscheidungen
  zaehler = { angenommen = 0, abgelehnt = 0 },
  gruende = {},       -- Ablehnungsgrund -> Anzahl
}

local spielen, schreiben

function Speaker.Init(opts)
  spielen  = opts.spielen
  schreiben = opts.schreiben or function() end
end

local function buchen(art, text)
  S.buch[#S.buch + 1] = string.format("%7.1fs  %-7s %s", S.jetzt, art, text)
  while #S.buch > 12 do table.remove(S.buch, 1) end
end

local function ablehnen(a, grund)
  S.zaehler.abgelehnt = S.zaehler.abgelehnt + 1
  S.gruende[grund] = (S.gruende[grund] or 0) + 1
  buchen("REJECT", string.format("%s  grund=%s", a.situation, grund))
  schreiben(string.format("SPEAKER REJECT situation=%s prio=%d grund=%s%s",
      a.situation, a.prio or 0, grund,
      S.aktiv and string.format(" aktiv=%s prio=%d", S.aktiv.situation, S.aktiv.prio) or ""))
end

--  Laeuft gerade Vanilla-Dialog? Der Szenen-Tier sagt es in einem Wert: ab Tier 3 hat der
--  Spieler die Kontrolle abgegeben, und dort hat eine Bark nichts verloren.
local function tierOk()
  local t = 1
  local ok = pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():GetLocalInstanced(
                 Game.GetPlayer():GetEntityID(), defs.PlayerStateMachine)
    if bb then t = bb:GetInt(defs.PlayerStateMachine.SceneTier) end
  end)
  if not ok then return true end          -- nicht lesbar: nicht daran scheitern
  if t == 0 then return true end          -- 0 kommt vor, wenn nichts gesetzt ist
  return t <= MAX_TIER
end

--  Warum ein Antrag jetzt nicht darf. nil heisst: er darf.
local function pruefen(a)
  if not a.line or a.line == "" then return "noLine" end
  if not tierOk() then return "dialogueActive" end
  if S.jetzt < S.ruheBis then return "globalCooldown" end
  if a.pool and S.cdBis[a.pool] and S.jetzt < S.cdBis[a.pool] then return "cooldown" end
  if a.pool and S.zuletzt[a.pool] == a.line then return "duplicateLine" end
  return nil
end

local function starten(a)
  S.gen = S.gen + 1
  local dauer = (a.dauer or 2.0) + NACHLAUF
  S.aktiv = { situation = a.situation, prio = a.prio or 0, line = a.line,
              gen = S.gen, endeUm = S.jetzt + dauer }
  if a.pool then
    S.zuletzt[a.pool] = a.line
    if a.cd and a.cd > 0.0 then S.cdBis[a.pool] = S.jetzt + dauer + a.cd end
  end
  S.zaehler.angenommen = S.zaehler.angenommen + 1
  buchen("ACCEPT", string.format("%s  %s  %.1fs", a.situation, a.line, a.dauer or 0))
  schreiben(string.format("SPEAKER ACCEPT situation=%s prio=%d line=%s dauer=%.2f bis=%.1f",
      a.situation, a.prio or 0, a.line, a.dauer or 0, S.aktiv.endeUm))
  spielen(a.line, a.ziel)
end

--  Ein Antrag. Gibt true zurueck, wenn sofort gesprochen wird.
function Speaker.Request(a)
  a.prio = a.prio or Speaker.PRIO[a.situation] or 0
  schreiben(string.format("SPEAKER REQUEST situation=%s prio=%d pool=%s line=%s",
      a.situation, a.prio, tostring(a.pool), tostring(a.line)))

  local grund = pruefen(a)
  if grund then ablehnen(a, grund); return false end

  if S.aktiv then
    --  Nicht schneiden. Hoechstens einen Antrag je Situation warten lassen, und der
    --  verfaellt - eine Kampfende-Zeile drei Sekunden nach dem Kampf ist keine mehr.
    local alt = S.warten[a.situation]
    if alt and alt.prio > a.prio then ablehnen(a, "lowerPriority"); return false end
    a.verfaelltUm = S.jetzt + WARTEZEIT
    S.warten[a.situation] = a
    buchen("QUEUE", string.format("%s  hinter %s", a.situation, S.aktiv.situation))
    return false
  end

  starten(a)
  return true
end

--  Alles Wartende einer Situation verwerfen. Fuer Zustandswechsel: wer den Kampf verlaesst,
--  braucht die Kampfzeile nicht mehr.
function Speaker.Verwerfen(situation)
  if S.warten[situation] then
    buchen("DROP", situation)
    S.warten[situation] = nil
  end
end

function Speaker.Tick(d)
  S.jetzt = S.jetzt + d

  if S.aktiv and S.jetzt >= S.aktiv.endeUm then
    --  Nur die eigene Generation abraeumen. Ohne diese Pruefung koennte ein alter
    --  Nachlauf eine inzwischen laufende Zeile beenden.
    local a = S.aktiv
    S.aktiv = nil
    S.ruheBis = S.jetzt
    schreiben("SPEAKER FINISH line=" .. a.line)
    buchen("FINISH", a.line)
    S.letzteSituation = a.situation
  end

  --  Verfallene Antraege raeumen.
  for sit, a in pairs(S.warten) do
    if S.jetzt > (a.verfaelltUm or 0.0) then
      ablehnen(a, "staleRequest")
      S.warten[sit] = nil
    end
  end

  if S.aktiv then return end

  --  Bester wartender Antrag.
  local best, bestSit
  for sit, a in pairs(S.warten) do
    if not best or a.prio > best.prio then best, bestSit = a, sit end
  end
  if not best then return end

  --  Zwischen zwei verschiedenen Situationen ein Atemzug mehr, sonst haengt die
  --  Sorge-Zeile unmittelbar am Kampfende.
  local abstand = (S.letzteSituation and S.letzteSituation ~= best.situation) and WECHSEL or 0.0
  if S.jetzt < S.ruheBis + abstand then return end

  S.warten[bestSit] = nil
  local grund = pruefen(best)
  if grund then ablehnen(best, grund); return end
  starten(best)
end

function Speaker.Status()
  return {
    jetzt = S.jetzt,
    aktiv = S.aktiv and string.format("%s  %s  noch %.1fs",
              S.aktiv.situation, S.aktiv.line, math.max(0.0, S.aktiv.endeUm - S.jetzt)) or "-",
    warten = (function()
      local n = 0
      for _ in pairs(S.warten) do n = n + 1 end
      return n
    end)(),
    angenommen = S.zaehler.angenommen,
    abgelehnt = S.zaehler.abgelehnt,
    gruende = S.gruende,
    buch = S.buch,
    cdBis = S.cdBis,
  }
end

--  Fuer das Panel: alle Sperren loesen, damit man beim Einstellen nicht wartet.
function Speaker.Freigeben()
  S.aktiv, S.ruheBis = nil, 0.0
  S.cdBis, S.warten, S.zuletzt = {}, {}, {}
  buchen("CLEAR", "alle Sperren geloest")
end

return Speaker
