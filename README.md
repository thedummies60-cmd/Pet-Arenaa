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

## Skydrop Royale (battle royale, één HTML-bestand)

`Skydrop_Royale.html` is een eigen 3D battle-royale-spel. Open het bestand in Chrome, Edge of Firefox op een
computer (toetsenbord + muis, internet nodig voor Three.js en het vriendensysteem).

- Lobby met kluisje (7 eigen skins, waaronder **Crimson Nocturne** en **Kapitein Koala**, en 3 zweefvliegers), dagelijkse opdrachten, levels en carrière.
- Eiland met 10 plekken, rivieren, bruggen, sneeuwbergen, herfstbos, bloesemheuvel, kermis met reuzenrad, doolhof en meer.
- Springen uit het luchtschip, zweefvliegen, loot en kisten, 5 wapens met zeldzaamheden, genezen, schild, bouwen (muur/vloer/helling), materialen hakken, storm, 23 bots.
- **Vrienden & Duo**: deel je vriendcode (tabblad VRIENDEN), accepteer het verzoek, nodig uit en speel samen DUO. Beide spelers moeten het spel open hebben.

Besturing: WASD lopen · muis kijken · Shift sprinten · Spatie springen/zweefvlieger · linkermuis schieten · rechtermuis richten ·
R herladen · 1-5 wapens · F houweel · Q bouwen (1 muur, 2 vloer, 3 helling, G materiaal) · E oppakken/kist/helpen · M kaart · B dansje.
