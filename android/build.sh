#!/usr/bin/env bash
# Builds the Pet Arena APKs (one with every arena, plus one per arena) without the Android SDK: every tool is fetched from Maven Central.
# Needs: java/javac (17+), python3 with Pillow, curl, mvn.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
WORK="${WORK:-$HERE/build}"
TOOLS="$WORK/tools"
OUT_DIR="$ROOT/Pet Arena APK"
KEYSTORE="$HERE/petarena.keystore"
KS_PASS="petarena"
KS_ALIAS="petarena"

mkdir -p "$TOOLS"
rm -rf "$WORK"/gen* "$WORK/classes" "$WORK/dex"

# --- Tools ---------------------------------------------------------------------------------
if [ ! -f "$TOOLS/android.jar" ]; then
  curl -sSfL -o "$TOOLS/android.jar" \
    https://raw.githubusercontent.com/Sable/android-platforms/master/android-33/android.jar
fi
mvn -q dependency:get -Dartifact=org.apktool:apktool-lib:3.0.3 -Dtransitive=false
mvn -q dependency:get -Dartifact=com.jakewharton.android.repackaged:dalvik-dx:16.0.1 -Dtransitive=false
mvn -q dependency:get -Dartifact=com.android.tools.build:apksig:2.3.0 -Dtransitive=false
M2="$HOME/.m2/repository"
DX="$M2/com/jakewharton/android/repackaged/dalvik-dx/16.0.1/dalvik-dx-16.0.1.jar"
APKSIG="$M2/com/android/tools/build/apksig/2.3.0/apksig-2.3.0.jar"
if [ ! -x "$TOOLS/aapt2" ]; then
  unzip -o -q -j "$M2/org/apktool/apktool-lib/3.0.3/apktool-lib-3.0.3.jar" prebuilt/linux/aapt2 -d "$TOOLS"
  chmod +x "$TOOLS/aapt2"
fi
ANDROID_JAR="$TOOLS/android.jar"

# --- Code (shared by every app) ---------------------------------------------------------------
mkdir -p "$WORK/classes" "$WORK/dex"
javac -nowarn -source 8 -target 8 -bootclasspath "$ANDROID_JAR" -classpath "$ANDROID_JAR" -d "$WORK/classes" \
  $(find "$HERE/src" -name '*.java') 2>&1 | grep -v -e 'JAVA_TOOL_OPTIONS' -e '^Note:' || true
java -cp "$DX" com.android.dx.command.Main --dex --min-sdk-version=24 --output="$WORK/dex/classes.dex" "$WORK/classes"

if [ ! -f "$KEYSTORE" ]; then
  keytool -genkeypair -keystore "$KEYSTORE" -storetype PKCS12 -storepass "$KS_PASS" -keypass "$KS_PASS" \
    -alias "$KS_ALIAS" -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Pet Arena, O=Pet Arena"
fi
javac -nowarn -cp "$APKSIG" -d "$WORK/classes-tools" "$HERE/tools/Sign.java"

# --- One app per variant ---------------------------------------------------------------------
# variant  package  apk name
VARIANTS="all:com.petarena.app:Pet Arena (alle versies)
normaal:com.petarena.normaal:Pet Arena
halloween:com.petarena.halloween:Pet Arena Halloween
thanksgiving:com.petarena.thanksgiving:Pet Arena Thanksgiving
kerst:com.petarena.kerst:Pet Arena Kerst"

mkdir -p "$OUT_DIR"
while IFS=: read -r VARIANT PACKAGE NAME; do
  GEN="$WORK/gen-$VARIANT"
  rm -rf "$GEN" && mkdir -p "$GEN/res"
  cp -r "$HERE/res/." "$GEN/res/"
  python3 "$HERE/tools/prepare.py" "$GEN" "$VARIANT"

  "$TOOLS/aapt2" compile --dir "$GEN/res" -o "$GEN/res.zip"
  "$TOOLS/aapt2" link -o "$GEN/unsigned.apk" -I "$ANDROID_JAR" \
    --manifest "$HERE/AndroidManifest.xml" --rename-manifest-package "$PACKAGE" \
    -A "$GEN/assets" --auto-add-overlay "$GEN/res.zip"
  (cd "$WORK/dex" && zip -q -0 "$GEN/unsigned.apk" classes.dex)

  java --add-exports java.base/sun.security.x509=ALL-UNNAMED --add-exports java.base/sun.security.pkcs=ALL-UNNAMED \
    --add-exports java.base/sun.security.util=ALL-UNNAMED \
    -cp "$APKSIG:$WORK/classes-tools" Sign "$KEYSTORE" "$KS_PASS" "$KS_ALIAS" "$GEN/unsigned.apk" "$OUT_DIR/$NAME.apk"
  echo "Built $OUT_DIR/$NAME.apk"
done <<< "$VARIANTS"
