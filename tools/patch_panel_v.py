"""Ergaenzt das Panel um Vs Voiceset: Sprecherwahl und Sweep.

V wird ueber `isPlayer = true` und `CreateNodeRef("#player")` angesprochen, Judy weiterhin
ueber ihren Tag. Beides derselbe Quest-Voiceset-Knoten.

Jede Ersetzung wird geprueft, bevor die Datei geschrieben wird - str.replace() tut sonst
stillschweigend nichts, und genau das hat hier schon zweimal zu einem Testlauf gefuehrt,
der nichts messen konnte.
"""
import io
import json
import os
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PANEL = os.path.join(HERE, "cet", "CompanionLeashVO", "init.lua")

names = json.load(open(os.path.join(HERE, "data", "vset_v_sweep.json"), encoding="utf-8"))
s = io.open(PANEL, encoding="utf-8").read()
fails = []


def sub(old, new, label):
    global s
    if old not in s:
        fails.append(label)
        return
    s = s.replace(old, new, 1)


rows, cur = [], "  "
for n in names:
    piece = '"%s", ' % n
    if len(cur) + len(piece) > 94:
        rows.append(cur.rstrip())
        cur = "  "
    cur += piece
rows.append(cur.rstrip().rstrip(","))
VSET = "local VSET_V = {\n" + "\n".join(rows) + "\n}"

Q = chr(34)
BS = chr(92)
ESCQ = BS + Q            # \" fuer Lua-Strings

sub(
    "local STYLES, styleIdx = {}, -1",
    "--  Aus vset_v.scene gelesen: 266 Eintraege, hier ohne Textfragmente und\n"
    "--  fremdsprachige Reste. V ist Player-POV - bei ihr zaehlen nur Text und Dauer,\n"
    "--  Mundbewegung spielt keine Rolle.\n"
    + VSET + "\n\n"
    "--  0 = Judy ueber ihren Tag, 1 = V ueber #player.\n"
    "local speaker = 0\n"
    "local sweep = nil\n\n"
    "local STYLES, styleIdx = {}, -1",
    "VSET_V")

sub(
    '    local ref = NewObject("gameEntityReference")\n'
    "    prm.isPlayer = false\n"
    '    ref.type  = Enum.new("gameEntityReferenceType", "Tag")\n'
    '    ref.names = { CName.new("NCA_Companion") }\n'
    "    prm.puppetRef = ref",
    '    local ref = NewObject("gameEntityReference")\n'
    "    if speaker == 1 then\n"
    "      prm.isPlayer  = true\n"
    '      ref.reference = CreateNodeRef("#player")\n'
    "    else\n"
    "      --  Ihre Entity traegt den Tag NCA_Companion, und Tag ist einer der vier\n"
    "      --  Referenztypen - eine gespawnte Begleiterin braucht damit keinen NodeRef.\n"
    "      prm.isPlayer = false\n"
    '      ref.type  = Enum.new("gameEntityReferenceType", "Tag")\n'
    '      ref.names = { CName.new("NCA_Companion") }\n'
    "    end\n"
    "    prm.puppetRef = ref",
    "Sprecherwahl")

sub(
    "local function playBark(name)\n"
    '  if not target then log("kein Ziel"); return end',
    "local function playBark(name)\n"
    '  if speaker == 0 and not target then log("kein Ziel"); return end',
    "Zielpruefung")

driver = (
    "--  Liest die zuletzt angezeigte Dialogzeile. ShowDialogLine haelt ein ARRAY von\n"
    "--  scnDialogLineData - als Struct gelesen ist jedes Feld nil.\n"
    "local function lastLine()\n"
    "  local ok, res = pcall(function()\n"
    "    local defs = Game.GetAllBlackboardDefs()\n"
    "    local bb   = Game.GetBlackboardSystem():Get(defs.UIGameData)\n"
    "    local arr  = FromVariant(bb:GetVariant(defs.UIGameData.ShowDialogLine))\n"
    '    if type(arr) ~= "table" then return nil end\n'
    "    local el = arr[#arr]\n"
    "    if el == nil then return nil end\n"
    '    local hash = ""\n'
    "    pcall(function() hash = tostring(el.speaker:GetEntityID().hash) end)\n"
    '    return { text = tostring(el.text or ""), dur = tonumber(el.duration) or 0,\n'
    '             name = tostring(el.speakerName or ""), hash = hash }\n'
    "  end)\n"
    "  if ok then return res end\n"
    "  return nil\n"
    "end\n\n"
    "--  Bei V ist der Sprecher der Spieler, nicht das gesperrte Ziel.\n"
    "local function expectedHash()\n"
    "  local ok, h = pcall(function()\n"
    "    if speaker == 1 then return tostring(Game.GetPlayer():GetEntityID().hash) end\n"
    "    return tostring(target:GetEntityID().hash)\n"
    "  end)\n"
    "  if ok then return h end\n"
    "  return nil\n"
    "end\n\n"
    'registerForEvent("onUpdate", function(dt)\n'
    "  local d = dt or 0.016\n\n"
    "  --  Sweep: jeden Namen feuern, kurz auf die Zeile warten, Ergebnis mitschreiben.\n"
    "  --  Ein Treffer steht nach ~0.25s fest, ein Blindgaenger kostet nur den Timeout.\n"
    "  if sweep then\n"
    "    sweep.t = sweep.t + d\n"
    "    if sweep.pending then\n"
    "      local dl = lastLine()\n"
    '      if dl and not sweep.got and dl.text ~= "" and dl.text ~= sweep.before\n'
    "         and dl.hash == expectedHash() then\n"
    "        sweep.got = true\n"
    "        sweep.hits = sweep.hits + 1\n"
    "        sweep.wait = math.max(0.4, dl.dur * 0.6)\n"
    '        log(string.format("  TREFFER  %-30s %.2fs  ' + ESCQ + "%s" + ESCQ + '",\n'
    "            sweep.list[sweep.i], dl.dur, dl.text))\n"
    "      end\n"
    "      if sweep.t >= (sweep.got and sweep.wait or 1.3) then sweep.pending = false end\n"
    "    end\n"
    "    if not sweep.pending then\n"
    "      sweep.i = sweep.i + 1\n"
    "      if sweep.i > #sweep.list then\n"
    "        styleIdx = sweep.savedStyle\n"
    '        log(string.format("=== SWEEP FERTIG: %d von %d", sweep.hits, #sweep.list))\n'
    "        sweep = nil\n"
    "      else\n"
    "        local dl = lastLine()\n"
    '        sweep.before = dl and dl.text or ""\n'
    "        sweep.t, sweep.got, sweep.pending = 0, false, true\n"
    "        playBark(sweep.list[sweep.i])\n"
    "      end\n"
    "    end\n"
    "  end"
)
sub('registerForEvent("onUpdate", function(dt)\n  local d = dt or 0.016', driver, "Sweep-Treiber")

ui = (
    '  ImGui.Text("Sprecher:")\n'
    "  ImGui.SameLine()\n"
    '  if ImGui.RadioButton("Judy", speaker == 0) then speaker = 0 end\n'
    "  ImGui.SameLine()\n"
    '  if ImGui.RadioButton("V (Player-POV)", speaker == 1) then speaker = 1 end\n'
    "  if speaker == 1 then\n"
    '    ImGui.TextDisabled("V braucht kein Ziel und kein Lipsync - nur Text und Dauer.")\n'
    "  end\n"
    "  ImGui.Separator()\n\n"
    '  if ImGui.CollapsingHeader("Vs Voiceset durchmessen") then\n'
    '    ImGui.TextWrapped("Feuert alle " .. #VSET_V .. " Eintraege aus vset_v.scene und " ..\n'
    '                      "schreibt Text und Dauer ins Log. Erzwingt dafuer einen " ..\n'
    '                      "sichtbaren Untertitel-Stil - die Erkennung liest die " ..\n'
    '                      "Untertiteldaten.")\n'
    "    if sweep then\n"
    '      ImGui.Text(string.format("laeuft: %d/%d, %d Treffer",\n'
    "                 sweep.i, #sweep.list, sweep.hits))\n"
    '      if ImGui.Button("abbrechen") then\n'
    "        styleIdx = sweep.savedStyle\n"
    "        sweep = nil\n"
    "      end\n"
    "    else\n"
    '      if ImGui.Button("Vs Voiceset durchmessen") then\n'
    "        speaker = 1\n"
    "        sweep = { list = VSET_V, i = 0, t = 99, hits = 0, pending = false,\n"
    '                  got = false, before = "", savedStyle = styleIdx }\n'
    "        styleIdx = -1  -- sichtbar, sonst wird nichts gemeldet\n"
    '        log(string.format("=== SWEEP ueber %d V-Eintraege", #VSET_V))\n'
    "      end\n"
    '      ImGui.TextDisabled("Rund 5 Minuten, unbeaufsichtigt.")\n'
    "    end\n"
    "  end\n\n"
    '  if ImGui.CollapsingHeader("Barks - 55 Zeilen") then'
)
sub('  if ImGui.CollapsingHeader("Barks - 55 Zeilen") then', ui, "Sweep-UI")

if fails:
    print("!! NICHT ERSETZT: %s" % fails)
    sys.exit(1)

io.open(PANEL, "w", encoding="utf-8", newline="\n").write(s)
print("[ok] alle 5 Ersetzungen bestaetigt | %d V-Eintraege im Sweep" % len(names))
