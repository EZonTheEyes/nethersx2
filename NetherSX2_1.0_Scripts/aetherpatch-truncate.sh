#!/bin/bash

PATCHED_APP_NAME="NetherSX2"

# ----Pre-checks----
IS_TERMUX="0"

acquire_apk() {
  OUT_APK="$1"
  if [ -z "$OUT_APK" ]; then
    OUT_APK="15210-v1.5-4248.apk"
  fi
  if true; then
    echo "Downloading APK..."
    if ! wget "https://www.aethersx2.com/archive/android/alpha/15210-v1.5-4248.apk" -O "$OUT_APK"; then
      return 1;
    fi
  else
    echo "Extracting APK..."
    AETHERSX2_LINE=$(awk '/^__AETHERSX2_BEGINS__/ { print NR + 1; exit 0; }' $0)
    if ! tail -n "+${AETHERSX2_LINE}" "$0" > "$OUT_APK"; then
      return 1;
    fi
  fi
  return 0
}

check_tools() {
  required_tools=(
    "xmlstarlet"
    "apktool"
    "apksigner"
    "keytool"
    "zipalign"
    "wget"
    "gm"
  )
  for cmd in "${required_tools[@]}"; do
    $cmd >/dev/null 2>/dev/null
    if [ "$?" -eq 127 ]; then
      echo "Required tool or alias $cmd not found"
      return 1
    fi
  done
  return 0
}

echo "Patcher start!"

if termux-setup-storage --help >/dev/null 2>/dev/null && apt -v >/dev/null 2>/dev/null; then
  echo "Checking tools (Termux)..."
  if ! check_tools; then
    if apt update && apt upgrade -o Dpkg::Options::="--force-confold" -y; then
      apt install -y xmlstarlet graphicsmagick which wget
      if ! which apktool || ! which apksigner || ! which keytool || ! which zipalign; then
        if ! curl -s https://raw.githubusercontent.com/rendiix/termux-apktool/main/install.sh | bash ; then
          echo "Failed to install apktool"
          exit 101
        fi
      fi
    else
      echo "This looks like termux, but apt upgrade failed."
      exit 100
    fi
  fi
  IS_TERMUX="1"
fi

echo "Checking tools (Final)..."
if ! check_tools; then
  echo "Exiting due to missing required tool"
  exit 1
fi

APK_FILE=""
# --Termux-specific--
if [ -z "$1" ]; then
  TERMUX_SHARED="$HOME/storage/shared"
  if [ "$IS_TERMUX" -eq "1" ]; then
    if [ ! -d "$TERMUX_SHARED" ] || ! ls "$TERMUX_SHARED" >/dev/null 2>/dev/null; then
      echo "Requesting storage setup..."
      termux-setup-storage
      for i in $(seq 20); do
        if [ -d "$TERMUX_SHARED" ] && ls "$TERMUX_SHARED" >/dev/null 2>/dev/null; then
          break
        fi
        sleep 1
      done
      if [ ! -d "$TERMUX_SHARED" ] || ! ls "$TERMUX_SHARED" >/dev/null 2>/dev/null; then
        echo "Shared storage not found!"
        exit 102
      fi
    fi
    mkdir -p "$TERMUX_SHARED/$PATCHED_APP_NAME"
    if ! acquire_apk "$TERMUX_SHARED/$PATCHED_APP_NAME/15210-v1.5-4248.apk"; then
      echo "Failed to download aethersx2!"
      exit 103
    fi
    APK_FILE="$TERMUX_SHARED/$PATCHED_APP_NAME/15210-v1.5-4248.apk"
  else
    if ! acquire_apk; then
      echo "Failed to download aethersx2!"
      exit 103
    fi
    APK_FILE="15210-v1.5-4248.apk"
  fi
elif [ ! -f "$1" ]; then
  echo "Required APK file '$1' not passed or not found!"
  exit 2
else
  APK_FILE="$1"
fi

# --End Termux-specific--

# ----End Pre-checks----

TMPDIR=`mktemp -d`
WORKDIR="$TMPDIR/work"
APK_NAME=$(basename -- "$APK_FILE")
APK_DIR=$(dirname -- "$APK_FILE")

# ----Decompile----
CLASSES_HASH="8a0c195898418c3310768873f4a10b14be325f5faa60dc1d4e9af24a3026ddce"
CLASSES_PATH="classes.dex"
NATIVE_LIB_HASH="10f659b0d30adea8162b6dd8daeeeb480fafb1e25df5752aa1dd227c0b7a3da0"
NATIVE_LIB_PATH="lib/arm64-v8a/libemucore.so"
if ! apktool d -s -o "$WORKDIR" "$APK_FILE"; then
  echo "apktool failed"
  exit 3
fi
echo -e "$CLASSES_HASH $WORKDIR/$CLASSES_PATH\n$NATIVE_LIB_HASH $WORKDIR/$NATIVE_LIB_PATH" | sha256sum --check --status
if [ "$?" -ne 0 ]; then
  echo "Found unsupported APK (only 15210-v1.5-4248) is supported!"
  exit 4
fi
# ----End Decompile----

# ----Patches----

# --Manifest Cleanup--
MANIFEST_PATH="AndroidManifest.xml"
manifest_remove=(
  "manifest/uses-permission[@android:name='android.permission.ACCESS_NETWORK_STATE' or @android:name='com.google.android.gms.permission.AD_ID' or @android:name='android.permission.WAKE_LOCK' or @android:name='android.permission.FOREGROUND_SERVICE']"
  "manifest/queries"
  "manifest/application/service"
  "manifest/application/receiver"
  "manifest/application/meta-data[@android:name='com.google.android.gms.ads.APPLICATION_ID' or @android:name='com.google.android.gms.version']"
  "manifest/application/provider/meta-data[@android:name='androidx.work.WorkManagerInitializer']"
  "manifest/application/activity[@android:name='com.google.android.gms.ads.AdActivity' or @android:name='com.google.android.gms.version' or @android:name='com.google.android.gms.common.api.GoogleApiActivity' or @android:name='com.google.android.gms.ads.OutOfContextTestingActivity']"
  "manifest/application/provider[@android:name='com.google.android.gms.ads.MobileAdsInitProvider']"
  "manifest/application/activity/@android:preferMinimalPostProcessing"
  "manifest/application/@android:extractNativeLibs"
)

for xpath in "${manifest_remove[@]}"; do
  xmlstarlet ed -L -d "$xpath" "$WORKDIR/$MANIFEST_PATH"
done
xmlstarlet ed -L -u "manifest/application/@android:label" -v "$PATCHED_APP_NAME" "$WORKDIR/$MANIFEST_PATH"
xmlstarlet ed -L -u "manifest/application/activity[@android:label='AetherSX2']/@android:label" -v "$PATCHED_APP_NAME" "$WORKDIR/$MANIFEST_PATH"
# --End Manifest Cleanup--

# --Main Activity Layout Cleanup--
MAIN_LAYOUT_PATH="res/layout/activity_main.xml"
xmlstarlet ed -L -d "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/RelativeLayout/FrameLayout/@android:layout_above" "$WORKDIR/$MAIN_LAYOUT_PATH"
xmlstarlet ed -L -a "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/RelativeLayout/FrameLayout" -t attr -n "android:layout_alignParentBottom" -v "true" "$WORKDIR/$MAIN_LAYOUT_PATH"
xmlstarlet ed -L -d "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/RelativeLayout/com.google.android.gms.ads.AdView" "$WORKDIR/$MAIN_LAYOUT_PATH"
xmlstarlet ed -L -u "androidx.drawerlayout.widget.DrawerLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/com.google.android.material.floatingactionbutton.FloatingActionButton/@android:layout_marginBottom" -v "16.0dip" "$WORKDIR/$MAIN_LAYOUT_PATH"
# --End Main Activity Layout Cleanup--

# --aapt2 Build Fix--
sed -i 's/@android:color/@*android:color/g' "$WORKDIR/res/values-v31/colors.xml"
# --End aapt2 Build Fix--

# --Update Licensing Information--
LICENSE_PATH="assets/3rdparty.html"
sed -i '4i\
<h1>AetherSX2 Violates the LGPLv3</h1>\
<p>This app is not actually LGPL compliant.</p>\
<p>While the original author claims that LGPL-compliant source is available at <a href="https://www.aethersx2.com/lgpl/aethersx2-lgpl.tar.gz">https://www.aethersx2.com/lgpl/aethersx2-lgpl.tar.gz</a>, closer examination shows that this source tarball does not correspond to the current release, and is in reality very outdated.</p>\
<p>Demand the original author do better by sending them an email at <a href="android@aethersx2.com">android@aethersx2.com</a></p>\
<p>Original Third Party license information follows below</p>' "$WORKDIR/$LICENSE_PATH"
# --End Update Licensing Information--

# --Icons--
for i in "$WORKDIR"/res/mipmap*/{ic_launcher.png,ic_launcher_foreground.png,ic_launcher_round.png,logo.png}; do
  gm convert "$i" -colorspace HSL -modulate 80,120,170 -colorspace sRGB "$i"
done
# --End Icons--


# --Patch Native Library--
# Patch signature checks
echo -n -e "\x66\x00\x00\x14" | dd bs=1 conv=notrunc seek=$((0x838560)) of="$WORKDIR/$NATIVE_LIB_PATH"
echo -n -e "\x62\x00\x00\x14" | dd bs=1 conv=notrunc seek=$((0x83B324)) of="$WORKDIR/$NATIVE_LIB_PATH"

# Patch BIOS type check
echo -n -e "\x35\x00\x80\x52" | dd bs=1 conv=notrunc seek=$((0x829248)) of="$WORKDIR/$NATIVE_LIB_PATH"
# --End Patch Native Library--

# --Patch DEX--

# Disable ads
echo -n -e "\x0e\x00" | dd bs=1 conv=notrunc seek=$((0x222264)) of="$WORKDIR/$CLASSES_PATH"
echo -n -e "\x0e\x00" | dd bs=1 conv=notrunc seek=$((0x3C5B70)) of="$WORKDIR/$CLASSES_PATH"

# Restore Launcher support
echo -n -e "\x12\x11" | dd bs=1 conv=notrunc seek=$((0x3BDAA4)) of="$WORKDIR/$CLASSES_PATH"
dd bs=1 conv=notrunc if="$WORKDIR/$CLASSES_PATH" skip=$((0x3C5A24)) seek=$((0x3BDAA6)) of="$WORKDIR/$CLASSES_PATH" count=14
echo -n -e "\x04" | dd bs=1 conv=notrunc seek=$((0x3BDAAA)) of="$WORKDIR/$CLASSES_PATH"
echo -n -e "\x05" | dd bs=1 conv=notrunc seek=$((0x3BDAAD)) of="$WORKDIR/$CLASSES_PATH"
echo -n -e "\x15" | dd bs=1 conv=notrunc seek=$((0x3BDAB2)) of="$WORKDIR/$CLASSES_PATH"
echo -n -e "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" | dd bs=1 conv=notrunc seek=$((0x3BDAB4)) of="$WORKDIR/$CLASSES_PATH"

# Fix checksum
echo -n -e "\xdd\xa2\x21\x3a" | dd bs=1 conv=notrunc seek=$((0x8)) of="$WORKDIR/$CLASSES_PATH"
# --End Patch Native Library--
# ----End Patches----

# ----Build and Sign----
# Rebuild APK

# Generate keystore
echo y | keytool -genkeypair -dname "cn=GNU LGPLv3, ou=GNU LGPLv3, o=GNU LGPLv3, c=XX" -alias gnulgplv3 -keypass gnulgplv3 -keystore "$TMPDIR/android.keystore" -storepass gnulgplv3 -keyalg RSA -keysize 2048 -validity 10000
apktool b --use-aapt2 -o "$WORKDIR/dist/1.apk" "$WORKDIR"
zipalign -f -v 4 "$WORKDIR/dist/1.apk" "$WORKDIR/dist/2.apk"
echo "gnulgplv3" | apksigner sign --ks "$TMPDIR/android.keystore" "$WORKDIR/dist/2.apk" > /dev/null
cp "$WORKDIR/dist/2.apk" "$APK_DIR/${APK_NAME%.*}-noads.apk" 
echo "Done! Output APK should be in " $(readlink -f "$APK_DIR")
rm -r "$TMPDIR"

if [ "$IS_TERMUX" -eq "1" ]; then
  # Try to open a file browser to the created folder
  termux-open-url "content://com.android.externalstorage.documents/document/primary%3ANetherSX2"
fi
# ----End Build and Sign----

exit 0
# USE TRUNCATED AT END USERS DISCRETION, IT IS SUGGESTED TO CURL FULL FROM OTHER OFFICIAL HOSTS, OR RUN LOCALLY
# THE FOLLOWING OPINIONS AND STATEMENTS EXPRESSED ARE BY THE SCRIPT AUTHOR, NOT THE DSITRIBUTOR. 
# AS THE SOLE AUTHOR REMAINS ANONYMOUS, NO REDISTRIBUTOR IS TO BE QUOTABLE FOR THE FOLLOWING DESCRIPTION. (Note: Removed Line 8 of Notes, applicability.)

# AetherSX2 is CC BY-NC-ND 4.0 + LGPLv3 
# The CC BY-NC-ND 4.0 explicitly says:
#    You are free to:
#
#    Share — copy and redistribute the material in any medium or format
#
#    The licensor cannot revoke these freedoms as long as you follow the license terms.
#
# AetherSX2 is apparently the author of AetherSX2 at the moment, so there's your attribution
# Tahlreth doesn't exist anymore or whatever, but in case he's the author, hi, you're the author for attribution
# APK is originally from https://www.aethersx2.com, specifically https://www.aethersx2.com/archive/android/alpha/15210-v1.5-4248.apk
# 
# I'm not making money off of this. I can assure you.
#
# Now the license is a little interesting here.
# "NoDerivatives — If you remix, transform, or build upon the material, you may not distribute the modified material."
#
# While I cannot share a modified APK myself, this implies that every end user may modify it for themselves, so long as they don't share it.
# Indeed, in the full license text:
#
# Subject to the terms and conditions of this Public License, the Licensor hereby grants You a worldwide, royalty-free, non-sublicensable, non-exclusive, irrevocable license to exercise the Licensed Rights in the Licensed Material to:
#
#    A. reproduce and Share the Licensed Material, in whole or in part, for NonCommercial purposes only; and
#    B. produce and reproduce, but not Share, Adapted Material for NonCommercial purposes only.
#
# ...therefore you, the end user, are perfectly entitled to produce and reproduce adapted material for noncommercial purposes only, so long as you do not share it
#
#
# I believe I'm making a good-faith effort to comply with the license here.
# Unlike some people.
# ;)

# Retrieved: November 30th 2023, 7:00AM est
# Latest Edit: August 12th 2023, 7:10 EST 