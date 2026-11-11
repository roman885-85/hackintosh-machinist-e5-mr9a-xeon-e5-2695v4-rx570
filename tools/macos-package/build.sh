#!/bin/bash
# Збирає встановлювальний пакет macOS dist/MR9A-Xeon-Drivers-ВЕРСІЯ.pkg з вмісту репозиторію:
# вбудований звук плати (Realtek ALC897) для macOS 26+ — VoodooHDA 3.6.8 у /Library/Extensions.
#   ./tools/macos-package/build.sh
# Завантажувач OpenCore у пакет не входить: у config.plist репозиторію заглушки серійних номерів
# і вимкнений запис Windows — його ставлять вручну (див. README, «Встановлення»).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
V=${VERSION:-$(date +%Y.%m.%d)}
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/comp" "$WORK/res" "$REPO/dist"
SUPDIR="Library/Application Support/MR9A-Xeon-Drivers"
ID=ua.local.mr9a.voodoohda

# корінь компонента: драйвер кладеться в теку підтримки, у /Library/Extensions його копіює postinstall
mkdir -p "$WORK/root/$SUPDIR" "$WORK/scripts"
cp -R "$REPO/PostInstall/VoodooHDA.kext" "$WORK/root/$SUPDIR/"
find "$WORK/root" \( -name "._*" -o -name ".DS_Store" \) -delete
cp "$HERE/scripts/voodoohda-postinstall" "$WORK/scripts/postinstall"; chmod 755 "$WORK/scripts/postinstall"

# kext не має бути «переміщуваним» (інакше Installer шукає його деінде на диску)
pkgbuild --analyze --root "$WORK/root" "$WORK/comp.plist" >/dev/null
n=$(/usr/libexec/PlistBuddy -c "Print" "$WORK/comp.plist" | grep -c "RootRelativeBundlePath" || true)
for ((i=0; i<n; i++)); do
  /usr/libexec/PlistBuddy -c "Set :$i:BundleIsRelocatable false" "$WORK/comp.plist" 2>/dev/null ||
    /usr/libexec/PlistBuddy -c "Add :$i:BundleIsRelocatable bool false" "$WORK/comp.plist"
done
pkgbuild --root "$WORK/root" --component-plist "$WORK/comp.plist" --scripts "$WORK/scripts" --identifier "$ID" \
  --version "$V" --install-location / --ownership recommended "$WORK/comp/mr9a-voodoohda.pkg" >/dev/null

cp "$HERE/resources/"*.html "$WORK/res/"
cat > "$WORK/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>Драйвери MACHINIST E5-MR9A · Xeon E5-2695 v4 · RX 570</title>
  <welcome file="welcome.html" mime-type="text/html"/>
  <conclusion file="conclusion.html" mime-type="text/html"/>
  <options customize="allow" require-scripts="false" hostArchitectures="x86_64" rootVolumeOnly="true"/>
  <domains enable_localSystem="true"/>
  <choices-outline><line choice="vhda"/></choices-outline>
  <choice id="vhda" title="Вбудований звук (VoodooHDA)" description="Realtek ALC897 на macOS 26 і новіших. Потрібні: увімкнений у BIOS «Onboard Azalia», дозвіл у «Конфіденційність і безпека» і перезапуск."><pkg-ref id="$ID"/></choice>
  <pkg-ref id="$ID" version="$V" onConclusion="RequireRestart">mr9a-voodoohda.pkg</pkg-ref>
</installer-gui-script>
XML
OUT="$REPO/dist/MR9A-Xeon-Drivers-$V.pkg"
productbuild --distribution "$WORK/distribution.xml" --resources "$WORK/res" --package-path "$WORK/comp" "$OUT" >/dev/null
echo "Готово: $OUT"
