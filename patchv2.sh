#!/bin/bash

[ -d tmp ] || mkdir tmp
INITDIR="$(pwd)"

#WSDIR="/media/Internal-1TB_data/LinDATA/Steam/steamapps/workshop/content/211820/"
#WSDIR='../StarboundArk/steamcmd/tmp/steam/steamapps/workshop/content/211820/'
#WSDIR='/run/media/geo/4095074e-895a-44e5-9c00-91aa4196e6c5/StarboundArk/steamcmd/tmp/steam/steamapps/workshop/content/211820/'
WSDIR='tmp/steam/steamapps/workshop/content/211820/'
#WSDIR='/run/media/geo/4095074e-895a-44e5-9c00-91aa4196e6c5/steamcmd/Starbound.stable/steamapps/workshop/content/211820/'
SBDIR="/media/Internal-1TB_data/LinDATA/Steam/steamapps/common/Starbound.stable/"
MODSDIR="mods/"
#MODSDIR="/media/Internal-1TB_data/LinDATA/Steam/steamapps/workshop/content/211820/"
UPDIR="unpack/"
MODBASE="modBase/"

echo "[INFO]: Initializing directories..."
[ -e "${UPDIR}" ] && rm -r "${UPDIR}"
mkdir "${UPDIR}"
[ -e 'speciesFixes' ] && rm -r 'speciesFixes'
cp -a "$MODBASE" 'speciesFixes'

printf '' > 'tmp/fixCinematic.log'
printf '' > 'tmp/patchChairs.log'
echo "[DBUG]: Initialized."

function logAction {
  if [ -z "$1" ] || [ -z "$2" ] || [ -n "$3" ] ; then
    echo '[CRIT]:   - Malformed call to `logAction`!'
    exit 1
  fi
  MODID="$2"

  METAFILE="$(find "${UPDIR}/${MODID}" -maxdepth 1 -type f -iregex '.*/\(\.\|_\)metadata$' | head -n 1)"
  NAME="Unknown"
  if [ -n "$METAFILE" ] ; then
    if grep -qE '"name" *: *"' "$METAFILE" ; then
      NAME="$(grep -E '"name" *: *"' "$METAFILE" | sed 's/.*"name" *: *"//' | sed 's/"[^\\]*$//')"
    elif grep -qE '"friendlyName" *: *"' "$METAFILE" ; then
      NAME="$(grep -E '"friendlyName" *: *"' "$METAFILE" | sed 's/.*"friendlyName" *: *"//' | sed 's/"[^\\]*$//')"
    fi
  fi
  if [[ "$1" == "fixCinematic" ]] ; then
    echo "[INFO]:   - Fixed cinematic in mod '$MODID'"
    echo "$MODID	$NAME" >> 'tmp/fixCinematic.log'
  else
    echo "[INFO]:   - Patched chair in mod '$MODID'"
    echo "$MODID	$NAME" >> 'tmp/patchChairs.log'
  fi
}

function fixCinematics {
  if [ -z "$1" ] || [ -n "$2" ] ; then
    echo '[CRIT]:   - Malformed call to `fixCinematics`!'
    exit 1
  fi
  MODID="$1"

  PSPECIESLIST="$(
    find "${UPDIR}/${MODID}" -type f -name "universe_server.config.patch" | while read FILE ; do
      sed ':a;N;$!ba;s/\n/ /g' "$FILE" | sed 's/,/\n/g' | grep -E '"path" *: *"/speciesShips/' | sed 's;.*"path" *: *"/speciesShips/;;' | sed 's/".*//'
    done | sort -u
  )"
  DSPECIESLIST="$(
    find "${UPDIR}/${MODID}" -type f -name "*.species" | while read FILE ; do
      grep -E '"kind" *: *"' "$FILE" | sed 's/.*"kind" *: *"//' | sed 's/".*//'
    done | sort -u
  )"
  SPECIESLIST="$(
    comm -12 <(echo "$PSPECIESLIST") <(echo "$DSPECIESLIST")
  )"
  #echo "SPECIESLIST = $SPECIESLIST"
  #exit 123
  SKIPSPECIES="$(
    find "${UPDIR}/${MODID}" -type f -name "deploy_*.cinematic" | while read FILE ; do
      echo "$FILE" | sed 's/.*deploy_//' | sed 's/\.cinematic//'
    done | sort -u
  )"
  CINSPECIES="$(comm -23 <(echo "$SPECIESLIST") <(echo "$SKIPSPECIES"))"

  if [ -n "$CINSPECIES" ] ; then
    echo "$CINSPECIES" | while read SPECIES ; do
      cp -a 'deploy_SPECIES.cinematic' "speciesFixes/cinematics/teleport/deploy_${SPECIES}.cinematic"
      echo "[INFO]:   - Built cinematic for species '$SPECIES'"
    done
    logAction "fixCinematic" "$MODID"
  fi
}

function patchChairs {
  if [ -z "$1" ] || [ -n "$2" ] ; then
    echo '[CRIT]:   - Malformed call to `fixCinematics`!'
    exit 1
  fi
  MODID="$1"

  CAPCHAIRLIST="$(
    find "${UPDIR}/${MODID}" -type f -name "*.object" | while read FILE ; do
      if grep -q 'openCockpitInterface' "$FILE" ; then
        echo "$FILE" | sed "s:.*${MODID}/::"
      fi
    done
  )"

  if [ -n "$CAPCHAIRLIST" ] ; then
    echo "$CAPCHAIRLIST" | while read FILE ; do
      mkdir -p "speciesFixes/$(dirname "$FILE")"
      cp -a 'captainChair.patch' "speciesFixes/${FILE}.patch"
      echo "[INFO]:   - Patched outdated captain's chair '$FILE'"
    done
    logAction "patchChairs" "$MODID"
  fi
}

if [[ "$1" == "local" ]] ; then
  echo "[INFO]: Using local mods directory $MODSDIR as source. NOTE: Must use proper naming convention!"
  ls "$MODSDIR" | while read FILE ; do
    MODID="$(echo "$FILE" | sed 's/_.*//')"
    if [ -f "${MODSDIR}/${FILE}" ] ; then
      #echo "Unpacking '${MODSDIR}/${FILE}' to '${UPDIR}/${MODID}'..."
      "${SBDIR}/linux/asset_unpacker" "${MODSDIR}/${FILE}" "${UPDIR}/${MODID}" >/dev/null 2>&1
    else
      echo "[INFO]: - File '${MODSDIR}/${FILE}' is not unpackable. Copying to '${UPDIR}/${MODID}"
      cp -a "${MODSDIR}/${FILE}" "${UPDIR}/${MODID}"
    fi
    echo "[INFO]: - Processing mod '$MODID'..."
    fixCinematics "$MODID"
    patchChairs "$MODID"
    rm -r "${UPDIR}/${MODID}"
  done
else
  echo "[INFO]: Using workshop directory '$WSDIR' as source."
  ls "$WSDIR"  | while read MODID ; do
    ls "${WSDIR}/${MODID}/" | while read FILE ; do
      if [ -f "${WSDIR}/${MODID}/${FILE}" ] ; then
        if ! "${SBDIR}/linux/asset_unpacker" "${WSDIR}/${MODID}/${FILE}" "${UPDIR}/${MODID}" >/dev/null 2>&1 ; then
          echo "[INFO]: - Skipping mod $MODID - Failed to unpack."
          break # If the unpacker fails, break and jump to the next mod. Usually due to pre-1.0 mods being on the workshop.
        fi
      else
        echo "[INFO]: - File '${WSDIR}/${MODID}/${FILE}' is not unpackable. Copying to '${UPDIR}/${MODID}'..."
        cp -a "${WSDIR}/${MODID}/${FILE}" "${UPDIR}/${MODID}"
      fi
      echo "[INFO]: - Processing mod '$MODID'..."
      fixCinematics "$MODID"
      patchChairs "$MODID"
      rm -r "${UPDIR}/${MODID}"
    done
  done
fi

read -p "[INFO]: Update version info? [y/N]: " UPRESP
if [[ "$UPRESP" == "Y" ]] || [[ "$UPRESP" == "y" ]] ; then
  OLDVER="$(grep '"version"' "${MODBASE}/_metadata" | sed 's/.*version" *: *"//' | sed 's/".*//')"
  read -p "[INFO]: - Version number? ['${OLDVER}']: " VERRESP
  if [ -z "$VERRESP" ] ; then
    NEWVER="$OLDVER"
  else
    NEWVER="$VERRESP"
  fi
  read -p "[INFO]: - Changelog entry? ['Refresh on $(date +%Y-%m-%d).']: " CLRESP
  if [ -z "$CLRESP" ] ; then
    CLENTRY="Refresh on $(date +%Y-%m-%d)."
  else
    CLENTRY="$CLRESP"
  fi
  echo "[INFO]: - Updating version from '$OLDVER' to '$NEWVER'"
  sed -i "s/\"version\" *: *\".*\"/\"version\": \"${NEWVER}\"/" "${MODBASE}/_metadata"
  echo -e "${NEWVER}\t${CLENTRY}" >> changelog.txt
  cp -a changelog.txt "${MODBASE}/changelog.txt"
fi

"${SBDIR}/linux/asset_packer" 'speciesFixes' 'speciesFixes.pak'

BOTH="$(comm -12 <(cat 'tmp/fixCinematic.log' | sort) <(cat 'tmp/patchChairs.log' | sort) | sort -nk1 | sed 's/\t/ - /')"
CINEMATIC="$(comm -23 <(cat 'tmp/fixCinematic.log' | sort) <(cat 'tmp/patchChairs.log' | sort) | sort -nk1 | sed 's/\t/ - /')"
CHAIR="$(comm -13 <(cat 'tmp/fixCinematic.log' | sort) <(cat 'tmp/patchChairs.log' | sort) | sort -nk1 | sed 's/\t/ - /')"

echo "--- Mods with fixed cinematics and captain's chairs ---" > 'tmp/report_both.txt'
echo "$BOTH" >> 'tmp/report_both.txt'
echo '' >> 'tmp/report_both.txt'
echo "--- Mods with only fixed cinematics ---" > 'tmp/report_cinematic.txt'
echo "$CINEMATIC" >> 'tmp/report_cinematic.txt'
echo '' >> 'tmp/report_cinematic.txt'
echo "--- Mods with only fixed captain's chairs ---" > 'tmp/report_chair.txt'
echo "$CHAIR" >> 'tmp/report_chair.txt'
echo '' >> 'tmp/report_chair.txt'
