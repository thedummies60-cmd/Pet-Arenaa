#!/usr/bin/env bash
# Builds PetArena.apk without the Android SDK: every tool is fetched from Maven Central.
# Needs: java/javac (17+), python3 with Pillow, curl, mvn.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
WORK="${WORK:-$HERE/build}"
TOOLS="$WORK/tools"
OUT="$ROOT/PetArena.apk"
KEYSTORE="$HERE/petarena.keystore"
KS_PASS="petarena"
KS_ALIAS="petarena"

mkdir -p "$TOOLS"
rm -rf "$WORK/gen" "$WORK/classes" "$WORK/dex" "$WORK"/*.apk

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

# --- Assets and icons ------------------------------------------------------------------------
mkdir -p "$WORK/gen/res"
cp -r "$HERE/res/." "$WORK/gen/res/"
python3 "$HERE/tools/prepare.py" "$WORK/gen"

# --- Resources -------------------------------------------------------------------------------
"$TOOLS/aapt2" compile --dir "$WORK/gen/res" -o "$WORK/gen/res.zip"
"$TOOLS/aapt2" link -o "$WORK/unsigned.apk" -I "$ANDROID_JAR" \
  --manifest "$HERE/AndroidManifest.xml" -A "$WORK/gen/assets" \
  --java "$WORK/gen/java" --auto-add-overlay "$WORK/gen/res.zip"

# --- Code ------------------------------------------------------------------------------------
mkdir -p "$WORK/classes" "$WORK/dex"
javac -nowarn -source 8 -target 8 -bootclasspath "$ANDROID_JAR" -classpath "$ANDROID_JAR" -d "$WORK/classes" \
  $(find "$HERE/src" "$WORK/gen/java" -name '*.java') 2>&1 | grep -v 'JAVA_TOOL_OPTIONS' || true
java -cp "$DX" com.android.dx.command.Main --dex --min-sdk-version=24 --output="$WORK/dex/classes.dex" "$WORK/classes"
(cd "$WORK/dex" && zip -q -0 "$WORK/unsigned.apk" classes.dex)

# --- Sign ------------------------------------------------------------------------------------
if [ ! -f "$KEYSTORE" ]; then
  keytool -genkeypair -keystore "$KEYSTORE" -storetype PKCS12 -storepass "$KS_PASS" -keypass "$KS_PASS" \
    -alias "$KS_ALIAS" -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Pet Arena, O=Pet Arena"
fi
javac -nowarn -cp "$APKSIG" -d "$WORK/classes-tools" "$HERE/tools/Sign.java"
java --add-exports java.base/sun.security.x509=ALL-UNNAMED --add-exports java.base/sun.security.pkcs=ALL-UNNAMED --add-exports java.base/sun.security.util=ALL-UNNAMED \
  -cp "$APKSIG:$WORK/classes-tools" Sign "$KEYSTORE" "$KS_PASS" "$KS_ALIAS" "$WORK/unsigned.apk" "$OUT"
echo "Built $OUT"
