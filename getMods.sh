#!/bin/bash
set -e

SCRIPT='tmp/download.scmd'
SCMDDIR='steamcmd'
BASEDIR="$PWD"

[ -e tmp ] || mkdir tmp

if [ -z "$1" ] ; then
  echo "[CRIT]: A valid Steam username must be supplied as the first argument for this script."
  exit 1
fi

echo "[INFO]: Building script..."
echo "@ShutdownOnFailedCommand 0" > "$SCRIPT"
echo "login ${1}"  >> "$SCRIPT"
echo "force_install_dir ${BASEDIR}/tmp/steam/" >> "$SCRIPT"
# rant; Why install the whole game when we only want the mods? Simple:
# SteamCMD is bad and it should feel bad. It behaves absolutely insanely
# unless the full game is installed first. Even then it doesn't behave sanely
# - it just behaves insane in a predictable manor. ;tnar
echo "app_update 211820 validate" >> "$SCRIPT"
cat tmp/IDList.txt | while read ID ; do
  echo "workshop_download_item 211820 $ID" >> "$SCRIPT"
done
echo "quit" >> "$SCRIPT"

echo "[INFO]: Running script. This'll take a while... possibly over a day, depending on your connection. Do not log back into Steam while this is running."
"${SCMDDIR}/steamcmd.sh" +runscript "../${SCRIPT}"

echo "[INFO]: Completed on $(date)."
