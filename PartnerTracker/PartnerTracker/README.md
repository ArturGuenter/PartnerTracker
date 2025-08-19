# PartnerTracker – Aufgabenmanagement für Gruppen & Einzelpersonen

## 📌 Beschreibung
**PartnerTracker** ist eine Aufgaben- & To-Do-App, die es Nutzern ermöglicht, sowohl persönliche Aufgaben als auch Gruppenaufgaben effizient zu verwalten.  
Die App eignet sich ideal für **Paare, Teams, Freundeskreise oder Projektgruppen**, die ihre Aufgaben gemeinsam im Blick behalten wollen.

---

## ✨ Funktionen

### 1. Persönliche Aufgaben
- Eigene Aufgaben erstellen, abhaken, bearbeiten und löschen  
- Jede Aufgabe besitzt ein **Reset-Intervall**:
  - **Täglich** → wird jeden Tag zurückgesetzt  
  - **Wöchentlich** → wird jede Woche zurückgesetzt  
  - **Nie** → bleibt erledigt, bis sie manuell geändert wird  
- Automatische Startaufgabe: *"App öffnen"* (falls der Nutzer noch keine Aufgaben hat)

### 2. Gruppenaufgaben
- Gruppen erstellen oder bestehenden Gruppen beitreten  
- Gemeinsame Aufgabenverwaltung für alle Mitglieder  
- Alle können Aufgaben abhaken und bearbeiten  
- Löschen ist nur für den Ersteller möglich  
- Auch Gruppenaufgaben besitzen das Reset-Intervall

### 3. Aufgaben bearbeiten
- **Titel ändern**  
- **Intervall ändern** (täglich, wöchentlich, nie)  

### 4. Fortschritt & Statistiken
- Anzeige erledigter Aufgaben (persönlich & Gruppe)  
- Gesamtfortschritt über alle Aufgaben hinweg  
- **Heatmap-Ansicht**:
  - Visualisierung der täglichen Aktivität ähnlich wie bei GitHub-Contributions  
  - Wochentage sind am Rand beschriftet  
  - Kästchen färben sich grün je nach Anzahl erledigter Aufgaben pro Tag  
  - Navigation durch verschiedene Monate möglich  

---

## 🔄 Wie funktioniert die App?

### Einloggen
- Anmeldung mit **Firebase Authentication**

### Aufgaben erstellen
- Persönliche Aufgaben für sich selbst  
- Gruppenaufgaben nach Beitritt oder Erstellung einer Gruppe  

### Aufgaben verwalten
- Abhaken, sobald sie erledigt sind  
- Intervalle über Picker auswählen (täglich, wöchentlich, nie)  

### Reset-Logik
- Aufgaben werden je nach **resetInterval** automatisch zurückgesetzt  
- Beispiel: tägliche Aufgaben → jeden Tag wieder offen  

### Zusammenarbeit in Gruppen
- Gruppenaufgaben sind für alle sichtbar  
- Bearbeitung durch alle möglich  
- Verwaltung über **Gruppennamen + Passwort**

### Bearbeiten & Löschen
- Aufgaben jederzeit anpassbar  
- Löschen abhängig vom Ersteller  

---

## 🛠️ Technologie & Architektur
- **SwiftUI** Frontend  
- **Firebase Firestore** Backend mit Echtzeit-Synchronisation  
- Datenmodell:
  - `TaskItem` → Felder: *title, isDone, resetInterval, groupId, lastDoneAt*  
  - `Group` → Gruppenzugehörigkeiten  
- Fortschritt & Historie in Firestore gespeichert (Datumsschlüssel `yyyy-MM-dd`, lokal konsistent)  

---

## 🎯 Beispielanwendungen
- **Pärchen-Tracker**: Wer hat heute den Müll rausgebracht?  
- **Teamaufgaben**: Wer bereitet das Meeting vor?  
- **Routinen**: Tägliche oder wöchentliche Aufgaben gemeinsam managen  

---

## 🏆 Ziel der App
- **Gemeinsame Organisation** von Aufgaben  
- **Klare Übersicht** für Einzelpersonen & Gruppen  
- **Automatischer Reset** für wiederkehrende Routinen  
- **Motivation durch Fortschritts-Heatmap**


