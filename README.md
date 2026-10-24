# Pet-Arenaa

## Android-app

`PetArena.apk` is de Android-app (Android 7.0 of nieuwer). Kopieer hem naar je telefoon en open hem
om te installeren (sta "installeren uit onbekende bronnen" toe).

De app opent met een menu waarin je kiest tussen Pet Arena, Halloween, Thanksgiving en Kerst, elk met
een eigen logo. Het app-icoon is de hondenmascotte. Alles werkt offline (lettertypes zitten in de app).

Opnieuw bouwen: `android/build.sh` (nodig: Java 17+, Maven, Python 3 met Pillow). Bewaar
`android/petarena.keystore`: updates moeten met dezelfde sleutel ondertekend worden, anders moet de app
eerst verwijderd worden (en ben je je voortgang kwijt).
