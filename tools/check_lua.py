# -*- coding: utf-8 -*-
"""Findet Lua-Namen, die vor ihrer Deklaration benutzt werden.

Dreimal in zwei Tagen hat genau dieser Fehler zugeschlagen: `lastLine`, `judyMerken`,
`stimme`. In Lua ist der Zugriff auf ein noch nicht deklariertes `local` kein Fehler beim
Laden - es wird als GLOBALE gelesen, ist `nil`, und fliegt erst zur Laufzeit. Beim letzten
Mal hat das jeden Frame geworfen, damit alle Ausloeser stillgelegt und das halbe Panel
gleich mit, waehrend die Kopfzeilen weiter funktionierten. Das sieht dann aus wie
"alles kaputt" und nicht wie "eine Zeile zu weit unten".

Vorher habe ich die Namen von Hand aufgezaehlt, die ich fuer verdaechtig hielt - und dabei
zweimal den uebersehen, der es war. Hier wird nichts mehr ausgewaehlt.

Geprueft wird nur die Dateiebene: `local x` ganz links, spaeter benutzt. Namen in
Zeichenketten und Kommentaren zaehlen nicht.

    python tools/check_lua.py cet/CompanionLeashVO/*.lua
"""
import re
import sys

BS = chr(92)


def entkleiden(src, offen=None):
    """Zeichenketten und Kommentare durch Leerzeichen ersetzen, Laenge erhalten.

    Nebenbei werden offene Zeichenketten gemeldet. Ein `"` das vor dem Zeilenende nicht
    wieder geschlossen wird, ist in Lua ein Syntaxfehler - erlaubt waere das nur mit
    `[[ ]]`. Genau das ist passiert, als ein `\\n` beim Erzeugen dieser Datei zu einem
    echten Umbruch wurde: die Datei sah heil aus, der Pruefer war zufrieden, und das Spiel
    hat die halbe Mod stillgelegt. Nach dem Muster suchen kostet nichts.
    """
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c in ('"', "'"):
            q = c
            beginn = i
            out.append(" ")
            i += 1
            while i < n and src[i] != q and src[i] != "\n":
                if src[i] == BS:
                    out.append(" ")
                    i += 1
                    if i >= n:
                        break
                out.append(" ")
                i += 1
            if i >= n or src[i] == "\n":
                if offen is not None:
                    offen.append(src.count("\n", 0, beginn) + 1)
                continue
            out.append(" ")
            i += 1
        elif c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(" ")
                i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def _tabellenschluessel(rein, start, ende):
    """`{ name = ...` oder `, name = ...` - ein Feldname, keine Variable."""
    nach = rein[ende:ende + 40].lstrip()
    if not nach.startswith("=") or nach.startswith("=="):
        return False
    vor = rein[max(0, start - 200):start].rstrip()
    return vor.endswith("{") or vor.endswith(",")


def pruefen(pfad):
    src = open(pfad, encoding="utf-8").read()
    offen = []
    rein = entkleiden(src, offen)
    kurz_ = pfad.replace(BS, "/").split("/")[-1]
    if offen:
        print("  %-14s %d NICHT GESCHLOSSENE ZEICHENKETTE(N):" % (kurz_, len(offen)))
        for zeile in offen:
            print("     Zeile %4d  %s" % (zeile, src.split("\n")[zeile - 1].strip()[:70]))
        return False

    #  Nur Deklarationen auf Dateiebene - alles andere ist ohnehin lokal begrenzt und
    #  wuerde hier bloss rauschen.
    deklariert = {}
    for m in re.finditer(r"^local(?:\s+function)?\s+([A-Za-z_][\w]*(?:\s*,\s*[A-Za-z_][\w]*)*)",
                         rein, re.M):
        for name in [x.strip() for x in m.group(1).split(",")]:
            deklariert.setdefault(name, m.start())

    treffer = []
    for name, wo in deklariert.items():
        #  Ein Punkt oder Doppelpunkt davor macht daraus einen FELDzugriff - `haltung.x`
        #  ist keine Nutzung des lokalen `x`. Ohne diese Bedingung meldet der Pruefer
        #  Namen, die zufaellig auch als Tabellenfeld vorkommen.
        for m in re.finditer(r"(?<![.:\w])%s\b" % re.escape(name), rein):
            if m.start() >= wo:
                break
            #  Und ein SCHLUESSEL in einem Tabellenliteral ist auch keiner: in
            #  `{ kampf = false }` steht der Name links von `=` und rechts von `{` oder
            #  `,`. Das ist ein Feldname, keine Variable - beide Ausnahmen kosten den
            #  Pruefer nichts an Trennschaerfe, weil ein echter Zugriff nie so aussieht.
            if _tabellenschluessel(rein, m.start(), m.end()):
                continue
            #  Die Deklarationszeile selbst nicht als Nutzung werten.
            zeile = src.count("\n", 0, m.start()) + 1
            treffer.append((zeile, name, src.split("\n")[zeile - 1].strip()[:70]))
            break

    kurz = pfad.replace(BS, "/").split("/")[-1]
    if not treffer:
        print("  %-14s %d Namen auf Dateiebene, keiner zu frueh benutzt"
              % (kurz, len(deklariert)))
        return True
    print("  %-14s %d BENUTZUNG(EN) VOR DER DEKLARATION:" % (kurz, len(treffer)))
    for zeile, name, text in sorted(treffer):
        print("     Zeile %4d  %-14s %s" % (zeile, name, text))
    return False


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    gut = True
    for p in sys.argv[1:]:
        if not pruefen(p):
            gut = False
    if not gut:
        raise SystemExit(1)


main()
