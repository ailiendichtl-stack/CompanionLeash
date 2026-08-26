//  Judy in den Aufzug bekommen.
//
//  Beobachtet: sie folgt V nicht in Aufzuege. Damit ist alles ausser dem Erdgeschoss
//  unerreichbar, solange sie dabei sein soll - der Weg ins Apartment ging zuletzt nur
//  ueber Schnellreise, was sie neu spawnt.
//
//  Die Ursache steht in NCA selbst, in `Npc/Hooks/NpcHooks.reds`, samt Erklaerung:
//
//      Lifts only ever enable the PLAYER half of their off-mesh link
//      (LiftDevice.EnableOffMeshConnections), while doors enable both halves.
//      Mirror the door behaviour so followers can path through a lift.
//
//  Der Fix steht dort fertig daneben - auskommentiert. Warum, wissen wir nicht; er kann
//  unfertig sein oder Aerger gemacht haben. Deshalb liegt er hier in einer EIGENEN Datei
//  und nicht in einer bestehenden: wer ihn loswerden will, loescht genau diese eine Datei,
//  ohne an der Leine oder den Kommandos vorbeizumuessen.
//
//  Sollte NCA den Block eines Tages selbst aktivieren, kollidieren zwei `@wrapMethod` auf
//  derselben Methode nicht - sie stapeln sich. Die Verbindung waere dann doppelt
//  eingeschaltet, was nichts kaputtmacht, aber diese Datei ueberfluessig.

module CompanionLeash.Lift

//  Aufzuege schalten nur die SPIELER-Haelfte ihrer Off-Mesh-Verbindung frei; Tueren
//  schalten beide. Ohne die NPC-Haelfte findet die Wegfindung schlicht keinen Weg hinein,
//  und die Begleiterin bleibt davor stehen - kein Fehler, den man im Log sieht, sondern
//  eine Kante, die es fuer sie nie gab.
@wrapMethod(LiftDevice)
protected final func EnableOffMeshConnections() -> Void {
    wrappedMethod();
    if IsDefined(this.m_offMeshConnectionComponent) {
        this.m_offMeshConnectionComponent.EnableOffMeshConnection();
    }
}

//  Und wieder zu, sobald der Aufzug faehrt. Ohne das bliebe eine Verbindung offen, die
//  ins Leere zeigt - die Kabine ist dann nicht mehr da, wo die Kante hinfuehrt.
@wrapMethod(LiftDevice)
protected final func DisableOffMeshConnections() -> Void {
    wrappedMethod();
    if IsDefined(this.m_offMeshConnectionComponent) {
        this.m_offMeshConnectionComponent.DisableOffMeshConnection();
    }
}
