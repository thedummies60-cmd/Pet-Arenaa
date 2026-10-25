# Pet-Arenaa

## Android-app

In de map **`Pet Arena APK`** staan de Android-apps (Android 7.0 of nieuwer):

| Bestand | Wat |
|---|---|
| `Pet Arena (alle versies).apk` | Menu met alle 4 de arena's |
| `Pet Arena.apk` | Gewone versie (hond-logo) |
| `Pet Arena Halloween.apk` | Halloween (pompoen-logo) |
| `Pet Arena Thanksgiving.apk` | Thanksgiving (kalkoen-logo) |
| `Pet Arena Kerst.apk` | Kerst (sneeuwman-logo) |

Elke app kan naast de andere geïnstalleerd worden. Download er een op je telefoon, open hem en sta
"installeren uit onbekende bronnen" toe. Alles werkt offline.

Opnieuw bouwen: `android/build.sh` (nodig: Java 17+, Maven, Python 3 met Pillow). Bewaar
`android/petarena.keystore`: updates moeten met dezelfde sleutel ondertekend worden, anders moet de app
eerst verwijderd worden (en ben je je voortgang kwijt).
