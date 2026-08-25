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


def entkleiden(src):
    """Zeichenketten und Kommentare durch Leerzeichen ersetzen, Laenge erhalten."""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c in ('"', "'"):
            q = c
            out.append(" ")
            i += 1
            while i < n and src[i] != q:
                if src[i] == BS:
                    out.append(" ")
                    i += 1
                out.append(" " if src[i] != "\n" else "\n")
                i += 1
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


def pruefen(pfad):
    src = open(pfad, encoding="utf-8").read()
    rein = entkleiden(src)

    #  Nur Deklarationen auf Dateiebene - alles andere ist ohnehin lokal begrenzt und
    #  wuerde hier bloss rauschen.
    deklariert = {}
    for m in re.finditer(r"^local(?:\s+function)?\s+([A-Za-z_][\w]*(?:\s*,\s*[A-Za-z_][\w]*)*)",
                         rein, re.M):
        for name in [x.strip() for x in m.group(1).split(",")]:
            deklariert.setdefault(name, m.start())

    treffer = []
    for name, wo in deklariert.items():
        for m in re.finditer(r"\b%s\b" % re.escape(name), rein):
            if m.start() >= wo:
                break
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
