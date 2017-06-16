# "Will he stay or will he go?"

Die [Telekom Baskets Bonn](https://www.telekom-baskets-bonn.de) veröffentlichten diese Woche einen [Artikel](https://www.telekom-baskets-bonn.de/presse/background/fluktuation.html), in dem der prozentuale Anteil der Spieler berechnet wurde, die nach einer Saison im selben Verein verblieben.

Ich habe diese Zahlen versucht zu replizieren und zu berechnen, wie hoch der Anteil der verbliebenen Spieler ist, die im Schnitt über 15 Minuten pro Spiel spielten oder mehr als 5 Punkte erzielten. Diese Werte sind nämlich bedeutend, um zu verstehen, ob eher "Bankdrücker" oder "Leistungsträger" gehalten wurden.

Mein GitHub-[Repository](https://github.com/stefan-mueller/BBL) beinhaltet die genutzen [Rohdaten](https://github.com/stefan-mueller/BBL/tree/master/raw_data), webscraped von der [BBL-Website](http://easycredit-bbl.de), das [Skript](https://github.com/stefan-mueller/BBL/blob/master/code/01_recode_and_merge.R), das für die Umwandlung und Berechnungen geschrieben wurde, den finalen [Datensatz](https://github.com/stefan-mueller/BBL/blob/master/data/bbl_2012-2017.csv) auf der Ebene von Spieler und Saison sowie die Durschnittswerte [pro Saison](https://github.com/stefan-mueller/BBL/blob/master/data/ratios_2012-2017.csv) und [aggregiert](https://github.com/stefan-mueller/BBL/blob/master/data/ratios_aggregated.csv). Kommentare und Hinweise auf mögliche Fehler sind jederzeit willkommen. Schreibt mir einfach eine [E-Mail](mailto:mullers@tcd.ie).


Interessanterweise weichen meine Zahlen von denen der Baskets ab (siehe Anmerkungen unten). Kenner der jeweiligen Vereine können [hier](https://github.com/stefan-mueller/BBL/blob/master/data/bbl_2012-2017.csv) gerne nachschauen, ob bei ihrem jeweiligen Verein die Spieler korrekt kodiert wurden (ich habe dies für meine Telekom Baskets und zufallsweise für andere Vereine gecheckt). Hierbei ist die Spalte `stayed` zu beachten: Wenn `stayed` den Wert 1 hat, heißt dies, dass der Spieler auch in der Vorsaison bei dem selben Club gespielt hat. Eine 0 impliziert, dass der Spieler neu verpflichtet wurde. Die Statistiken basieren ausschließlich auf den gelieferten Daten der BBL. Alle Änderungen, die vornegenommen wurde, um die Berechnungen vorzunehmen, können in [diesem R-Skript](https://github.com/stefan-mueller/BBL/blob/master/code/01_recode_and_merge.R) nachverfolgt werden.

## Durchschnittliche Fluktuation der vergangenen fünf Spielzeiten
![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/ratio_total.jpg)

## Aufschlüsselung pro Saison

![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/ratio_1617.jpg)

![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/ratio_1516.jpg)

![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/ratio_1415.jpg)

![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/ratio_1314.jpg)

![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/ratio_1213.jpg)

Mit dem neuen Datensatz lässt sich außerdem überprüfen, wie sich der prozentuale Anteil der "gehaltenen Spieler" vereinsübergreifend entwickelt hat. Hierzu berechne ich den Mittelwert aller Vereine pro Saison. Interesssanterweise ist _kein_ eindeutiger Trend festzustellen. In allen Saisons (Ausnahme ist 2014/15) wurden weniger "Leistungsträger" (gemessen in Form von Minuten und/oder Punkten) gehalten. Nur 2014/15 war der Anteil der gehaltenen Spielern mit >15 Minuten minimal höher als die Gesamt-Prozentzahl. Die Werte schwanken zwischen 30 und 47 Prozent, wobei die Saison 2014/15 ein Ausreißer nach oben ist. Die schwarze vertikale Linie zeigt den Mittelwert aller Saisons, der laut meinen Berechnungen bei etwas weniger als 40 Prozent des Kaders liegt.


![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/comparison_per_season.jpg)



Ein paar Anmerkungen zur Berechnung:

* Es sind lediglich Spieler einbezogen, die über die ganze Saison hinweg mindestens eine Minute auf dem Feld standen.

* Bei Spielern, die während der Saison innerhalb der BBL wechselten, wurde der Club ausgewählt, für den ein Spieler mehr Spiele absolviert hat.

* Während der Saison nachverpflichte Spieler fließen ebenfalls in die Statistik als potentielle verbliebene Spieler ein.

* Wenn ein Verein aus der ProA aufsteigt, beinhaltet die Seite der BBL keine Angaben über Statistiken aus der Vorsaison. Teams in der ersten Saison nach dem Aufstieg sind daher nicht berücksichtigt.

* Der Gesamtanteil von verbliebenen Spielern pro Saison bezieht sich nur auf die Anzahl an Saisons, die dieser Verein zwischen 2012/13 und 2016/17 in der BBL gespielt hat.

* Falls ein Club zwischen 2012 und 2017 den Vereinsnamen geändert hat, wurde die aktuellst Bezeichnung auf alle vergangenen Saisons angewendet. 

Wenn ich nun die aggregierten Zahlen meiner Berechnung mit denen der Telekom Baskets Bonn vergleiche, fällt auf, dass die Korrelation nicht perfekt ist (dann wären alle Punkte auf der diagonalen gestrichelten Linie). Der Korrelationskoeffizient beträgt 0.85. Bei der Berechnung scheint es also Unterschiede gegeben zu haben. Allerdings sind die von mir berechneten Werte tendenziell noch etwas höher als die Werte, die die Telekom Baskets [vermelden](https://www.telekom-baskets-bonn.de/presse/background/fluktuation.html). Die Grundaussage der Baskets bleibt damit unverändert.

![](https://raw.githubusercontent.com/stefan-mueller/BBL/master/output/comparison_ratios.jpg)
