# Hardwarepraktikum SoSe26

**ausführliche Informationen auf gesonderter Anleitung im ISIS-Kurs**

## Repository einrichten
1. Lokal klonen (siehe unten)
2. Im Ordner *make setup* ausführen
3. Den Anweisungen folgen

## GIT
* Git ist eine Versionierungssoftware wie z.B. SVN
* Git ist dezentral (es gibt zunächst erstmal keinen Server, der einem Dinge vorschreibt)
* ein Git-Repository ist eine Sammlung von **Commits**
* ein **Commit** ist eine Zusammenfassung von Änderungen

### Workflow

* etwas 'hochladen': Datei **X** hat Änderungen oder ist neu
 1. *git add X*: fügt die Datei zum nächsten **Commit** hinzu
 2. *git status*: überprüfen, ob wirklich nur die gewünschten Dateien in den **Commit** kommen
 3. *git diff --staged*: optional: Überprüfung, welche Änderungen vorgenommen werden
 5. *git commit -m "**X wurde aktualisiert**"*: erzeugt den **Commit** mit dem Kommentar "**X wurde aktualisiert**"
   * dieser **Commit** wurde nun aussschließlich im lokalen Repository erstellt
 6. *git push*: sendet die neue **Commits** zum Server


* lokales Repoitory aktualisieren
 1. *git status*: überprüfen, ob man selbst ein *sauberes* Repository hat (keine ungesicherten Änderungen)
 2. *git pull: holt neue **Commits** vom Server
 3. Es kann nun zu einem **Merge conflict** kommen
   * Die neuen Änderungen lassen sich nicht auf die lokalen Daten anwenden
   * Es muss nun ein *Merge Commit* gemacht werden
      1. Git hat automatische alle unbetroffenen Dateien zu diesem Commit hinzugefügt
      2. Mit *git status* überprüfen, welche Dateien betroffen sind
      3. Die Dateien öffnen und schauen, welche Änderungen nicht umsetztbar sind
      4. Sich für eine Variante entscheiden (im Notfall fragen)
      5. Mit *git add* die betroffenen Dateien zum *merge Commit* hinzufügen
      6. *git commit*

### wichtige Git-Befehle
| Befehl                         | Beschreibung
| :----------------------------- | :-------------
| git clone *repo-uri*           | Kopiert (klont) ein vorhandenes Repository auf den lokalen Rechner
| git status                     | Zeigt den Status aller Änderungen an und welche zum nächsten Commit gehören
| git add *datei*                | Fügt Änderungen (und neu Dateien) zu dem nächsten Commit hinzu
| git reset *datei*              | Entfernt Dateien vom nächsten Commit, welche mit add hinzugefügt worden sind
| git diff                       | Listet alle Änderungen, welche in keinem Commit sind
| git diff --staged              | Listet alle Änderungen, welche mit *git add* hinzugefügt worden sind
| git rm *datei*                 | Entfernt die Datei aus Git und löscht sie auch lokal.
| git commit -m "*Beschreibung*“ | Fasst alle vorgemerkten Änderungen (git add) zu einem commit zusammen mit der angegebenen Beschreibung.
| git pull                       | Holt sich neu Commits vom Mutter-Repository.
| git push                       | Lädt lokale Commits zum Mutter-Repository hoch.
| git checkout main -- *datei*           | Setzt alle Änderungen der Datei auf den Stand des letzten Commits zurück.
| git reset			 | Macht git add rückgängig
| git reset --hard		 | Löscht alle lokalen Änderungen seit dem letzten Commit (**Vorsicht!**)
| git pull vorgaben main       | Lädt geänderte Vorlagen aus dem Vorgaben-Repository
