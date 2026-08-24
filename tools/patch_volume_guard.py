"""Dauerhafte Sicherung gegen stumm gebliebene Dialoglautstaerke.

Die bisherigen Sicherungen - Timer, Shutdown-Hook, Stopp-Knopf - greifen alle nur, solange
die Sitzung lebt. Endet sie im Stumm-Fenster, bleibt `DialogueVolume` auf 0 stehen und
wandert so in die UserSettings.json. Genau das ist passiert.

Deshalb zusaetzlich zwei Dinge, die nicht davon abhaengen, dass unser Code sauber
durchlaeuft:

* beim Start pruefen und melden, wenn die Lautstaerke auf 0 steht
* eine unuebersehbare Warnung samt Knopf im Panel, solange sie auf 0 steht

Der Knopf setzt auf 100 statt auf einen gemerkten Wert: der gemerkte Wert ist ja gerade
verloren, wenn dieser Fall eintritt.
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PANEL = os.path.join(HERE, "cet", "CompanionLeashVO", "init.lua")

s = io.open(PANEL, encoding="utf-8").read()
fails = []


def sub(old, new, label):
    global s
    if old not in s:
        fails.append(label)
        return
    s = s.replace(old, new, 1)


#  Warnung ganz oben, unabhaengig von aufgeklappten Abschnitten.
sub(
    '  ImGui.Text("Ziel: " .. targetName)',
    "  --  Endet eine Sitzung im Stumm-Fenster, bleibt die Lautstaerke auf 0 und landet so\n"
    "  --  in den UserSettings. Timer und Shutdown-Hook helfen dann nicht mehr - das hier\n"
    "  --  haengt an nichts ausser dem gelesenen Wert.\n"
    "  local dv = dialogueVar()\n"
    "  if dv and dv:GetValue() == 0 then\n"
    "    ImGui.TextColored(1.0, 0.3, 0.3, 1.0, \"DIALOGLAUTSTAERKE STEHT AUF 0\")\n"
    '    ImGui.TextWrapped("Vermutlich von einem Stumm-Fenster, das nicht zurueckgesetzt " ..\n'
    '                      "wurde. Solange das so steht, hoerst du keinen Dialog im Spiel.")\n'
    '    if ImGui.Button("auf 100 zuruecksetzen##volfix") then\n'
    "      pcall(function() dv:SetValue(100) end)\n"
    '      log("DialogueVolume von Hand auf 100 gesetzt")\n'
    "    end\n"
    "    ImGui.Separator()\n"
    "  end\n\n"
    '  ImGui.Text("Ziel: " .. targetName)',
    "Warnung")

#  Beim Start melden, damit es auch ohne offenes Panel auffaellt.
sub(
    '  log(string.format("bereit - %d Stile gelesen, invisible=%s", #STYLES, tostring(styleIdx >= 0)))',
    '  log(string.format("bereit - %d Stile gelesen, invisible=%s", #STYLES, tostring(styleIdx >= 0)))\n'
    "  local dv = dialogueVar()\n"
    "  if dv and dv:GetValue() == 0 then\n"
    '    log("ACHTUNG: DialogueVolume steht auf 0 - im Panel steht ein Knopf zum Zuruecksetzen")\n'
    "  end",
    "Startmeldung")

if fails:
    print("!! NICHT ERSETZT: %s" % fails)
    sys.exit(1)

io.open(PANEL, "w", encoding="utf-8", newline="\n").write(s)
print("[ok] beide Ersetzungen bestaetigt")
