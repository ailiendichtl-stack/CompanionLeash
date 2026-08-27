--  Die Ausloeser. Jeder beobachtet einen Zustand und stellt Antraege beim Sprecher.
--
--  Keiner spielt selbst ab, keiner kennt Voiceset-Namen, keiner fuehrt eine eigene
--  Belegt-Fahne. Sie kennen nur ihren Pool und ihre Bedingungen; wann tatsaechlich geredet
--  wird, entscheidet `speaker.lua` allein.
--
--  Einen neuen Ausloeser anzulegen heisst: eine Beobachtung schreiben und
--  `Speaker.Request` aufrufen. Die Zeilen kommen aus `lines.lua`, das die Matrix erzeugt -
--  hier steht kein einziger Zeilentext.

local T = {}

local Speaker, LINES, log, holeZiel, letzteZeile

--  ---------------------------------------------------------------- gemeinsame Hilfen

--  Laeuft eine Spielsitzung? Im Hauptmenue und waehrend des Ladens gibt es keinen Spieler,
--  und ein nil an eine native Funktion zu reichen faengt kein pcall ab - das nimmt den
--  Prozess mit. Genau daran ist der erste Anlauf gestorben.
local function spieler()
  local vor = true
  local ok = pcall(function() vor = Game.GetSystemRequestsHandler():IsPreGame() end)
  if not ok or vor then return nil end
  local p
  pcall(function() p = Game.GetPlayer() end)
  return p
end

local function imSpiel()
  return spieler() ~= nil
end

--  Steht das Spiel? Im Pausenmenue, im Inventar und auf der Karte laeuft `onUpdate`
--  weiter, das Spiel aber nicht. Ohne diese Sperre zaehlen alle Uhren durch: die
--  Standuhr der Leiter (im Menue bewegt sich niemand), der Zufallstimer, die Blickdauer.
--  Nach dem Schliessen waeren mehrere Sprossen gleichzeitig faellig und wuerden sich
--  aufeinander stapeln.
local function pausiert()
  local p = false
  pcall(function() p = Game.GetSystemRequestsHandler():IsGamePaused() end)
  if p == true then return true end
  pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():Get(defs.UI_System)
    if bb then p = bb:GetBool(defs.UI_System.IsInMenu) end
  end)
  return p == true
end

function T.Pausiert() return pausiert() end

--  Ein Wert aus der Spieler-Zustandsmaschine.
--
--  `Game.GetPlayer():IsInCombat()` sah naheliegend aus und lieferte nie etwas - der Aufruf
--  scheiterte, das pcall schluckte es, und der Kampf-Ausloeser blieb still. Nichts im
--  Protokoll, weil ich nur Zustandswechsel schreibe, und Wechsel gab es nie.
--
--  Darum zwei Dinge: das Blackboard statt der Skriptfunktion, und eine Sonde, die ihren
--  ERSTEN Fehlschlag meldet. Eine Abfrage, die stumm nichts liefert, kostet mehr Zeit als
--  jeder laute Fehler.
local sondeTot = {}

--  Eine Abfrage, die still nichts liefert, kostet mehr Zeit als jeder laute Fehler -
--  genau daran ist der Kampf-Ausloeser einen ganzen Abend lang gescheitert. Jede Sonde
--  meldet darum ihren ersten Fehlschlag, danach schweigt sie.
--  `nilIstOk`, weil nil oft die richtige Antwort ist: wer nicht im Wagen sitzt, hat kein
--  Fahrzeug. Ohne die Unterscheidung meldet die Sonde einen Fehlschlag, wo nur nichts war -
--  und eine Warnung, die faelschlich kommt, macht die echten wertlos.
local function sonde(name, fn, nilIstOk)
  local wert
  local ok = pcall(function() wert = fn() end)
  if not ok or (wert == nil and not nilIstOk) then
    if not sondeTot[name] then
      sondeTot[name] = true
      log("SONDE " .. name .. (ok and " liefert nichts" or " nicht aufrufbar"))
    end
  end
  return wert
end

local function psm(feld)
  local p = spieler()
  if not p then return nil end
  local wert, ok = nil, false
  pcall(function()
    local defs = Game.GetAllBlackboardDefs()
    local bb = Game.GetBlackboardSystem():GetLocalInstanced(
                 p:GetEntityID(), defs.PlayerStateMachine)
    if bb then
      wert = bb:GetInt(defs.PlayerStateMachine[feld])
      ok = wert ~= nil
    end
  end)
  if not ok and not sondeTot[feld] then
    sondeTot[feld] = true
    log("SONDE PlayerStateMachine." .. feld .. " nicht lesbar")
  end
  return wert
end

--  Alle Eintraege einer Situation, wahlweise nur einer Stufe.
local function pool(situation, stufe)
  local p = {}
  for _, l in ipairs(LINES) do
    if l.s == situation and (not stufe or l.st == stufe) then p[#p + 1] = l end
  end
  return p
end

--  Ist das Judy?
--
--  Zwei naheliegende Wege sind im Spiel durchgefallen, und beide schweigend:
--
--    `TDBID.ToStringDBID` braucht aufgeloeste TweakDB-Namen. Fehlen sie, kommt gar nichts
--    zurueck - im Panel stand `record=?`.
--
--    `GetDisplayName` liefert bei ihr `LocKey#47008`, nicht "Judy". Der Name steht in der
--    Lokalisierung und muss erst nachgeschlagen werden.
--
--  Darum wird die Record-Id jetzt als ZAHL verglichen, gegen `Character.Judy` - das ist
--  die Id, unter der NCA sie fuehrt. Keine Namensaufloesung, keine Sprache, kein Debugname.
--  Der aufgeloeste LocKey und das gesperrte Panel-Ziel bleiben als Rueckfallebenen.
local JUDY = nil
pcall(function() JUDY = TweakDBID.new("Character.Judy") end)

local function idGleich(a, b)
  if not a or not b then return false end
  local x, y
  pcall(function() x = string.format("%s:%s", tostring(a.hash), tostring(a.length)) end)
  pcall(function() y = string.format("%s:%s", tostring(b.hash), tostring(b.length)) end)
  return x ~= nil and x == y
end

--  Anzeigename, notfalls ueber die Lokalisierung aufgeloest.
local function klarname(o)
  local n = "?"
  pcall(function() n = tostring(o:GetDisplayName()) end)
  if n:find("LocKey", 1, true) then
    local k = n
    pcall(function()
      local t = Game.GetLocalizedText(k)
      if t and t ~= "" then n = tostring(t) end
    end)
  end
  return n
end

local function beschreibe(o)
  local rec = "?"
  pcall(function()
    local r = o:GetRecordID()
    if r then rec = string.format("%s:%s", tostring(r.hash), tostring(r.length)) end
  end)
  return rec, klarname(o)
end

local function istJudy(o)
  if not o then return false end

  local ziel = holeZiel and holeZiel() or nil
  if ziel then
    local a, b
    pcall(function() a = tostring(ziel:GetEntityID().hash) end)
    pcall(function() b = tostring(o:GetEntityID().hash) end)
    if a and a == b then return true end
  end

  local r
  pcall(function() r = o:GetRecordID() end)
  if idGleich(r, JUDY) then return true end

  if klarname(o):lower():find("judy", 1, true) then return true end

  --  Frueher stand hier ein Eintrag je unbekanntem Objekt. Das hat die Erkennung
  --  aufgeklaert, aber Night City hat Tausende Entitaeten, und 75 von 160 Zeilen waren
  --  Autos und Passanten. Was jetzt zaehlt, steht im Panel unter "anvisiert" - live und
  --  ohne Protokoll.
  return false
end

--  ---------------------------------------------------------------- Beziehungsstand

--  Flirt braucht keine Ausloesung, sondern eine SPERRE. Wer die Romanze nie gespielt hat,
--  soll nicht angeflirtet werden - das faellt sofort auf und ist keine Geschmacksfrage,
--  sondern schlicht falsch.
--
--  Der erste Versuch nahm NCAs `love`. Das war der falsche Wert: er zaehlt NCAs eigenen
--  Fortschritt aus Posen und Gespraechen. Im Spiel stand "Liebe 6 / Freundschaft 70" bei
--  abgeschlossener Romanze und fester Partnerin - als Sperre haette er alles zugehalten.
--
--  Der richtige Wert ist ein Quest-Fakt. Das Spiel fuehrt sie je Figur nach demselben
--  Muster - `sq027_panam_lover`, `sq029_river_lover`, `sq028_kerry_relationship` -, und
--  Judys heisst `sq030_judy_lover`. Beide hier benutzten Fakten werden von installierten
--  Romanzen-Mods abgefragt, sind also nicht geraten.
local FAKTEN = { "sq030_judy_lover", "mq055_judy" }

local NCA_PS = nil
local bez = { liebe = nil, freund = nil, fakt = nil, welcher = nil }

local function beziehungLesen()
  if NCA_PS == nil then
    pcall(function()
      local c = Game.GetScriptableSystemsContainer()
      NCA_PS = c:Get("NightCityAllies.Persistence.PersistenceSystem")
      if not NCA_PS then NCA_PS = c:Get("PersistenceSystem") end
    end)
    if not NCA_PS then
      NCA_PS = false
      log("SONDE NCAs PersistenceSystem nicht erreichbar - Flirt bleibt gesperrt")
    end
  end
  if NCA_PS and JUDY then
    pcall(function()
      bez.liebe  = NCA_PS:GetLove(JUDY)
      bez.freund = NCA_PS:GetFriendship(JUDY)
    end)
  end

  --  Der Fakt entscheidet. NCAs Werte stehen nur zur Anschauung daneben.
  bez.fakt, bez.welcher = nil, nil
  for _, name in ipairs(FAKTEN) do
    local v
    pcall(function() v = Game.GetQuestsSystem():GetFact(CName.new(name)) end)
    if v and v > 0 then
      bez.fakt, bez.welcher = v, name
      return
    end
    if v ~= nil and bez.fakt == nil then bez.fakt = 0 end
  end
end

--  Unbekannt heisst gesperrt - aber sichtbar gesperrt. Im Panel steht, welcher Fakt
--  gegriffen hat; ein stiller Riegel waere nach dieser Woche genau das falsche Verhalten.
local function verliebtGenug()
  return bez.fakt ~= nil and bez.fakt > 0
end

--  ---------------------------------------------------------------- Wo ist Judy

--  Eine Referenz auf sie, die sich selbst instand haelt.
--
--  Zwei Quellen liefern sie beilaeufig: der Blick, sobald V sie ansieht, und der
--  Untertitel, sobald sie etwas sagt - dort steht das Sprecherobjekt, nicht nur ein Name.
--  Beides passiert oft genug, dass eine verlorene Referenz von selbst zurueckkommt.
--
--  Gehalten wird sie nur, solange `IsAttached` das bestaetigt. NCA despawnt Begleiter bei
--  Entfernung und in gesperrten Zonen; eine Referenz auf eine abgeraeumte Entity waere
--  genau die Art Nullzeiger, die dieses Projekt schon zweimal abgestuerzt hat.
local judy = { obj = nil, dist = nil }

local function judyMerken(o)
  if o then judy.obj = o end
end

local function judyHolen()
  if not judy.obj then return nil end
  local da = false
  pcall(function() da = judy.obj:IsAttached() end)
  if not da then
    judy.obj, judy.dist = nil, nil
    return nil
  end
  return judy.obj
end

--  Abstand V zu Judy, oder nil wenn sie gerade nicht greifbar ist.
local function abstand(p)
  local o = judyHolen()
  if not o or not p then judy.dist = nil; return nil end
  local w
  pcall(function() w = Vector4.Distance(p:GetWorldPosition(), o:GetWorldPosition()) end)
  judy.dist = w
  return w
end

--  ---------------------------------------------------------------- Haltung

--  Geht V in die Hocke, soll Judy es auch tun - und dabei weiterlaufen.
--
--  Der Weg fuehrt durch dieselbe Tuer, die die Kampf-KI benutzt. Die Haltung wird nicht
--  ueber ein Anim-Feature gesetzt, sondern ueber ein Signal an ihre Zustandskomponente:
--
--      puppet:GetStatesComponent():OnNPCStateChangeSignalReceived(signal)
--
--  `OnNPCStateChangeSignalReceived` ist oeffentlich, und `ChangeStanceState` dahinter macht
--  genau das Richtige: Anim-Feature anwenden, Anim-Wrapper-Gewichte umsetzen, Blackboard
--  schreiben. Selbst am Anim-Feature zu drehen haette den halben Weg nachgebaut.
--
--  OFFEN und der eigentliche Grund fuer die Rueckmessung: ob die KI die Haltung beim
--  naechsten Verhaltensschritt wieder ueberschreibt. Darum wird nicht blind gesetzt,
--  sondern der Ist-Wert aus ihrem Blackboard gelesen und nachgezogen.
local STANCE = { Crouch = "Crouch", Stand = "Stand" }
local HALTUNG = { takt = 0.4, auffrischen = 3.0 }

--  Der Schalter ist die LAGE, nicht die Haltung.
--
--  Tagelang habe ich die Haltung gesetzt, sauber, ueber sechs verschiedene Wege - und sie
--  blieb stehen. Der Wert kam an und blieb fuenfzehn Sekunden liegen, ohne dass ihn jemand
--  gelesen haette. Was fehlte, war die Ebene darueber: in `Relaxed` hat ihr Graph keine
--  Hocke, in die er wechseln koennte.
--
--  Gemessen: Lage auf `Stealth` gesetzt, zwei Sekunden spaeter steht der Haltungswert von
--  selbst wieder auf Stand - und sie hockt weiter. Die tiefe Hocke haengt an der Lage.
--  Deshalb ist `Stand` in der Stealth-Lage auch kein Rueckweg: aufrecht heisst dort immer
--  noch geduckt. Zurueck geht nur ueber `Relaxed`.
local LAGEN = { hocke = "Stealth", normal = "Relaxed" }

local haltung = { an = true, ziel = nil, ist = nil, seit = 0.0,
                  weg = nil, auffrisch = 0.0,
                  gesetzt = 0, korrekturen = 0, aufgefrischt = 0,
                  gemeldet = false, gemeldetOk = false }

--  Der ECHTE Zustand, nicht der gespiegelte.
--
--  `GetCurrentStanceState` liest `GetReplicatedStanceState` - das ist der Wert, den die
--  Zustandsmaschine wirklich fuehrt. Das Blackboard daneben ist nur eine Kopie, die
--  `UpdateStanceState` mitschreibt; wer sie selbst setzt, prueft sich gegen sich selbst.
local function haltungLesen(o)
  local v
  pcall(function()
    local comp = o:GetStatesComponent()
    if comp then v = comp:GetCurrentStanceState() end
  end)
  if v ~= nil then
    local n
    pcall(function() n = EnumInt(v) end)
    if n ~= nil then return n end
  end
  return v
end

--  `NPCPuppet.ChangeStanceState(obj, newState)` - oeffentlich, statisch, und genau das,
--  was die Behavior-Aufgaben selbst aufrufen (`aiChangeNPCState.script`).
--
--  Der lange Weg hierher, damit er nicht nochmal gegangen wird:
--
--    Den Empfaenger direkt aufzurufen aenderte nur den Spiegel der Komponente.
--    Anim-Feature und Wrapper sind die Anzeigeebene, nicht der Zustand.
--    Das Blackboard selbst zu setzen war schaedlich - es ist die Kopie, nicht das Original.
--
--  Diese Funktion hebt das Signal so, wie die KI es tut - aber ueber
--  `owner:GetSignalTable()`, NICHT ueber `GetAIControllerComponent():GetSignals()`. Zwei
--  verschiedene Tabellen; mein Nachbau nahm die falsche.
--
--  Sie hat ausserdem eine Vorpruefung: `GetStanceStateFromBlackboard() == newState` steigt
--  sofort aus. Genau deshalb war das eigenmaechtige Beschreiben des Blackboards nicht nur
--  unsauber, sondern haette diesen Weg aktiv blockiert.
local function haltungSetzen(o, name)
  local ok = false
  pcall(function()
    NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", name))
    ok = true
  end)

  --  Rueckfall: dieselbe Mechanik von Hand, ueber die AI-Controller-Tabelle. Bleibt drin,
  --  weil sie eine andere Tabelle anspricht - falls die statische Funktion nicht greift,
  --  sagt der Vergleich etwas aus.
  if not ok then
    pcall(function()
      local tbl = o:GetAIControllerComponent():GetSignals()
      local sig = NewObject("NPCStateChangeSignal")
      sig.m_stanceState = Enum.new("gamedataNPCStanceState", name)
      sig.m_stanceStateValid = true
      local id = tbl:GetOrCreateSignal(CName.new("NPCStateChangeSignal"))
      tbl:Set(id, false)
      tbl:SetWithData(id, sig)
      ok = true
      haltung.weg = "Signaltabelle"
    end)
  else
    haltung.weg = "NPCPuppet.ChangeStanceState"
  end

  if not haltung.gemeldet then
    haltung.gemeldet = true
    log("HALTUNG Weg: " .. tostring(haltung.weg or "keiner"))
  end
  return ok
end

--  ---------------------------------------------------------------- Haltung: alle Wege
--
--  Solange nichts wirkt, ist Raten teuer: jeder Versuch kostet einen Reload und einen
--  Testlauf. Darum liegt jeder Weg auf einem eigenen Knopf, und jeder misst den ECHTEN
--  Zustand vor und nach dem Versuch - `GetCurrentStanceState()`, nicht den Spiegel.
--
--  Der interessanteste ist Nummer 6: `SetReplicatedStanceState` gibt einen Bool zurueck,
--  den das private `ChangeStanceState` verschluckt. Den hat noch nie jemand gesehen.
--  ---------------------------------------------------------------- Kontext
--
--  Eine Momentaufnahme, aus der alle Module lesen. Ohne sie liest jedes neue Modul die
--  NCA-Felder leicht unterschiedlich, und wohin das fuehrt, hat uns der Kampf-Riegel
--  gerade vorgefuehrt: wir fragten IHR `IsInCombat()`, NCA haengt an VS Kampfzustand, und
--  genau in der Luecke dazwischen haetten wir sein `Combat` mit unserem `Relaxed`
--  ueberschrieben, waehrend sie in Deckung geht.
--
--  Deshalb wird hier zunaechst NICHTS ersetzt, sondern VERGLICHEN. Beide Quellen laufen
--  nebeneinander, jede Abweichung geht ins Protokoll. Ausgebaut wird erst, wenn der Log
--  zeigt, dass sie dieselben Uebergaenge melden - und nicht, weil es plausibel klingt.

--  Ein Ortssprung - Schnellreise, Aufzug, Teleport - ist eine Tatsache ueber die WELT und
--  gehoert keinem einzelnen Ausloeser. Er lag bisher im Wiedersehen, und genau daran ist
--  der Abschied gescheitert: beim Schnellreisen verschwindet sie aus 14 m Naehe, der
--  Abschied laeuft frueher im Takt, feuert - und erst danach stellt das Wiedersehen den
--  Sprung fest. Im Log steht beides in derselben Sekunde:
--
--      13:24:46  ABSCHIED sie war 14 m entfernt und ist weg
--      13:24:46  WIEDERSEHEN Ortssprung 574 m
--
--  Deshalb jetzt einmal ganz vorn im Takt gemessen, JEDES Bild - eine halbe Sekunde
--  Taktung wuerde dem Abschied wieder Zeit lassen, dazwischenzugehen.
local SPRUNG = { weite = 150.0, ruhe = 15.0 }
local welt = { letztePos = nil, sprungSeit = nil }

local function weltTick(d, p)
  if welt.sprungSeit then welt.sprungSeit = welt.sprungSeit + d end
  local pos
  pcall(function() pos = p:GetWorldPosition() end)
  if pos and welt.letztePos then
    local weit = 0.0
    pcall(function() weit = Vector4.Distance(pos, welt.letztePos) end)
    if weit > SPRUNG.weite then
      welt.sprungSeit = 0.0
      log(string.format("WELT Ortssprung %.0f m", weit))
    end
  end
  welt.letztePos = pos
end

--  Kurz nach einem Sprung ist nichts, was mit Naehe zu tun hat, noch zu glauben.
local function frischGesprungen()
  return welt.sprungSeit ~= nil and welt.sprungSeit < SPRUNG.ruhe
end

local KTX_TAKT = 0.5

local NCA_CTX = nil
local ktx = {
  seit = 0.0,
  eigen = { kampf = false, wagen = false, menue = false, hockt = false },
  nca   = { da = false, kampf = nil, wagen = nil, menue = nil,
            interaktion = nil, ort = nil, distrikt = nil },
  abw   = {},        -- Feld -> Anzahl Abweichungen
  proben = 0,
}

local function ncaKontext()
  if NCA_CTX ~= nil then return NCA_CTX or nil end
  local c
  pcall(function()
    local cont = Game.GetScriptableSystemsContainer()
    c = cont:Get("NightCityAllies.Persistence.ContextSystem")
    if not c then c = cont:Get("ContextSystem") end
  end)
  NCA_CTX = c or false
  log(c and "KONTEXT NCAs ContextSystem erreichbar - Vergleich laeuft"
        or "KONTEXT NCAs ContextSystem nicht erreichbar - eigene Messung bleibt allein")
  return c
end

--  Jedes Feld einzeln. Ein fehlendes darf die anderen nicht mitreissen.
local function ncaFeld(c, name)
  local v
  pcall(function() v = c[name] end)
  return v
end

local function abweichung(feld, unser, ihrer)
  if ihrer == nil then return end
  if unser == ihrer then return end
  local n = (ktx.abw[feld] or 0) + 1
  ktx.abw[feld] = n
  --  Erste, 10. und 100. Abweichung. Jede zu melden ertraenkt den Log, keine zu melden
  --  laesst uns glauben, es gaebe keine.
  if n == 1 or n == 10 or n == 100 then
    log(string.format("KONTEXT %s weicht ab (%d.): wir %s, NCA %s",
        feld, n, tostring(unser), tostring(ihrer)))
  end
end

local function kontextTick(d, p)
  ktx.seit = ktx.seit + d
  if ktx.seit < KTX_TAKT then return end
  ktx.seit = 0.0

  --  Unsere eigene Messung, wie bisher.
  local lok = psm("Locomotion")
  ktx.eigen.kampf = psm("Combat") == 1
  ktx.eigen.hockt = lok == 1 or lok == 11 or lok == 12
  ktx.eigen.menue = pausiert()
  ktx.eigen.wagen = false
  pcall(function() ktx.eigen.wagen = Game.GetMountedVehicle(p) ~= nil end)

  local c = ncaKontext()
  if not c then ktx.nca.da = false; return end
  ktx.nca.da = true
  ktx.proben = ktx.proben + 1

  ktx.nca.kampf       = ncaFeld(c, "isInCombat")
  ktx.nca.wagen       = ncaFeld(c, "isInCar")
  ktx.nca.menue       = ncaFeld(c, "isInMenu")
  ktx.nca.interaktion = ncaFeld(c, "isInInteraction")
  ktx.nca.stunde      = ncaFeld(c, "hour")
  ktx.nca.ort         = ncaFeld(c, "location")
  ktx.nca.distrikt    = ncaFeld(c, "district")

  --  Ort und Distrikt haben keine Vergleichsspalte, aber einen Verlauf. Ohne den ist ein
  --  Besuch in der Wohnung nachher spurlos, und Phase 3 haengt genau daran.
  if ktx.nca.ort ~= ktx.ortWar then
    log(string.format("KONTEXT Ort: %s -> %s", tostring(ktx.ortWar), tostring(ktx.nca.ort)))
    ktx.ortWar = ktx.nca.ort
  end
  if ktx.nca.distrikt ~= ktx.distriktWar then
    log(string.format("KONTEXT Distrikt: %s -> %s",
        tostring(ktx.distriktWar), tostring(ktx.nca.distrikt)))
    ktx.distriktWar = ktx.nca.distrikt
  end

  abweichung("kampf", ktx.eigen.kampf, ktx.nca.kampf)
  abweichung("wagen", ktx.eigen.wagen, ktx.nca.wagen)
  abweichung("menue", ktx.eigen.menue, ktx.nca.menue)
end

--  `GetLocalInstanced` war der falsche Zugriff - alle Felder kamen als Strich zurueck.
--  Das Spiel selbst holt dieses Blackboard ueber die Puppe:
--
--      puppet.GetPuppetStateBlackboard().GetInt(PuppetState.HighLevel)
--
--  Damit ist ihre LAGE lesbar, und das ist die Haelfte, die uns bei der gebueckten
--  Haltung gefehlt hat: ob dort `Wounded` (8) steht, war bisher schlicht nicht zu sehen.
--  Tageszeit. Bisher hatten wir diese Dimension gar nicht - NCA fuehrt sie mit, weil sein
--  Timer sie ohnehin braucht. Zwei Fenster, eines davon geht ueber Mitternacht.
local function stundeIn(fenster)
  local h = ktx.nca.stunde
  if type(h) ~= "number" then return false end
  local von, bis = fenster[1], fenster[2]
  if von <= bis then return h >= von and h < bis end
  return h >= von or h < bis     -- ueber Mitternacht
end

local function bbLesen(o, feld)
  local v
  pcall(function()
    local defs = Game.GetAllBlackboardDefs().PuppetState
    local bb = o:GetPuppetStateBlackboard()
    if bb and defs[feld] then v = bb:GetInt(defs[feld]) end
  end)
  return v
end

local LAGENAMEN = { [0] = "Alerted", [1] = "Any", [2] = "Combat", [3] = "Dead",
                    [4] = "Fear", [5] = "Relaxed", [6] = "Stealth",
                    [7] = "Unconscious", [8] = "Wounded" }

local function lageLesen(o)
  local v = bbLesen(o or judyHolen(), "HighLevel")
  if v == nil then return nil, "?" end
  return v, (LAGENAMEN[v] or tostring(v)) .. " (" .. tostring(v) .. ")"
end

--  ---------------------------------------------------------------- Aufhelfen
--
--  Denselben Griff auch bei uns, weil der Weg ueber NCAs Menue unzuverlaessig ist:
--  `App:OnInteract` steigt bei `Context().isInCombat` sofort aus - und genau dieser Wert
--  ist der, bei dem wir 341 Abweichungen gemessen haben. Er bleibt nach dem Gefecht auf
--  `true` haengen, also ist das Menue gerade dann tot, wenn man es braucht.
--
--  Der Eintrag in NCAs `Interactions/` bleibt trotzdem: ausserhalb des Kampfes ist er der
--  schoenere Weg. Das hier ist der, der immer geht.
local liegen = { hat = nil, geholfen = 0, fehler = nil }

local function liegtAmBoden(o)
  local v
  pcall(function() v = ScriptedPuppet.IsDefeated(o or judyHolen()) end)
  return v
end

function T.Aufhelfen()
  local o = judyHolen()
  if not o then log("AUFHELFEN Judy nicht greifbar"); return end

  --  Gesundheit zuerst - sonst steht sie mit zwei Trefferpunkten auf und faellt wieder um.
  local ok = pcall(function()
    Game.GetStatPoolsSystem():RequestSettingStatPoolValue(
      o:GetEntityID(), gamedataStatPoolType.Health, 100.0, nil, true)
  end)
  if not ok then log("AUFHELFEN Gesundheit liess sich nicht setzen") end

  for _, typ in ipairs({ "Defeated", "DefeatedWithRecover", "Wounded" }) do
    local gut, fehler = pcall(function()
      StatusEffectHelper.RemoveAllStatusEffectsByType(o, gamedataStatusEffectType[typ])
    end)
    if not gut then liegen.fehler = typ .. ": " .. tostring(fehler) end
  end

  liegen.geholfen = liegen.geholfen + 1
  log(string.format("AUFHELFEN ausgefuehrt - liegt danach noch: %s",
      tostring(liegtAmBoden(o))))
end

--  ------------------------------------------------- NCAs Kampfsperre: ZURUECKGENOMMEN
--
--  Der Versuch, `App:OnInteract` zu umhuellen und `isInCombat` nur fuer die Dauer des
--  Aufrufs zu drehen, hat NCAs Menue zerlegt: es stand dauerhaft offen, liess sich nicht
--  mehr bedienen und ging beim Weggehen nicht zu. Warum genau, ist noch offen - der Gedanke
--  war sauber, die Wirkung nicht, und ein fremdes Menue kaputtzumachen ist kein Preis, den
--  wir fuer eine Bequemlichkeit zahlen.
--
--  Der Knopf im eigenen Panel bleibt und tut dasselbe, ohne irgendetwas anzufassen.
--
--  Falls wir es noch einmal angehen: erst herausfinden, WAS bricht. Verdacht sind zwei
--  Dinge, die ich nicht auseinandergehalten habe - dass unsere Umhuellung bei einem Reload
--  der Mod ein zweites Mal ueber sich selbst gelegt wird, und dass `ui:Close()` aus NCAs
--  eigener Beobachtung kommt und mit einer ersetzten Methode nicht mehr zusammenpasst.

--  ---------------------------------------------------------------- Orte
--
--  NCA registriert neun Orte ueber `RegisterLocation`, darunter alle fuenf Wohnungen von
--  V. Der Kontext fuehrt den aktuellen als `location`, und draussen steht dort schlicht
--  nichts - das Feld ist nur INNERHALB eines registrierten Ortes belegt.
--
--  Das ist der Unterbau fuer Phase 3. Die 36 Wohnungszeilen lagen zurueck, weil uns ein
--  Ortsmodul fehlte; es war die ganze Zeit da, wir haben nur nie hingesehen.
local ORTSNAMEN = {
  H10_Apartment        = "Wohnung H10",
  CorpoPlaza_Apartment = "Wohnung Corpo Plaza",
  Glen_Apartment       = "Wohnung Glen",
  Northside_Apartment  = "Wohnung Northside",
  JapanTown_Apartment  = "Wohnung Japantown",
  Afterlife            = "Afterlife",
  Lizzies              = "Lizzie's",
}
local WOHNUNGEN = {
  H10_Apartment = true, CorpoPlaza_Apartment = true, Glen_Apartment = true,
  Northside_Apartment = true, JapanTown_Apartment = true,
}

--  `tostring` auf einem CName liefert die Rohform mit Hashes - im Panel stand
--  `ToCName{ hash_lo = 0x0... }`, was niemandem hilft. Der Klartext liegt in `.value`.
local function cnameText(v)
  if v == nil then return nil end
  local t
  pcall(function() t = v.value end)
  if type(t) == "string" and t ~= "" then return t end
  pcall(function() t = NameToString(v) end)
  if type(t) == "string" and t ~= "" then return t end
  return tostring(v)
end

local ort = { tag = nil, seit = 0.0, wohnung = false, drin = false,
              judySeit = 0.0, judyStill = 0.0, letztePos = nil, an = true }

local function ortTick(d)
  local tag = cnameText(ktx.nca.ort)
  if tag == "None" or tag == "" then tag = nil end
  local drin = tag ~= nil

  if tag ~= ort.tag then
    if ort.tag then
      log(string.format("ORT verlassen: %s nach %.0f s",
          ORTSNAMEN[ort.tag] or ort.tag, ort.seit))
    end
    if tag then
      log(string.format("ORT betreten: %s%s", ORTSNAMEN[tag] or tag,
          WOHNUNGEN[tag] and "   (Wohnung)" or ""))
    end
    ort.tag, ort.seit = tag, 0.0
    ort.wohnung = tag ~= nil and WOHNUNGEN[tag] == true
    ort.drin = drin
    ort.judySeit, ort.judyStill, ort.letztePos = 0.0, 0.0, nil
    return
  end
  if not tag then return end
  ort.seit = ort.seit + d

  --  Was tut sie drinnen? NCA setzt sie dort von selbst auf die Couch, und das wollen wir
  --  nicht verdraengen, sondern begleiten. Wie lange sie am Stueck stillsteht, ist der
  --  beste Anhaltspunkt dafuer, dass sie sich niedergelassen hat.
  local o = judyHolen()
  if not o then return end
  local pos
  pcall(function() pos = o:GetWorldPosition() end)
  if pos and ort.letztePos then
    local weit = 0.0
    pcall(function() weit = Vector4.Distance(pos, ort.letztePos) end)
    if weit < 0.15 then
      ort.judyStill = ort.judyStill + d
    else
      if ort.judyStill > 20.0 then
        log(string.format("ORT sie hat sich nach %.0f s wieder bewegt", ort.judyStill))
      end
      ort.judyStill = 0.0
    end
  end
  ort.letztePos = pos

  ort.judySeit = ort.judySeit + d
  if ort.judySeit >= 20.0 then
    ort.judySeit = 0.0
    log(string.format("ORT %s: %.0f s drin, Judy %s m weg, steht seit %.0f s still",
        ORTSNAMEN[ort.tag] or ort.tag, ort.seit,
        judy.dist and string.format("%.1f", judy.dist) or "?", ort.judyStill))
  end
end

--  Fuer Phase 3: erlaubt der Ort einen anderen Umgangston?
function T.InWohnung() return ort.wohnung end
function T.OrtTag()   return ort.tag end

--  ---------------------------------------------------------------- Wunden
--
--  Der gebueckte Gang mit haengendem Arm ist ein STATUSEFFEKT, kein Animationszustand
--  und keine Lage. Das erklaert alles, was uns daran verwirrt hat:
--
--  * Die Lage steht auf `Relaxed`, nie auf `Wounded` - gemessen, deshalb war die Spur
--    ueber `ChangeHighLevelState` von vornherein aussichtslos.
--  * Volle Gesundheit loest ihn nicht, weil er nicht an der Gesundheit haengt.
--  * Schnellreise loest ihn, weil sie dabei neu gespawnt wird - ein neuer Koerper hat
--    keine Effekte.
--  * Sie sprintet nicht mehr, weil der Effekt ihre Fortbewegung beschneidet.
--
--  Und Statuseffekte lassen sich entfernen. `gamedataStatusEffectType.Wounded` ist der
--  Typ, den auch die KI abfragt (`CheckWoundedStatusEffectState`).
--  Geloest wird ab 80 %, und zwar SOLANGE sie darueber ist - nicht an einem einzelnen
--  Uebergang. Zwei feste Punkte, etwa 80 und 100, koennen beide verpasst werden: faellt sie
--  waehrend des Heilens noch einmal unter die Schwelle, ist der Uebergang verbraucht und
--  kommt nie wieder. Eine laufende Pruefung kann nichts durchrutschen lassen.
--
--  80 statt 100, weil zusammengeflickt nicht makellos heissen muss - und weil sie die
--  letzten Prozent unter Beschuss womoeglich nie erreicht.
local WUNDE = { an = true, abHp = 80.0, takt = 5.0 }
local wunde = { hat = nil, entfernt = 0, versuche = 0, seit = 0.0,
                fehler = nil, gemeldet = false }

local function wundeLesen(o)
  local v
  pcall(function()
    v = StatusEffectSystem.ObjectHasStatusEffectOfType(o, gamedataStatusEffectType.Wounded)
  end)
  return v
end

--  Zwei Signaturen im Umlauf: einmal `(owner, typ)`, einmal `(game, id, typ)`. Beide
--  einzeln versuchen und melden, welche gegriffen hat - zusammengefasst wuesste man
--  hinterher wieder nicht, welche Haelfte es war.
local function wundeEntfernen(o)
  local weg = false
  local ok = pcall(function()
    StatusEffectHelper.RemoveAllStatusEffectsByType(o, gamedataStatusEffectType.Wounded)
    weg = true
  end)
  if not ok or not weg then
    ok = pcall(function()
      StatusEffectHelper.RemoveAllStatusEffectsByType(
        Game.GetPlayer():GetGame(), o:GetEntityID(), gamedataStatusEffectType.Wounded)
      weg = true
    end)
  end
  if not weg then return false, "keine der beiden Signaturen griff" end
  local nachher = wundeLesen(o)
  return nachher == false, string.format("danach %s", tostring(nachher))
end

--  ---------------------------------------------------------------- Heilung
--
--  NCA heilt Begleiter ueberhaupt nicht. Es gibt eine Lebensanzeige und nichts dahinter -
--  ihre Gesundheit kam bisher nur durch einen Respawn zurueck, also praktisch nur nach
--  Schnellreise. Wer laenger mit ihr unterwegs ist, laeuft mit einer dauerhaft
--  angeschlagenen Judy herum, und das ist keine Design-Entscheidung, sondern eine Luecke.
--
--  Erste Fassung bewusst stumpf: fester Zuwachs ausserhalb des Kampfes. Das richtige
--  System - ihr Medikamente geben, Verhalten bei niedrigem Leben - steht auf der Liste.
--
--  Die Frage, die dieser Bau beantworten soll: heilt das auch den GLIEDMASSENSCHADEN? Die
--  gebueckte, blutende Haltung kommt aus `hitReactionComponent`, wird beim Treffer gesetzt
--  und hat im Vanilla-Code keinen Rueckweg. Wenn volle Gesundheit sie nicht loest, brauchen
--  wir dafuer etwas anderes - und dann wissen wir es, statt es anzunehmen.
local HEILUNG = { takt = 1.0, proSekunde = 2.0, ruheNachKampf = 5.0, voll = 99.5 }
local heil = { an = true, seit = 0.0, ruhe = 0.0, war = nil,
               gemeldet = false, fehler = nil, hp = nil }

local function heilungTick(d, o)
  if not heil.an then return end

  --  Im Kampf nicht, und ein paar Sekunden danach auch nicht: sonst heilt sie sich
  --  mitten im Gefecht wieder hoch und der Kampf verliert sein Gewicht.
  if ktx.eigen.kampf then heil.ruhe = 0.0; return end
  heil.ruhe = heil.ruhe + d
  if heil.ruhe < HEILUNG.ruheNachKampf then return end

  heil.seit = heil.seit + d
  if heil.seit < HEILUNG.takt then return end
  local dt = heil.seit
  heil.seit = 0.0
  if not o then return end

  local hp
  pcall(function()
    hp = Game.GetStatPoolsSystem():GetStatPoolValue(o:GetEntityID(),
                                                   gamedataStatPoolType.Health, true)
  end)
  if hp == nil then
    if not heil.gemeldet then
      heil.gemeldet = true
      log("HEILUNG ihre Gesundheit ist nicht lesbar - Regeneration bleibt aus")
    end
    return
  end
  heil.hp = hp

  --  Der Wundeffekt haengt NICHT am Heilungsuebergang, sondern nur an der Schwelle. So
  --  ist er auch dann noch zu erwischen, wenn sie zwischendurch wieder getroffen wurde.
  if WUNDE.an and hp >= WUNDE.abHp then
    wunde.seit = wunde.seit + dt
    if wunde.seit >= WUNDE.takt then
      wunde.seit = 0.0
      if wundeLesen(o) == true then
        local ok, wie = wundeEntfernen(o)
        wunde.versuche = wunde.versuche + 1
        if ok then wunde.entfernt = wunde.entfernt + 1 end
        --  Nicht jeden Versuch melden - bei einem dauerhaft misslingenden Aufruf stuende
        --  sonst alle fuenf Sekunden dieselbe Zeile im Log.
        if ok or wunde.versuche <= 3 or wunde.versuche % 20 == 0 then
          log(string.format("WUNDE bei %.0f%% entfernen: %s - %s (Versuch %d)",
              hp, ok and "geloest" or "blieb", wie, wunde.versuche))
        end
        if not ok then wunde.fehler = wie end
      end
    end
  else
    wunde.seit = WUNDE.takt   -- unter der Schwelle: beim Ueberschreiten sofort pruefen
  end

  if hp >= HEILUNG.voll then
    if heil.war ~= nil and heil.war < HEILUNG.voll then
      log(string.format("HEILUNG voll (war %.0f%%)", heil.war))
    end
    heil.war = hp
    return
  end
  if heil.war == nil or heil.war >= HEILUNG.voll then
    log("HEILUNG Lage beim Beginn: " .. select(2, lageLesen(o)))
  end

  if heil.war == nil or heil.war >= HEILUNG.voll then
    log(string.format("HEILUNG beginnt bei %.0f%%", hp))
  end

  --  `RequestChangingStatPoolValue(objID, typ, diff, ausloeser, chunkTransfer, prozent)`.
  --  Der fuenfte ist NICHT `perc` - das ist der sechste. Vertauscht heilt sie um 2 Punkte
  --  statt 2 Prozent, was bei 343 Punkten Gesamtleben fast wirkungslos waere.
  local ok, fehler = pcall(function()
    Game.GetStatPoolsSystem():RequestChangingStatPoolValue(
      o:GetEntityID(), gamedataStatPoolType.Health,
      HEILUNG.proSekunde * dt, nil, false, true)
  end)
  if not ok and heil.fehler ~= tostring(fehler) then
    heil.fehler = tostring(fehler)
    log("HEILUNG Aufruf fehlgeschlagen: " .. tostring(fehler))
  end
  heil.war = hp
end

--  ---------------------------------------------------------------- Blickkontakt
--
--  Sie dreht sich zu V, dann spricht sie. Jede Zeile wirkt dadurch adressiert statt in
--  den Raum gesprochen. Den Lebenszyklus besitzt der SPRECHER, nicht dieser Ausloeser -
--  bei konkurrierenden Anfragen liefen sonst mehrere Abschalt-Uhren gegeneinander, und
--  genau das zu verhindern ist der Sinn des Sprechers.
--
--  Zwei Dinge aus dem Vanilla-Code formen den Bau:
--
--  * Der Aufruf liefert `false`, wenn ihre Lage `Combat` ist. Im Gefecht gibt es keinen
--    Blick, und das ist eine Entscheidung des Spiels, keine Panne.
--  * Die uebergebene Dauer ist nur der ERSATZWERT fuer
--    `AIGeneralSettings.reactionLookAtDuration`. Existiert der Eintrag, wird unserer
--    verworfen - NCA uebergibt 1.0 und bekommt vermutlich etwas ganz anderes. Deshalb
--    lesen wir den echten Wert und frischen selbst nach, statt uns darauf zu verlassen.
local blick = { dauer = nil, gemeldet = false, fehler = nil, letzte = nil }

local function blickDauer()
  if blick.dauer ~= nil then return blick.dauer end
  local v
  pcall(function()
    v = TweakDB:GetFlat(TweakDBID.new("AIGeneralSettings.reactionLookAtDuration"))
  end)
  blick.dauer = (type(v) == "number") and v or 5.0
  log(string.format("BLICKKONTAKT TweakDB-Dauer: %s (%s)", tostring(v),
      (type(v) == "number") and "gelesen" or "Ersatzwert 5.0"))
  return blick.dauer
end

function T.Blick(obj, dauer)
  local p = spieler()
  if not p then return nil end
  local o = obj or judyHolen()
  if not o then return nil end

  --  Getrennte pcalls. Zusammengefasst hiesse eine Fehlmeldung nur "irgendwas davon",
  --  und daran haben wir uns in diesem Projekt schon viermal die Zaehne ausgebissen.
  local stim
  pcall(function() stim = o:GetStimReactionComponent() end)
  if not stim then
    if not blick.gemeldet then
      blick.gemeldet = true
      log("BLICKKONTAKT GetStimReactionComponent fehlt - kein Blick")
    end
    return nil
  end

  local ok, r = pcall(function()
    return stim:ActivateReactionLookAt(p, false, false, dauer or 3.0, false, false)
  end)
  if not ok then
    if blick.fehler ~= tostring(r) then
      blick.fehler = tostring(r)
      log("BLICKKONTAKT Aufruf fehlgeschlagen: " .. tostring(r))
    end
    return nil
  end

  blick.letzte = r
  --  Zweiter Rueckgabewert: wie lange der Blick wirklich haelt. Der Sprecher richtet sein
  --  Auffrischen danach, statt auf Verdacht zu takten.
  if not blick.gemeldet then
    blick.gemeldet = true
    log(string.format("BLICKKONTAKT erster Aufruf - Rueckgabe %s, echte Dauer %.1fs",
        tostring(r), blickDauer()))
  end
  return r, blickDauer()
end

--  ------------------------------------------------ Haltung: mitlesen statt weiterraten
--
--  Im Kampf geht sie von selbst in Deckung und in die Hocke. Ihr Animationsgraph kann es
--  also - nur nicht ueber den Weg, den wir gehen. Damit ist Wege-Raten der falsche Zug.
--  Das Spiel fuehrt es uns vor; wir lesen mit, WAS sich dabei an ihr aendert.


--  Jeder Wert einzeln und einzeln abgesichert. Faellt einer aus, steht dort ein Strich,
--  und die anderen sagen trotzdem etwas.
local FELDER = {
  { "Haltung",  function(o) return haltungLesen(o) end },
  { "bbStance", function(o) return bbLesen(o, "Stance") end },
  { "Lage",     function(o) local _, t = lageLesen(o); return t end },
  { "bbUpper",  function(o) return bbLesen(o, "UpperBody") end },
  { "bbLoco",   function(o) return bbLesen(o, "LocomotionMode") end },
  { "bbHitRe",  function(o) return bbLesen(o, "HitReactionMode") end },
  { "bbDefense",function(o) return bbLesen(o, "DefenseMode") end },
  { "bbBehav",  function(o) return bbLesen(o, "BehaviorState") end },
  { "Kampf",    function(o) return o:IsInCombat() end },
  { "Deckung",  function(o) return o:IsInCover() end },
  { "Waffe",    function(o) return o:HasAnyWeaponEquipped() end },
  { "Tempo",    function(o) return string.format("%.1f", Vector4.Length(o:GetVelocity())) end },
}

local beob = { an = false, takt = 0.0, vorher = nil }

local function probeNehmen(o)
  local pr = {}
  for _, f in ipairs(FELDER) do
    local v
    pcall(function() v = f[2](o) end)
    pr[f[1]] = (v == nil) and "-" or tostring(v)
  end
  return pr
end

local function probeSchreiben(kopf, pr)
  log("PROBE " .. kopf)
  for _, f in ipairs(FELDER) do
    log(string.format("   %-9s %s", f[1], pr[f[1]]))
  end
end

--  Nur Aenderungen melden. Waehrend eines Gefechts stuende sonst alle 0.4s dasselbe im
--  Log und die eine Zeile, auf die es ankommt, ginge darin unter.
local function beobTick(d)
  if not beob.an then return end
  beob.takt = beob.takt + d
  if beob.takt < 0.4 then return end
  beob.takt = 0.0
  local o = judyHolen()
  if not o then return end
  local jetzt = probeNehmen(o)
  if not beob.vorher then
    beob.vorher = jetzt
    probeSchreiben("Ausgangslage", jetzt)
    return
  end
  local aend = {}
  for _, f in ipairs(FELDER) do
    local n = f[1]
    if jetzt[n] ~= beob.vorher[n] then
      aend[#aend + 1] = string.format("%s %s -> %s", n, beob.vorher[n], jetzt[n])
    end
  end
  if #aend > 0 then log("PROBE " .. table.concat(aend, " | ")) end
  beob.vorher = jetzt
end

--  Die Ebene UEBER der Haltung. Der Verdacht: in `Relaxed` hat ihr Graph gar keinen
--  Hock-Zustand, deshalb bleibt der gesetzte Wert unbenutzt liegen. Im Kampf setzt die KI
--  beides - Lage UND Haltung - und dann sieht man es.
local function lageSetzen(o, name)
  local ok, fehler = pcall(function()
    NPCPuppet.ChangeHighLevelState(o, Enum.new("gamedataNPCHighLevelState", name))
  end)
  if ok then return true, "Lage " .. name end
  return false, "Lage " .. name .. " fehlt: " .. tostring(fehler)
end

local HWEGE = {
  { name = "1 NPCPuppet.ChangeStanceState", fn = function(o, st)
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", st))
      return "aufgerufen"
    end },
  { name = "2 Signaltabelle (Puppet)", fn = function(o, st)
      local tbl = o:GetSignalTable()
      if not tbl then return "keine Tabelle" end
      local sig = NewObject("NPCStateChangeSignal")
      sig.m_stanceState = Enum.new("gamedataNPCStanceState", st)
      sig.m_stanceStateValid = true
      local id = tbl:GetOrCreateSignal(CName.new("NPCStateChangeSignal"))
      tbl:Set(id, false)
      tbl:SetWithData(id, sig)
      return "gesendet"
    end },
  { name = "3 Signaltabelle (AI-Controller)", fn = function(o, st)
      local tbl = o:GetAIControllerComponent():GetSignals()
      if not tbl then return "keine Tabelle" end
      local sig = NewObject("NPCStateChangeSignal")
      sig.m_stanceState = Enum.new("gamedataNPCStanceState", st)
      sig.m_stanceStateValid = true
      local id = tbl:GetOrCreateSignal(CName.new("NPCStateChangeSignal"))
      tbl:Set(id, false)
      tbl:SetWithData(id, sig)
      return "gesendet"
    end },
  { name = "4 Empfaenger direkt", fn = function(o, st)
      local sig = NewObject("NPCStateChangeSignal")
      sig.m_stanceState = Enum.new("gamedataNPCStanceState", st)
      sig.m_stanceStateValid = true
      o:GetStatesComponent():OnNPCStateChangeSignalReceived(sig)
      return "zugestellt"
    end },
  { name = "5 SetCurrentStanceState", fn = function(o, st)
      local r = o:GetStatesComponent():SetCurrentStanceState(
                  Enum.new("gamedataNPCStanceState", st))
      return "Rueckgabe " .. tostring(r)
    end },
  { name = "6 SetReplicatedStanceState", fn = function(o, st)
      --  2 = Crouch, 3 = Stand. Der Bool ist der Wert, den alles andere verschluckt.
      local r = o:GetStatesComponent():SetReplicatedStanceState((st == "Crouch") and 2 or 3)
      return "Rueckgabe " .. tostring(r)
    end },
  { name = "7 Anim-Feature + Wrapper", fn = function(o, st)
      --  Jeder Aufruf einzeln mit seinem Rueckgabewert. "angewandt" fuer beides zusammen
      --  hiess nur, dass nichts geworfen hat, und das ist keine Auskunft.
      local feat = NewObject("animAnimFeature_NPCState")
      if not feat then return "Feature nicht baubar" end
      feat.state = (st == "Crouch") and 2 or 3
      local a = AnimationControllerComponent.ApplyFeature(o, CName.new("stanceState"), feat)
      local b = AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(
                  o, CName.new("inCrouch"), (st == "Crouch") and 1.0 or 0.0)
      return string.format("Feature=%s state=%s Wrapper=%s",
                           tostring(a), tostring(feat.state), tostring(b))
    end },
  { name = "11 Anim-Feature 3s lang halten", fn = function(o, st)
      --  Ein einzelner Anwurf koennte vom naechsten Durchlauf der NPC-Zustandsmaschine
      --  sofort ueberschrieben werden. Wenn Halten wirkt und Setzen nicht, wissen wir das.
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", st))
      haltung.halten = { o = o, st = st, rest = 3.0 }
      return "halte 3s"
    end },
  { name = "9 Zustand + Anim zusammen", fn = function(o, st)
      --  `UpdateStanceState` macht beides nacheinander. Route 1 sollte das intern tun -
      --  falls nicht, holt das hier es nach.
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", st))
      local feat = NewObject("animAnimFeature_NPCState")
      feat.state = (st == "Crouch") and 2 or 3
      AnimationControllerComponent.ApplyFeature(o, CName.new("stanceState"), feat)
      AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(
        o, CName.new("inCrouch"), (st == "Crouch") and 1.0 or 0.0)
      return "beides"
    end },
  { name = "10 Zustand, dann 3s nachmessen", fn = function(o, st)
      --  Bleibt der Zustand stehen, oder dreht die KI ihn zurueck? Der Einzelmesswert
      --  direkt nach dem Setzen sagt das nicht.
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", st))
      haltung.nachmessen = { o = o, rest = 3.0, takt = 0.0 }
      return "messe 3s nach"
    end },
  { name = "12 Lage Combat, dann Hocke", fn = function(o, st)
      local _, m = lageSetzen(o, "Combat")
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", st))
      return m
    end },
  { name = "13 Lage Alerted, dann Hocke", fn = function(o, st)
      local _, m = lageSetzen(o, "Alerted")
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", st))
      return m
    end },
  { name = "14 Lage Stealth, dann Hocke", fn = function(o, st)
      local _, m = lageSetzen(o, "Stealth")
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", st))
      return m
    end },
  { name = "15 Lage Relaxed (Rueckweg)", fn = function(o, st)
      --  Der Rueckweg aus der Hocke. Nicht die Haltung, die Lage.
      local _, m = lageSetzen(o, "Relaxed")
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState", "Stand"))
      return m
    end },
  { name = "8 Cover statt Crouch", fn = function(o, st)
      NPCPuppet.ChangeStanceState(o, Enum.new("gamedataNPCStanceState",
                                              (st == "Crouch") and "Cover" or "Stand"))
      return "aufgerufen"
    end },
}

--  Was gibt es ueberhaupt? Bisher habe ich Namen aus dem Skript-Dump geraten, und die
--  RTTI kennt nicht jeden davon - `AnimFeature_NPCState` gegen `animAnimFeature_NPCState`
--  hat uns das schon vorgefuehrt. Hier fragen wir die laufende RTTI selbst.
local RTTI_KLASSEN = { "ScriptedPuppet", "NPCPuppet", "npcStateComponent", "gamePuppet",
                       "AnimationControllerComponent", "AIHumanComponent", "AIComponent" }
local RTTI_MUSTER  = { "stance", "crouch", "stealth", "cover", "locomotion", "movement",
                       "highlevel", "state" }

local function enumZeigen(name, bis)
  local teile = {}
  for i = 0, bis do
    local ok, txt = pcall(function() return tostring(Enum.new(name, i)) end)
    if ok and txt and txt ~= "" then teile[#teile + 1] = i .. "=" .. txt end
  end
  log("ENUM " .. name .. ": " .. table.concat(teile, "  "))
end

function T.HaltungRTTI()
  for _, kn in ipairs(RTTI_KLASSEN) do
    local ok, fehler = pcall(function()
      local c = Reflection.GetClass(kn)
      if not c then log("RTTI " .. kn .. " - unbekannt"); return end
      local treffer = {}
      for _, liste in ipairs({ c:GetFunctions(), c:GetStaticFunctions() }) do
        for _, f in ipairs(liste) do
          local n = tostring(f:GetName())
          local klein = string.lower(n)
          for _, m in ipairs(RTTI_MUSTER) do
            if string.find(klein, m, 1, true) then treffer[#treffer + 1] = n; break end
          end
        end
      end
      log(string.format("RTTI %s - %d Treffer", kn, #treffer))
      for _, n in ipairs(treffer) do log("   " .. n) end
    end)
    if not ok then log("RTTI " .. kn .. " - Fehler: " .. tostring(fehler)) end
  end

  local ok, fehler = pcall(function()
    local c = Reflection.GetClass("PuppetStateDef")
    if not c then log("RTTI PuppetStateDef - unbekannt"); return end
    local namen = {}
    for _, pr in ipairs(c:GetProperties()) do
      namen[#namen + 1] = tostring(pr:GetName())
    end
    log("RTTI PuppetStateDef - Felder: " .. table.concat(namen, ", "))
  end)
  if not ok then log("RTTI PuppetStateDef - Fehler: " .. tostring(fehler)) end

  enumZeigen("gamedataNPCStanceState", 6)
  enumZeigen("gamedataNPCHighLevelState", 8)
  enumZeigen("gamedataNPCUpperBodyState", 8)
  enumZeigen("moveMovementType", 8)
end

function T.Probe()
  local o = judyHolen()
  if not o then log("PROBE Judy nicht greifbar"); return end
  probeSchreiben("Momentaufnahme", probeNehmen(o))
end

function T.Beobachten(an)
  beob.an = an and true or false
  beob.vorher = nil
  log("PROBE Beobachtung " .. (beob.an and "an" or "aus"))
end

function T.HaltungWege()
  local out = {}
  for i, w in ipairs(HWEGE) do out[i] = w.name end
  return out
end

function T.HaltungTest(i, hocken)
  local w = HWEGE[i]
  if not w then return end
  local o = judyHolen()
  if not o then log("HTEST Judy nicht greifbar"); return end
  local st = hocken and "Crouch" or "Stand"
  local vorher = haltungLesen(o)
  local ergebnis
  local ok = pcall(function() ergebnis = w.fn(o, st) end)
  local nachher = haltungLesen(o)
  log(string.format("HTEST %s -> %s | %s | vorher %s, nachher %s",
      w.name, st, ok and tostring(ergebnis) or "FEHLER",
      tostring(vorher), tostring(nachher)))
end

--  Laeuft nach einem Test drei Sekunden mit und schreibt den echten Zustand mit. Ein
--  Wert direkt nach dem Setzen sagt nur, dass er ankam - nicht, ob er bleibt.
local function nachmessen(d)
  local n = haltung.nachmessen
  if not n then return end
  n.rest = n.rest - d
  n.takt = n.takt + d
  if n.takt >= 0.5 then
    n.takt = 0.0
    log(string.format("   nachher %.1fs: %s", 3.0 - n.rest, tostring(haltungLesen(n.o))))
  end
  if n.rest <= 0.0 then haltung.nachmessen = nil end
end

--  Legt das Anim-Feature in jedem Frame neu auf, drei Sekunden lang.
local function halten(d)
  local h = haltung.halten
  if not h then return end
  h.rest = h.rest - d
  if h.rest <= 0.0 then
    haltung.halten = nil
    log(string.format("   gehalten bis Ende, Zustand jetzt %s", tostring(haltungLesen(h.o))))
    return
  end
  local feat = NewObject("animAnimFeature_NPCState")
  if not feat then haltung.halten = nil; return end
  feat.state = (h.st == "Crouch") and 2 or 3
  AnimationControllerComponent.ApplyFeature(h.o, CName.new("stanceState"), feat)
  AnimationControllerComponent.SetAnimWrapperWeightOnOwnerAndItems(
    h.o, CName.new("inCrouch"), (h.st == "Crouch") and 1.0 or 0.0)
end

--  Die Haltung mitschreiben, unabhaengig davon, ob wir sie gerade steuern. Nach einer
--  Autofahrt lief sie bei voller Gesundheit wieder gebueckt, und ohne diesen Verlauf ist
--  nicht zu unterscheiden, ob dort `Vehicle` (5) haengengeblieben ist, `Crouch` (2) nicht
--  zurueckkam oder es etwas Drittes war.
local HALTUNGSNAMEN = { [0] = "Any", [1] = "Cover", [2] = "Crouch", [3] = "Stand",
                        [4] = "Swim", [5] = "Vehicle", [6] = "VehicleWindow" }

local function haltungText(o)
  local v = haltungLesen(o or judyHolen())
  if v == nil then return "?" end
  local n = tonumber(tostring(v))
  return (n and HALTUNGSNAMEN[n] or tostring(v)) .. " (" .. tostring(v) .. ")"
end

--  Die Lage ist es NICHT - gemessen: Relaxed, Combat, Unconscious, nie `Wounded`. Der
--  gebueckte Gang mit haengendem Arm muss also in einem der uebrigen Zustandsfelder
--  stehen. Statt dich Knoepfe druecken zu lassen, waehrend sie so laeuft, beobachten wir
--  die vier hier mit und melden jeden Wechsel.
local ZUSTANDSFELDER = { "LocomotionMode", "HitReactionMode", "DefenseMode",
                         "BehaviorState", "UpperBody", "PhaseState" }

local hbeo = { war = nil, lageWar = nil, seit = 0.0, felder = {} }

local function haltungMitschreiben(d)
  hbeo.seit = hbeo.seit + d
  if hbeo.seit < 0.4 then return end
  hbeo.seit = 0.0
  local o = judyHolen()
  if not o then hbeo.war = nil; return end
  --  Lage und Haltung sind zwei Regler. Die Wunde zeigt sich, wenn ueberhaupt, an der
  --  Lage - deshalb beide beobachten und beide melden.
  local lv, lt = lageLesen(o)
  if lv ~= nil and lv ~= hbeo.lageWar then
    if hbeo.lageWar ~= nil then
      log(string.format("LAGE-IST %s -> %s   unser Ziel %s, Wagen %s, Kampf %s",
          tostring(LAGENAMEN[hbeo.lageWar] or hbeo.lageWar), lt,
          tostring(haltung.ziel), tostring(ktx.eigen.wagen), tostring(ktx.eigen.kampf)))
    else
      log("LAGE-IST erste Messung: " .. lt)
    end
    hbeo.lageWar = lv
  end

  local am = liegtAmBoden(o)
  if am ~= nil and am ~= liegen.hat then
    if liegen.hat ~= nil then
      log(string.format("LIEGT %s   Lage %s, Kampf %s",
          am and "sie geht zu Boden" or "sie steht wieder", lt,
          tostring(ktx.eigen.kampf)))
    end
    liegen.hat = am
  end

  local w = wundeLesen(o)
  if w ~= nil and w ~= wunde.hat then
    if wunde.hat ~= nil then
      log(string.format("WUNDE %s   Lage %s, Kampf %s",
          w and "aufgetreten" or "verschwunden", lt, tostring(ktx.eigen.kampf)))
    end
    wunde.hat = w
  end

  for _, feld in ipairs(ZUSTANDSFELDER) do
    local fv = bbLesen(o, feld)
    if fv ~= nil and fv ~= hbeo.felder[feld] then
      if hbeo.felder[feld] ~= nil then
        log(string.format("ZUSTAND %s: %s -> %s   Lage %s, Kampf %s",
            feld, tostring(hbeo.felder[feld]), tostring(fv), lt,
            tostring(ktx.eigen.kampf)))
      end
      hbeo.felder[feld] = fv
    end
  end

  local v = haltungLesen(o)
  if v == nil or v == hbeo.war then return end
  if hbeo.war ~= nil then
    log(string.format("HALTUNG-IST %s -> %s   Lage %s, Ziel %s, Wagen %s, Kampf %s",
        tostring(hbeo.war), haltungText(o), lt, tostring(haltung.ziel),
        tostring(ktx.eigen.wagen), tostring(ktx.eigen.kampf)))
  end
  hbeo.war = v
end

local function haltungTick(d)
  if not haltung.an then return end
  haltung.seit = haltung.seit + d
  if haltung.seit < HALTUNG.takt then return end
  haltung.seit = 0.0

  local o = judyHolen()
  if not o then haltung.ziel, haltung.ist = nil, nil; return end

  --  Im Kampf gehoert die Lage NCA, nicht uns.
  --
  --  NCA umhaengt `PlayerPuppet.OnCombatStateChanged` und setzt in `CombatBehavior` selbst
  --  `ChangeHighLevelState(Combat)` beim Beginn und `Relaxed` beim Ende - derselbe Regler,
  --  an dem wir drehen. Entscheidend ist, woran es haengt: an **Vs** Kampfzustand, nicht an
  --  ihrem. Fragten wir hier `o:IsInCombat()`, benutzten wir eine andere Grenze als der Mod,
  --  mit dem wir uns den Regler teilen - und genau in der Luecke dazwischen wuerden wir sein
  --  `Combat` mit unserem `Relaxed` ueberschreiben, waehrend sie in Deckung geht.
  --  Also dasselbe Signal wie NCA, plus ihres als Netz.
  local imKampf = psm("Combat") == 1
  if not imKampf then pcall(function() imKampf = o:IsInCombat() end) end
  if imKampf then
    if haltung.ziel then
      log("HALTUNG Kampf - Lage wieder an die KI abgegeben")
      haltung.ziel = nil
    end
    return
  end

  --  gamePSMLocomotionStates: 1 Crouch, 11 CrouchSprint, 12 CrouchDodge
  local lok = psm("Locomotion")
  local hockt = lok == 1 or lok == 11 or lok == 12
  local ziel = hockt and LAGEN.hocke or LAGEN.normal
  haltung.ist = haltungLesen(o)

  if ziel ~= haltung.ziel then
    local ok, text = lageSetzen(o, ziel)
    haltungSetzen(o, hockt and STANCE.Crouch or STANCE.Stand)
    if not ok then
      log("HALTUNG " .. text)
      return
    end
    haltung.gesetzt = haltung.gesetzt + 1
    haltung.ziel = ziel
    haltung.auffrisch = 0.0
    log(string.format("HALTUNG Lage %s - V %s", ziel, hockt and "hockt" or "steht"))
    return
  end

  --  Nur die Hocke wird aufgefrischt. `Relaxed` immer wieder nachzusetzen hiesse, ihr den
  --  Weg in den Kampf zu verstellen - und der gehoert ihr.
  if ziel == LAGEN.hocke then
    haltung.auffrisch = haltung.auffrisch + HALTUNG.takt
    if haltung.auffrisch >= HALTUNG.auffrischen then
      haltung.auffrisch = 0.0
      haltung.aufgefrischt = haltung.aufgefrischt + 1
      lageSetzen(o, ziel)
      haltungSetzen(o, STANCE.Crouch)
    end
  end
end

--  ---------------------------------------------------------------- Judys eigene Stimme

--  Die Spiel-KI laesst Judy im Gefecht selbst reden - dieselbe Voiceset-Infrastruktur, die
--  wir benutzen. Wer da dazwischenspricht, ersetzt ihre Zeile statt sie zu ergaenzen.
--
--  Eine direkte Abfrage "spricht sie gerade" gibt es nicht. Was es gibt, ist der
--  Untertitel: `UIGameData.ShowDialogLine` fuehrt die zuletzt gezeigte Zeile samt Sprecher
--  und Dauer. Erscheint dort eine Zeile von ihr, waehrend WIR nichts gestartet haben, war
--  es die KI.
--
--  Nebenbei loest das ein zweites Problem: laeuft eine unserer Zeilen, ist der Sprecher im
--  Untertitel zwangslaeufig sie - so lernen wir ihre Entity-Id, ohne sie ansehen zu muessen.
local stimme = { judyId = nil, letzter = "", zuletztFremd = "-" }

--  Ihre eigenen Barks sammeln.
--
--  Bisher standen sie nur im Log - und der rotiert. Die Zeilen aus der Nacht sind weg,
--  darunter "Bin bei dir." und "Achtung!", genau die, die zur Kampf-Uebernahme gehoeren.
--  Fuer die Besitzmatrix aus Phase 4 brauchen wir aber einen Bestand, der Sitzungen
--  ueberdauert: welche Zeile sagt sie von selbst, wie oft, wie lang.
--
--  Also eine eigene Datei neben dem Log, die nur waechst. Klassifiziert wird spaeter von
--  Hand - welche Situation, und ob wir dort ergaenzen, ersetzen oder schweigen.
local FREMD_DATEI = "fremde_zeilen.txt"
local fremde = { }        -- Text -> { anzahl, dauer }
local fremdeAnzahl = 0

local function fremdMerken(text, dauer)
  local e = fremde[text]
  if e then
    e.anzahl = e.anzahl + 1
    return
  end
  fremde[text] = { anzahl = 1, dauer = dauer or 0 }
  fremdeAnzahl = fremdeAnzahl + 1
  --  Nur beim ERSTEN Auftreten schreiben. Anhaengen statt neu schreiben, damit frueher
  --  Gesammeltes nicht verlorengeht, wenn das Spiel abstuerzt.
  pcall(function()
    local f = io.open(FREMD_DATEI, "a")
    if not f then return end
    f:write(string.format("%.1fs  %s", dauer or 0, text) .. "\n")
    f:close()
  end)
end

local function stimmeTick()
  if not letzteZeile then return end
  local dl = letzteZeile()
  if not dl or dl.text == "" or dl.text == stimme.letzter then return end
  stimme.letzter = dl.text

  --  Frueher wurde hier ihr Entity-Hash gelernt, sobald eine unserer Zeilen lief. Das
  --  ging schief: erscheint in diesem Moment ein fremder Untertitel - eine Werbetafel
  --  reicht -, wird dessen Sprecher als Judy gemerkt, und danach sperrt uns jede Reklame.
  --  Im Protokoll stand dann "Judy spricht selbst: Kumquat fuer die Seele."
  --
  --  Es gibt eine sichere Pruefung, und die stand schon da: die Record-Id.
  if not istJudy(dl.obj) then return end
  judyMerken(dl.obj)
  pcall(function() stimme.judyId = tostring(dl.obj:GetEntityID().hash) end)
  if Speaker.Spricht() then return end

  Speaker.Fremd(dl.dur)
  stimme.zuletztFremd = dl.text
  fremdMerken(dl.text, dl.dur)
  log(string.format("FREMD Judy spricht selbst (%.1fs): %s", dl.dur or 0, dl.text))
end

--  ---------------------------------------------------------------- Der lange Blick

local GAZE = {
  stufe1  =   10.0,   -- ab hier merkt sie es
  stufe2  =   30.0,   -- ab hier nimmt sie es auf
  stufe3  =   75.0,   -- so lange sieht man niemanden aus Versehen an
  cd1     =  300.0,   -- Abklingzeit der beilaeufigen Reaktion
  cd2     = 1800.0,   -- die zweite Ebene hoechstens halbstuendlich
  cd3     = 3600.0,   -- die dritte einmal pro Stunde
  distanz =    8.0,   -- ueber die Strasse hinweg ist kein Anschauen
}
--  s1/s2 gehoeren dem Blick: sie verhindern, dass er innerhalb EINES Blicks nachlegt.
--  Belegt-Sein und Abklingzeiten fuehrt der Sprecher.
local gaze = { t = 0.0, id = nil, s1 = false, s2 = false, s3 = false,
               an = true, zuletzt = "-" }

local function gazeFeuern(obj)
  --  Dritte Stufe: so lange sieht man niemanden aus Versehen an. Sie zieht aus dem
  --  Flirt-Pool und nur, wenn die Beziehung das traegt.
  local stufe
  if not gaze.s3 and gaze.t >= GAZE.stufe3 and verliebtGenug() then
    stufe = 3
  elseif not gaze.s2 and gaze.t >= GAZE.stufe2 then
    stufe = 2
  elseif not gaze.s1 and gaze.t >= GAZE.stufe1 then
    stufe = 1
  end
  if not stufe then return end

  --  Ob angenommen oder nicht: innerhalb dieses Blicks nicht noch einmal anfragen. Ohne
  --  das stellt der Ausloeser in jedem Frame denselben Antrag, solange V hinsieht.
  gaze.s1 = true
  if stufe >= 2 then gaze.s2 = true end
  if stufe >= 3 then gaze.s3 = true end

  local k = (stufe == 3) and pool("flirt") or pool("blick", stufe)
  if #k == 0 then
    log(string.format("BLICK Stufe %d - Pool leer", stufe))
    return
  end
  log(string.format("BLICK Stufe %d nach %.1fs, %d Kandidaten", stufe, gaze.t, #k))
  Speaker.Request({
    situation  = (stufe == 3) and "flirt" or "blick",
    --  Stufe 3 zieht aus dem Flirt-Pool und teilt sich dessen Abklingzeit mit der
    --  Leitersprosse und dem Zufallstimer: Flirt soll selten sein, egal woher er kommt.
    pool       = (stufe == 3) and "flirt" or ("blick" .. stufe),
    kandidaten = k,
    cd         = (stufe == 3) and GAZE.cd3 or (stufe == 2) and GAZE.cd2 or GAZE.cd1,
    ziel       = obj,
  })
  gaze.zuletzt = string.format("Stufe %d, %d Kandidaten", stufe, #k)
end

local function gazeTick(d, p)
  if not gaze.an then return end
  local ts
  pcall(function() ts = Game.GetTargetingSystem() end)
  if not ts then return end
  local o
  pcall(function() o = ts:GetLookAtObject(p, false, false) end)

  local passt = istJudy(o)
  if passt then
    if psm("Combat") == 1 then passt = false end
  end
  if passt then
    local dist = 999.0
    pcall(function()
      dist = Vector4.Distance(p:GetWorldPosition(), o:GetWorldPosition())
    end)
    if dist > GAZE.distanz then passt = false end
  end

  if passt then
    local id = tostring(o:GetEntityID().hash)
    stimme.judyId = id
    judyMerken(o)
    T.Blickkontakt()
    if id ~= gaze.id then
      gaze.id, gaze.t, gaze.s1, gaze.s2, gaze.s3 = id, 0.0, false, false, false
    end
    gaze.t = gaze.t + d
    gazeFeuern(o)
  elseif gaze.id then
    --  Wegsehen setzt die Uhr zurueck. Sonst liesse sich die Schwelle aus lauter kurzen
    --  Blicken zusammensammeln, und das ist nicht dasselbe wie jemanden anzusehen.
    gaze.id, gaze.t, gaze.s1, gaze.s2, gaze.s3 = nil, 0.0, false, false, false
  end
end

--  ---------------------------------------------------------------- Kampf

local KAMPF = {
  anlauf   =  2.0,    -- erst ein Moment Gefecht, dann redet sie
  waehrend = 30.0,    -- Abstand zwischen Zeilen im laufenden Kampf
  nachlauf =  2.5,    -- nach dem letzten Schuss, bevor sie es kommentiert
  cd_ende  = 45.0,    -- damit ein zweiter Schwung nicht sofort wieder quittiert wird
}
local kampf = { drin = false, seit = 0.0, seitEnde = nil, an = true }

local function kampfTick(d)
  if not kampf.an then return end
  --  gamePSMCombat: 0 Default, 1 InCombat, 2 OutOfCombat, 3 Stealth
  local drin = psm("Combat") == 1

  if drin and not kampf.drin then
    kampf.drin, kampf.seit, kampf.seitEnde = true, 0.0, nil
    log("KAMPF beginnt - Haltung " .. haltungText() .. ", Lage " .. select(2, lageLesen()))
  elseif not drin and kampf.drin then
    kampf.drin, kampf.seitEnde = false, 0.0
    --  Was noch fuer den Kampf anstand, ist keine Kampfzeile mehr.
    Speaker.Verwerfen("kampf")
    log("KAMPF vorbei - Haltung " .. haltungText() .. ", Lage " .. select(2, lageLesen()))
  end

  if kampf.drin then
    kampf.seit = kampf.seit + d
    --  Erst fragen, wenn es auch etwas werden kann. Sonst prallt alle zwei Sekunden ein
    --  Antrag an der Abklingzeit ab und begraebt die echten Ablehnungen im Protokoll.
    if kampf.seit >= KAMPF.anlauf and Speaker.Frei("kampf") then
      local k = pool("kampf")
      if #k > 0 then
        Speaker.Request({ situation = "kampf", pool = "kampf",
                          kandidaten = k, cd = KAMPF.waehrend })
      end
      kampf.seit = 0.0
    end
    return
  end

  if kampf.seitEnde then
    kampf.seitEnde = kampf.seitEnde + d
    if kampf.seitEnde >= KAMPF.nachlauf then
      kampf.seitEnde = nil
      local k = pool("kampf_ende")
      if #k > 0 then
        Speaker.Request({ situation = "kampf_ende", pool = "kampf_ende",
                          kandidaten = k, cd = KAMPF.cd_ende })
      end
    end
  end
end

--  ---------------------------------------------------------------- Die Leiter

--  Wenn V stehen bleibt, faengt sie irgendwann von selbst an.
--
--  Der erste Entwurf mass Ruhe - wie lange nichts gesagt wurde. Das war das falsche Mass.
--  Bewegung ist Aktivitaet: wer gerade durch die Stadt gelaufen ist, steht nicht seit acht
--  Minuten herum, auch wenn niemand geredet hat. Gemessen wird darum STILLSTAND, und jede
--  Bewegung setzt die Leiter auf die erste Sprosse zurueck.
--
--  Ruhe bleibt trotzdem eine Sperre, nur eben nicht die Uhr: sie soll sich nicht selbst
--  hinterherreden, wenn eben erst etwas anderes lief.
--
--  Die Sprossen wachsen. Gleiche Abstaende erzeugen ein Ticken, und ein Ticken merkt man
--  beim dritten Mal. Ist die letzte gespielt, bleibt sie still, bis V sich bewegt.
--  `cd` je Sprosse, nicht global. Sprosse eins ist die billigste und wuerde sich sonst
--  bei "ein Schritt, warten, ein Schritt, warten" alle halbe Minute wiederholen.
local LEITER = {
  --  Stufe 2 des Reibungstopfs: "V troedelt". Stufe 1 gehoert dem Abstand und wuerde
  --  hier falsch klingen - "V, warte, ich bin ganz nah", waehrend sie danebensteht.
  { steht =  25.0, pool = "reibung", stufe = 2, cd = 120.0 },
  { steht =  75.0, pool = "alltag",     cd =  60.0 },   -- laenger: Smalltalk
  { steht = 180.0, pool = "initiative", cd =  60.0 },   -- sehr lange: sie faengt etwas an
  { steht = 420.0, pool = "flirt",      cd = 900.0, liebe = true },   -- sieben Minuten
}
--  In Metern JE SEKUNDE. Der erste Anlauf verglich die Strecke EINES BILDES mit einem
--  festen Wert; bei 60 Bildern waren das knapp ein Meter pro Bild, und damit haette
--  Sprinten noch als Stehen gezaehlt. 0,5 m/s ist langsamer als Schleichen.
--  Zu Hause misst die Leiter das Falsche.
--
--  Draussen ist Stillstehen ein Hinweis darauf, dass V sie stehenlaesst - deshalb faengt
--  die Leiter dort mit Ungeduld an. In der Wohnung ist Stillstehen der NORMALFALL, und
--  Ungeduld waere schlicht daneben: sie hat sich gerade selbst hingesetzt.
--
--  Also eine eigene Leiter. Kein Reibungs-Sprosse, kuerzere Abstaende, waermere Toepfe.
--  Kein neuer Inhalt - dieselben Zeilen in einem anderen Mischungsverhaeltnis.
local LEITER_WOHNUNG = {
  { steht =  20.0, pool = "alltag",  cd =   90.0 },
  --  Tageszeit-Sprossen. Passt die Stunde nicht, werden sie UEBERSPRUNGEN, nicht
  --  abgewartet - sonst stuende die Leiter mittags an der Morgenzeile fest.
  { steht =  40.0, pool = "wohnung", stufe = 2, cd = 3600.0, stunden = {  5, 11 } },
  { steht =  40.0, pool = "wohnung", stufe = 3, cd = 3600.0, stunden = { 22,  4 } },
  { steht =  70.0, pool = "wohnung", stufe = 1, cd =  300.0 },
  { steht = 120.0, pool = "naehe",   cd =  180.0 },
  { steht = 200.0, pool = "initiative", cd = 120.0 },
  { steht = 320.0, pool = "flirt",   cd =  600.0, liebe = true },
}

local STILL_TEMPO = 0.5
local RUHE_MIN    = 15.0   -- so lange muss sie mindestens geschwiegen haben
--  Karenz: erst ANHALTENDE Bewegung setzt die Leiter zurueck. Sich umzudrehen oder einen
--  Schritt zur Seite zu machen ist kein Weitergehen - ohne die Karenz reichte eine
--  Sekunde, um von vorn zu beginnen, und dann faengt sie alle 25 s wieder an.
local KARENZ      = 4.0
local leiter = { stufe = 1, an = true, stehtSeit = 0.0, bewegtSeit = 0.0, letztePos = nil,
                 wohnungWar = false }

local function leiterTick(d, p)
  if not leiter.an then return end

  --  Im Gefecht und im Wagen hat sie anderes zu tun, und "stehen" heisst dort nichts.
  local imWagen = sonde("GetMountedVehicle", function() return Game.GetMountedVehicle(p) end,
                        true)
  if psm("Combat") == 1 or imWagen ~= nil then
    leiter.stufe, leiter.stehtSeit, leiter.bewegtSeit = 1, 0.0, 0.0
    return
  end

  local pos
  pcall(function() pos = p:GetWorldPosition() end)
  if pos and leiter.letztePos then
    local w = 0.0
    pcall(function() w = Vector4.Distance(pos, leiter.letztePos) end)
    local tempo = (d > 0.0) and (w / d) or 0.0
    if tempo > STILL_TEMPO then
      --  Waehrend der Karenz laeuft die Standuhr weder weiter noch zurueck: ein Schritt
      --  ist kein Stehen, aber auch kein Weitergehen.
      leiter.bewegtSeit = leiter.bewegtSeit + d
      if leiter.bewegtSeit >= KARENZ then
        leiter.stufe, leiter.stehtSeit = 1, 0.0
      end
    else
      leiter.bewegtSeit = 0.0
      leiter.stehtSeit = leiter.stehtSeit + d
    end
  end
  leiter.letztePos = pos

  --  Beim Wechsel zwischen den beiden Leitern die Sprosse zuruecksetzen. Ohne das wuerde
  --  ein Index aus der einen auf die andere angewandt - Sprosse 3 draussen ist
  --  `initiative`, drinnen auch, aber die Schwellen und Abklingzeiten passen nicht, und
  --  bei ungleich langen Leitern zeigte der Index ins Leere.
  local drin = T.InWohnung()
  if drin ~= leiter.wohnungWar then
    leiter.wohnungWar = drin
    leiter.stufe, leiter.stehtSeit, leiter.bewegtSeit = 1, 0.0, 0.0
    log("LEITER " .. (drin and "Wohnungsleiter" or "Leiter draussen") .. " uebernimmt")
    return
  end

  local st = (drin and LEITER_WOHNUNG or LEITER)[leiter.stufe]
  if not st then return end
  if leiter.stehtSeit < st.steht then return end
  if Speaker.StillSeit() < RUHE_MIN then return end

  --  Bedingte Sprossen ueberspringen statt blockieren. Frueher stand hier ein `return`
  --  fuer die Liebes-Sprosse; als letzte war das gleichbedeutend, mitten in der Leiter
  --  waere es eine Sperre gewesen.
  if (st.liebe and not verliebtGenug())
     or (st.stunden and not stundeIn(st.stunden)) then
    leiter.stufe = leiter.stufe + 1
    return
  end

  local k = pool(st.pool, st.stufe)
  if #k == 0 or not Speaker.Frei(st.pool) then return end
  log(string.format("LEITER%s Sprosse %d nach %.0fs Stillstand, Pool %s (%d)",
      drin and " (Wohnung)" or "", leiter.stufe, leiter.stehtSeit, st.pool, #k))
  Speaker.Request({ situation = "leiter", prio = Speaker.PRIO.alltag,
                    pool = st.pool, kandidaten = k, cd = st.cd or 60.0 })
  leiter.stufe = leiter.stufe + 1
end

--  ---------------------------------------------------------------- Abschied

--  Sie verabschiedet sich, wenn sie geht.
--
--  Ein Ereignis dafuer gibt es nicht, das wir ohne NCA-Haken lesen koennten. Was wir haben,
--  ist ihre Referenz: faellt sie weg, ist Judy nicht mehr da. Das passiert aber auch beim
--  Despawn auf Entfernung und in gesperrten Zonen, und das ist kein Abschied.
--
--  Der Unterschied ist die letzte bekannte Entfernung. Wer weggeschickt wird, steht vorher
--  neben einem; wer wegen Entfernung verschwindet, war weit weg. Protokolliert wird beides,
--  damit sich nach ein paar Sitzungen sagen laesst, ob die Trennung taugt.
local ABSCHIED = { nah = 20.0, cd = 120.0 }
local abschied = { warDa = false, letzteDist = nil, an = true }

local function abschiedTick()
  if not abschied.an then return end
  local daJetzt = judy.obj ~= nil
  if judy.dist then abschied.letzteDist = judy.dist end

  if abschied.warDa and not daJetzt then
    local w = abschied.letzteDist
    --  Beim Schnellreisen verschwindet sie aus naechster Naehe, und das ist kein
    --  Abschied, sondern ein Ortswechsel. Sie ist gleich wieder da.
    if frischGesprungen() then
      log("ABSCHIED verworfen - Ortssprung, das ist kein Weggehen")
      abschied.letzteDist = nil
      abschied.warDa = daJetzt
      return
    end
    if w and w <= ABSCHIED.nah then
      local k = pool("abschied")
      if #k > 0 then
        log(string.format("ABSCHIED sie war %.0f m entfernt und ist weg", w))
        Speaker.Request({ situation = "abschied", pool = "abschied",
                          kandidaten = k, cd = ABSCHIED.cd })
      end
    else
      log(string.format("ABSCHIED verworfen - sie war %s entfernt, das war ein Despawn",
          w and string.format("%.0f m", w) or "unbekannt weit"))
    end
    abschied.letzteDist = nil
  end
  abschied.warDa = daJetzt
end

--  ---------------------------------------------------------------- Zufallsflirt

--  Ein seltener Timer, der auch beim Laufen zuschlaegt.
--
--  Blick und Leiter setzen beide Stillstand voraus - wer durch die Stadt laeuft, erreicht
--  keine der beiden. Genau dort fehlt aber etwas: sie geht neben V her, und irgendwann
--  sagt sie einfach etwas. Der Abstand ist absichtlich weit und zufaellig, damit sich kein
--  Takt einstellt.
local ZUFALL = { min = 600.0, max = 1200.0 }
local zufall = { rest = nil, an = true }

local function zufallNeu()
  zufall.rest = ZUFALL.min + math.random() * (ZUFALL.max - ZUFALL.min)
end

local function zufallTick(d, p)
  if not zufall.an then return end
  if zufall.rest == nil then zufallNeu() end

  --  Im Gefecht laeuft die Uhr nicht weiter - sonst haette sie nach einem langen Kampf
  --  sofort etwas offen, und ein Flirt direkt nach dem letzten Schuss sitzt falsch.
  if psm("Combat") == 1 then return end

  zufall.rest = zufall.rest - d
  if zufall.rest > 0.0 then return end

  if not verliebtGenug() then return end
  local k = pool("flirt")
  if #k == 0 or not Speaker.Frei("flirt") then return end

  zufallNeu()
  log(string.format("ZUFALLSFLIRT faellig, %d Kandidaten, naechster in %.0f min",
      #k, zufall.rest / 60.0))
  Speaker.Request({ situation = "flirt", pool = "flirt", kandidaten = k, cd = 300.0 })
end

--  ---------------------------------------------------------------- Warten und Troedeln

--  Zwei Schwellen statt einer. Eine einzelne wuerde flattern, sobald V an der Grenze
--  entlanglaeuft: ein Schritt hin, ein Schritt zurueck, und sie faengt jedes Mal neu an.
--  Ausgeloest wird ueber `weit`, zurueckgesetzt erst unter `nah`.
--
--  Und es muss ANHALTEN. Kurz durch eine Tuer zu gehen ist kein Zuruecklassen; sechs
--  Sekunden Abstand sind eins.
local REIBUNG = {
  nah    =  6.0,
  weit   = 10.0,
  geduld =  6.0,
  cd     = 90.0,
}
local reibung = { seit = 0.0, an = true }

local function reibungTick(d, p)
  if not reibung.an then return end

  --  Im Wagen ist Abstand normal, im Gefecht redet sie ueber anderes.
  local imWagen = sonde("GetMountedVehicle", function() return Game.GetMountedVehicle(p) end,
                    true)
  if imWagen ~= nil or psm("Combat") == 1 then
    reibung.seit = 0.0
    return
  end

  --  Und in der Wohnung ist Abstand ebenfalls normal: sie sitzt auf der Couch, V steht in
  --  der Kueche. "V, warte, ich bin ganz nah" waere dort schlicht falsch.
  if T.InWohnung() then
    reibung.seit = 0.0
    return
  end

  local w = judy.dist
  if not w then reibung.seit = 0.0; return end

  if w < REIBUNG.nah then
    reibung.seit = 0.0
    return
  end
  if w < REIBUNG.weit then
    --  Zwischen nah und weit passiert nichts, aber die Uhr laeuft auch nicht zurueck.
    return
  end

  reibung.seit = reibung.seit + d
  if reibung.seit < REIBUNG.geduld then return end
  reibung.seit = 0.0

  --  Stufe 1: sie haengt hinterher und ruft V nach. Stufe 2 setzt voraus, dass sie
  --  danebensteht, und gehoert der Leiter.
  local k = pool("reibung", 1)
  if #k > 0 and Speaker.Frei("reibung") then
    log(string.format("WARTEN %.0f m seit %.0fs", w, REIBUNG.geduld))
    Speaker.Request({ situation = "reibung", pool = "reibung",
                      kandidaten = k, cd = REIBUNG.cd })
  end
end

--  ---------------------------------------------------------------- Sorge

--  Ausgeloest wird am UEBERGANG unter die Schwelle, nicht solange V darunter ist. Sonst
--  redet sie durch, waehrend es eng wird, und das ist das Gegenteil von Anteilnahme.
local SORGE = {
  schwelle = 40.0,    -- Prozent
  cd       = 120.0,
}
local sorge = { war = 100.0, an = true }

local function sorgeTick()
  if not sorge.an then return end
  local p = spieler()
  if not p then return end
  local hp = sonde("StatPool.Health", function()
    --  Der dritte Parameter heisst `perc`. Mit `false` kommen Absolutpunkte zurueck -
    --  im Panel standen 343, und eine Schwelle von 40 war damit nie zu unterschreiten.
    return Game.GetStatPoolsSystem():GetStatPoolValue(p:GetEntityID(),
                                                      gamedataStatPoolType.Health, true)
  end)
  if hp == nil then return end

  if hp <= SORGE.schwelle and sorge.war > SORGE.schwelle then
    local k = pool("sorge")
    if #k > 0 and Speaker.Frei("sorge") then
      log(string.format("SORGE Gesundheit %.0f%% -> unter %.0f%%", hp, SORGE.schwelle))
      Speaker.Request({ situation = "sorge", pool = "sorge",
                        kandidaten = k, cd = SORGE.cd })
    end
  end
  sorge.war = hp
end

--  ---------------------------------------------------------------- Wiedersehen

--  "V kommt zurueck" laesst sich ohne Judys Position nicht messen. Zwei ehrliche
--  Naeherungen: der Beginn einer Sitzung, und ein Ortssprung - Schnellreise, Aufzug ins
--  Penthouse, jede Teleportation. Ein Sprung ist schlicht eine Strecke, fuer die in einem
--  Bild keine Zeit war; das braucht kein Blackboard und faellt auch nicht mit ihm aus.
--  Die Begruessung haengt jetzt am ersten BLICKKONTAKT, nicht an einer Uhr. Eine feste
--  Verzoegerung nach dem Laden trifft den Moment nie: mal steht sie schon da, mal kommt
--  sie erst um die Ecke. Sich anzusehen ist der Moment, in dem ein Hallo faellig ist.
local WIEDER = {
  nachBlick =  0.2,    -- so kurz, dass es zum Blick gehoert und nicht danach kommt
  nachSprung = 8.0,
  spaetestens = 15.0,   -- ohne Blickkontakt trotzdem, sonst bleibt es aus
  rueckfallNah = 25.0,  -- aber nur, wenn sie ueberhaupt in der Naehe ist
  cd        = 300.0,
}
local wieder = { startOffen = true, seitStart = nil, seitBlick = nil,
                 seitSprung = nil, an = true }

--  Vom Blick-Ausloeser gemeldet, sobald er sie zum ersten Mal erkennt.
function T.Blickkontakt()
  if wieder.startOffen and not wieder.seitBlick then wieder.seitBlick = 0.0 end
end

local function wiederTick(d, p)
  if not wieder.an then return end

  --  Der Sprung wird in `weltTick` gemessen, ganz vorn im Takt. Hier nur uebernehmen.
  if welt.sprungSeit == 0.0 and not wieder.seitSprung then wieder.seitSprung = 0.0 end

  --  Ohne Blickkontakt kaeme sonst NIE ein Hallo. Wer nach dem Laden losgeht, ohne sie
  --  anzusehen, hat sie stumm neben sich - genau das war zu beobachten, das erste
  --  Wiedersehen kam Minuten zu spaet. Der Blick bleibt der schoene Weg, die Uhr der
  --  Rueckfall.
  if wieder.startOffen then
    wieder.seitStart = (wieder.seitStart or 0.0) + d
    if wieder.seitStart >= WIEDER.spaetestens and judy.obj and judy.dist
       and judy.dist <= WIEDER.rueckfallNah then
      log(string.format("WIEDERSEHEN kein Blickkontakt in %.0fs - Rueckfall auf die Uhr",
          WIEDER.spaetestens))
      wieder.startOffen, wieder.seitBlick = false, nil
      wieder.seitSprung = wieder.seitSprung or WIEDER.nachSprung
    end
  end

  local faellig = false
  if wieder.seitBlick then
    wieder.seitBlick = wieder.seitBlick + d
    if wieder.seitBlick >= WIEDER.nachBlick then
      wieder.startOffen, wieder.seitBlick, faellig = false, nil, true
    end
  end
  if wieder.seitSprung then
    wieder.seitSprung = wieder.seitSprung + d
    if wieder.seitSprung >= WIEDER.nachSprung then
      wieder.seitSprung, faellig = nil, true
    end
  end
  if not faellig then return end

  local k = pool("wiedersehen")
  if #k > 0 then
    Speaker.Request({ situation = "wiedersehen", pool = "wiedersehen",
                      kandidaten = k, cd = WIEDER.cd })
  end
end

--  ---------------------------------------------------------------- Fahrzeug

local FAHRZEUG = {
  anlauf = 2.5,     -- erst sitzen, dann reden
  cd     = 150.0,
}
local fahrt = { drin = false, seit = nil, an = true }

local function fahrtTick(d, p)
  if not fahrt.an then return end
  local v = sonde("GetMountedVehicle", function() return Game.GetMountedVehicle(p) end,
                    true)
  local drin = v ~= nil

  if drin and not fahrt.drin then
    fahrt.drin, fahrt.seit = true, 0.0
    log("FAHRZEUG aufgesessen - Haltung " .. haltungText()
        .. ", Lage " .. select(2, lageLesen()))
  elseif not drin and fahrt.drin then
    fahrt.drin, fahrt.seit = false, nil
    --  Was noch fuers Einsteigen anstand, passt nach dem Aussteigen nicht mehr.
    Speaker.Verwerfen("fahrzeug")
  end

  if fahrt.seit then
    fahrt.seit = fahrt.seit + d
    if fahrt.seit >= FAHRZEUG.anlauf then
      fahrt.seit = nil
      local k = pool("fahrzeug")
      if #k > 0 then
        Speaker.Request({ situation = "fahrzeug", pool = "fahrzeug",
                          kandidaten = k, cd = FAHRZEUG.cd })
      end
    end
  end
end

--  ---------------------------------------------------------------- aussen

--  ---------------------------------------------------------------- Testknoepfe

--  Jeden Ausloeser sofort ausloesen, ohne seine Bedingung herzustellen. Sonst dauert eine
--  Runde durch alle Situationen Minuten: drei Minuten stillstehen fuer Sprosse drei, eine
--  halbe Stunde fuer die zweite Blickstufe.
--
--  Die Pools sind dieselben wie im echten Betrieb, und der Weg geht durch den Sprecher -
--  ein Test zeigt also auch, ob Auswahl, Wiederholungsschutz und Ausgabe stimmen. Nur die
--  Wartezeiten entfallen.
local TESTS = {
  { name = "Blick 1",     sit = "blick",       pool = "blick1",      q = "blick", st = 1 },
  { name = "Blick 2",     sit = "blick",       pool = "blick2",      q = "blick", st = 2 },
  { name = "Kampf",       sit = "kampf",       pool = "kampf",       q = "kampf" },
  { name = "Kampfende",   sit = "kampf_ende",  pool = "kampf_ende",  q = "kampf_ende" },
  { name = "Sorge",       sit = "sorge",       pool = "sorge",       q = "sorge" },
  { name = "Wiedersehen", sit = "wiedersehen", pool = "wiedersehen", q = "wiedersehen" },
  { name = "Fahrzeug",    sit = "fahrzeug",    pool = "fahrzeug",    q = "fahrzeug" },
  { name = "Warten",      sit = "reibung",     pool = "reibung",     q = "reibung", st = 1 },
  { name = "Leiter 1",    sit = "leiter",      pool = "reibung",     q = "reibung", st = 2 },
  { name = "Leiter 2",    sit = "leiter",      pool = "alltag",      q = "alltag" },
  { name = "Leiter 3",    sit = "leiter",      pool = "initiative",  q = "initiative" },
  { name = "Blick 3",     sit = "flirt",       pool = "blick3",      q = "flirt" },
  { name = "Leiter 4",    sit = "leiter",      pool = "flirt",       q = "flirt" },
  { name = "Zufallsflirt", sit = "flirt",      pool = "flirt",       q = "flirt" },
  { name = "Abschied",    sit = "abschied",    pool = "abschied",    q = "abschied" },
}

function T.Tests()
  local out = {}
  for i, t in ipairs(TESTS) do
    out[i] = { name = t.name, n = #pool(t.q, t.st) }
  end
  return out
end

function T.Test(i)
  local t = TESTS[i]
  if not t then return end
  local k = pool(t.q, t.st)
  if #k == 0 then
    log("TEST " .. t.name .. " - Pool leer")
    return
  end
  log(string.format("TEST %s, %d Kandidaten", t.name, #k))
  --  cd = 0: ein Test soll die echte Abklingzeit nicht setzen und damit den naechsten
  --  Versuch blockieren.
  Speaker.Request({ situation = t.sit, pool = t.pool, kandidaten = k,
                    cd = 0.0, erzwingen = true })
end

function T.Init(opts)
  Speaker     = opts.speaker
  LINES       = opts.lines or {}
  log         = opts.log or function() end
  holeZiel    = opts.ziel
  letzteZeile = opts.letzteZeile
end

--  Fuer das Panel: was sieht V gerade an?
function T.Anvisiert()
  local p = spieler()
  if not p then return nil end
  local o
  pcall(function()
    o = Game.GetTargetingSystem():GetLookAtObject(p, false, false)
  end)
  if not o then return nil end
  local rec, name = beschreibe(o)
  return { name = name, record = rec, judy = istJudy(o),
           judyRecord = JUDY and string.format("%s:%s", tostring(JUDY.hash),
                                               tostring(JUDY.length)) or nil }
end

function T.Tick(d)
  if not Speaker then return end
  local p = spieler()
  if not p then return end
  --  Im Menue steht die Zeit fuer den Spieler still, also auch fuer sie.
  if pausiert() then return end
  --  Unabhaengig von jedem Ausloeser: der Abstand wird auch angezeigt und spaeter vom
  --  Teleport-Fix gebraucht. Frueher rechnete ihn nur reibungTick, und der steigt im
  --  Wagen und im Gefecht sofort aus - dann stand im Panel ein alter Wert.
  abstand(p)
  beziehungLesen()
  weltTick(d, p)
  kontextTick(d, p)
  heilungTick(d, judyHolen())
  ortTick(d)
  stimmeTick()
  haltungMitschreiben(d)
  nachmessen(d)
  beobTick(d)
  halten(d)
  gazeTick(d, p)
  kampfTick(d)
  sorgeTick()
  reibungTick(d, p)
  leiterTick(d, p)
  zufallTick(d, p)
  abschiedTick()
  haltungTick(d)
  wiederTick(d, p)
  fahrtTick(d, p)
end

function T.Status()
  return {
    beob  = beob.an,
    fremde = { anzahl = fremdeAnzahl, liste = fremde },
    blickkontakt = { dauer = blick.dauer, letzte = blick.letzte, fehler = blick.fehler },
    liegen = { hat = liegen.hat, geholfen = liegen.geholfen, fehler = liegen.fehler },
    leiter2 = { wohnung = leiter.wohnungWar, stufe = leiter.stufe,
                stehtSeit = leiter.stehtSeit },
    ort   = { tag = ort.tag, name = ort.tag and (ORTSNAMEN[ort.tag] or ort.tag) or nil,
              wohnung = ort.wohnung, seit = ort.seit, still = ort.judyStill },
    wunde = { an = WUNDE.an, hat = wunde.hat, entfernt = wunde.entfernt,
              versuche = wunde.versuche, abHp = WUNDE.abHp, fehler = wunde.fehler },
    heil  = { an = heil.an, hp = heil.hp, ruhe = heil.ruhe,
              proSekunde = HEILUNG.proSekunde, fehler = heil.fehler },
    stunde = ktx.nca.stunde,
    ktx   = { da = ktx.nca.da, proben = ktx.proben,
              eigen = ktx.eigen, nca = ktx.nca, abw = ktx.abw },
    gaze  = { an = gaze.an, t = gaze.t, aktiv = gaze.id ~= nil, zuletzt = gaze.zuletzt,
              stufe1 = GAZE.stufe1, stufe2 = GAZE.stufe2, stufe3 = GAZE.stufe3,
              n1 = #pool("blick", 1), n2 = #pool("blick", 2), n3 = #pool("flirt") },
    bez = { liebe = bez.liebe, freund = bez.freund,
            fakt = bez.fakt, welcher = bez.welcher, offen = verliebtGenug() },
    zufall = { an = zufall.an, rest = zufall.rest,
               min = ZUFALL.min, max = ZUFALL.max, n = #pool("flirt") },
    kampf = { an = kampf.an, drin = kampf.drin, seit = kampf.seit,
              n = #pool("kampf"), nEnde = #pool("kampf_ende") },
    sorge = { an = sorge.an, hp = sorge.war, schwelle = SORGE.schwelle,
              n = #pool("sorge") },
    wieder = { an = wieder.an, offen = wieder.startOffen,
               seitBlick = wieder.seitBlick, nachBlick = WIEDER.nachBlick,
               seitStart = wieder.seitStart, spaetestens = WIEDER.spaetestens,
               seitSprung = wieder.seitSprung, nachSprung = WIEDER.nachSprung,
               n = #pool("wiedersehen") },
    fahrt = { an = fahrt.an, drin = fahrt.drin, n = #pool("fahrzeug") },
    abschied = { an = abschied.an, da = abschied.warDa, n = #pool("abschied") },
    haltung = { an = haltung.an, ziel = haltung.ziel, ist = haltung.ist,
                gesetzt = haltung.gesetzt, aufgefrischt = haltung.aufgefrischt },
    stimme = { kennt = stimme.judyId ~= nil, zuletzt = stimme.zuletztFremd,
               greifbar = judy.obj ~= nil },
    leiter = { an = leiter.an, stufe = leiter.stufe, stufen = #LEITER,
               steht = leiter.stehtSeit,
               ruhe = Speaker and Speaker.StillSeit() or 0.0, ruheMin = RUHE_MIN,
               bewegt = leiter.bewegtSeit, karenz = KARENZ,
               naechste = LEITER[leiter.stufe] and LEITER[leiter.stufe].steht or nil },
    reibung = { an = reibung.an, dist = judy.dist, seit = reibung.seit,
                nah = REIBUNG.nah, weit = REIBUNG.weit, geduld = REIBUNG.geduld,
                n = #pool("reibung") },
  }
end

function T.Setzen(was, an)
  if was == "heilung"  then heil.an = an end
  if was == "wunde"    then WUNDE.an = an end
  if was == "blick"    then gaze.an  = an end
  if was == "kampf"    then kampf.an = an end
  if was == "sorge"    then sorge.an = an end
  if was == "wieder"   then wieder.an = an end
  if was == "fahrzeug" then fahrt.an = an end
  if was == "reibung"  then reibung.an = an end
  if was == "leiter"   then leiter.an = an end
  if was == "zufall"   then zufall.an = an end
  if was == "abschied" then abschied.an = an end
  if was == "haltung"  then haltung.an = an end
end

function T.Zuruecksetzen()
  gaze.s1, gaze.s2, gaze.s3, gaze.t, gaze.id = false, false, false, 0.0, nil
  kampf.seit = 0.0
  sorge.war = 100.0
  wieder.startOffen, wieder.seitBlick, wieder.seitSprung = true, nil, nil
  fahrt.seit = nil
  reibung.seit = 0.0
  leiter.stufe, leiter.stehtSeit, leiter.bewegtSeit = 1, 0.0, 0.0
  zufall.rest = nil
end

return T
